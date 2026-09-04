module SIRDES

using ResumableFunctions, ConcurrentSim, Distributions, DataFrames, Random
export SIRPerson, SIRModel, MakeSIRModel, activate, sir_run, out, metrics,
       vaccinate!, ode_sir, increment!, decrement!, carryover!

increment!(a::Vector{Int}) = push!(a, last(a) + 1)
decrement!(a::Vector{Int}) = push!(a, last(a) - 1)
carryover!(a::Vector{Int}) = push!(a, last(a))

mutable struct SIRPerson
    id::Int
    status::Symbol
    infection_time::Float64
end

"""Individual-based DES. Contact excludes self; β is a probability, not a rate."""
mutable struct SIRModel
    sim::Simulation
    β::Float64
    c::Float64
    γ::Float64
    σ::Float64
    μ::Float64
    birth_rate::Float64
    fixed_duration::Bool
    rng::AbstractRNG
    allIndividuals::Vector{SIRPerson}
    positions::Dict{Int,Int}
    next_id::Int
    counts::Vector{Int} # S, E, I, R (living people only)
    ta::Vector{Float64}
    Sa::Vector{Int}
    Ea::Vector{Int}
    Ia::Vector{Int}
    Ra::Vector{Int}
    Ba::Vector{Int}
    Da::Vector{Int}
    Va::Vector{Int}
    Ca::Vector{Int} # new infections, excludes initial I and vaccinations
    events::Vector{Symbol}
    person_ids::Vector{Int}
    disease_durations::Vector{Float64}
    births::Int
    deaths::Int
    vaccinations::Int
    infections::Int
    contacts::Int
    active::Bool
    initial::NTuple{3,Int}
end

stateindex(s::Symbol) = s == :S ? 1 : s == :E ? 2 : s == :I ? 3 : s == :R ? 4 : 0

function snapshot!(m, event::Symbol, id::Int=0)
    push!(m.ta, now(m.sim))
    push!(m.Sa, m.counts[1]); push!(m.Ea, m.counts[2])
    push!(m.Ia, m.counts[3]); push!(m.Ra, m.counts[4])
    push!(m.Ba, m.births); push!(m.Da, m.deaths)
    push!(m.Va, m.vaccinations); push!(m.Ca, m.infections)
    push!(m.events, event); push!(m.person_ids, id)
end

function transition!(m, person, target::Symbol, event::Symbol)
    old = stateindex(person.status)
    old == 0 && return false
    m.counts[old] -= 1
    new = stateindex(target)
    new > 0 && (m.counts[new] += 1)
    person.status = target
    snapshot!(m, event, person.id)
    true
end

function MakeSIRModel(u0, p; seed=1234, rng=Xoshiro(seed), fixed_duration=false,
                     sigma=Inf, mu=0.0, birth_rate=0.0)
    length(u0) == 3 || throw(ArgumentError("u0 must contain S,I,R"))
    all(x -> x isa Integer && x >= 0, u0) || throw(ArgumentError("invalid population"))
    sum(u0) > 0 || throw(ArgumentError("population must be positive"))
    length(p) == 3 || throw(ArgumentError("p must contain beta,c,gamma"))
    β, c, γ = Float64.(p)
    isfinite(β) && 0 <= β <= 1 || throw(ArgumentError("beta must be a probability"))
    isfinite(c) && c >= 0 || throw(ArgumentError("c must be nonnegative"))
    isfinite(γ) && γ > 0 || throw(ArgumentError("gamma must be positive"))
    sigma > 0 || throw(ArgumentError("sigma must be positive"))
    isfinite(mu) && mu >= 0 || throw(ArgumentError("mu must be nonnegative"))
    isfinite(birth_rate) && birth_rate >= 0 || throw(ArgumentError("invalid births"))
    people = SIRPerson[]
    for (status, n) in zip((:S,:I,:R),u0), _ in 1:n
        push!(people, SIRPerson(length(people)+1,status,status == :I ? 0.0 : NaN))
    end
    S,I,R = Int.(u0)
    SIRModel(Simulation(),β,c,γ,Float64(sigma),Float64(mu),Float64(birth_rate),
        fixed_duration,rng,people,Dict(p.id=>i for (i,p) in enumerate(people)),
        length(people)+1,[S,0,I,R],[0.0],[S],[0],[I],[R],[0],[0],[0],[0],
        [:initial],[0],Float64[],0,0,0,0,0,false,(S,I,R))
end

@resumable function live(sim::Simulation, person::SIRPerson, m::SIRModel)
    while person.status == :S && m.c > 0
        @yield timeout(sim, rand(m.rng, Exponential(1/m.c)))
        # A vaccination/death may have happened while this contact was pending.
        person.status == :S || break
        if length(m.allIndividuals) > 1
            m.contacts += 1
            alter = person
            while alter === person
                alter = m.allIndividuals[rand(m.rng, DiscreteUniform(1,length(m.allIndividuals)))]
            end
            if alter.status == :I && rand(m.rng, Uniform(0,1)) < m.β
                m.infections += 1
                if isfinite(m.σ)
                    transition!(m,person,:E,:infection)
                else
                    person.infection_time = now(sim)
                    transition!(m,person,:I,:infection)
                end
            end
        end
    end
    if person.status == :E
        @yield timeout(sim, rand(m.rng, Exponential(1/m.σ)))
        if person.status == :E
            person.infection_time = now(sim)
            transition!(m,person,:I,:infectious)
        end
    end
    if person.status == :I
        duration = m.fixed_duration ? 1/m.γ : rand(m.rng, Exponential(1/m.γ))
        @yield timeout(sim, duration)
        if person.status == :I
            push!(m.disease_durations, now(sim)-person.infection_time)
            transition!(m,person,:R,:recovery)
        end
    end
end

@resumable function die(sim::Simulation, person::SIRPerson, m::SIRModel)
    @yield timeout(sim, rand(m.rng, Exponential(1/m.μ)))
    if person.status != :D
        idx = m.positions[person.id]
        lastperson = last(m.allIndividuals)
        m.allIndividuals[idx] = lastperson
        m.positions[lastperson.id] = idx
        pop!(m.allIndividuals)
        delete!(m.positions,person.id)
        m.deaths += 1
        transition!(m,person,:D,:death)
    end
end

@resumable function births(sim::Simulation, m::SIRModel)
    while true
        @yield timeout(sim, rand(m.rng, Exponential(1/m.birth_rate)))
        person = SIRPerson(m.next_id,:S,NaN)
        m.next_id += 1
        push!(m.allIndividuals,person)
        m.positions[person.id] = length(m.allIndividuals)
        m.counts[1] += 1
        m.births += 1
        snapshot!(m,:birth,person.id)
        @process live(sim,person,m)
        if m.μ > 0
            @process die(sim,person,m)
        end
    end
end

function vaccinate!(m, fraction)
    0 <= fraction <= 1 || throw(ArgumentError("fraction must be in [0,1]"))
    candidates = filter(p -> p.status == :S,m.allIndividuals)
    n = floor(Int, fraction*length(candidates))
    n == 0 && return 0
    shuffle!(m.rng,candidates)
    for person in Iterators.take(candidates,n)
        m.vaccinations += 1
        transition!(m,person,:R,:vaccination)
    end
    n
end

@resumable function vaccination(sim::Simulation,m::SIRModel,time::Float64,fraction::Float64)
    @yield timeout(sim,time)
    vaccinate!(m,fraction)
end

function activate(m::SIRModel; vaccine_time=nothing,vaccine_fraction=0.0)
    m.active && throw(ArgumentError("model has already been activated"))
    0 <= vaccine_fraction <= 1 || throw(ArgumentError("invalid vaccine fraction"))
    if !isnothing(vaccine_time)
        isfinite(vaccine_time) && vaccine_time >= 0 || throw(ArgumentError("invalid vaccine time"))
        @process vaccination(m.sim,m,Float64(vaccine_time),Float64(vaccine_fraction))
    end
    for person in m.allIndividuals
        @process live(m.sim,person,m)
        m.μ > 0 && (@process die(m.sim,person,m))
    end
    m.birth_rate > 0 && (@process births(m.sim,m))
    m.active = true
    m
end

function sir_run(m::SIRModel,tf::Real)
    m.active || throw(ArgumentError("activate the model first"))
    isfinite(tf) && tf > now(m.sim) || throw(ArgumentError("horizon must advance time"))
    run(m.sim,Float64(tf))
    snapshot!(m,:horizon)
    m
end

out(m::SIRModel) = DataFrame(t=m.ta,S=m.Sa,E=m.Ea,I=m.Ia,R=m.Ra,
    births=m.Ba,deaths=m.Da,vaccinated=m.Va,infections=m.Ca,
    event=string.(m.events),person=m.person_ids)

function metrics(m::SIRModel)
    k = argmax(m.Ia)
    N0 = sum(m.initial)
    (; peak_I=m.Ia[k],peak_time=m.ta[k],S_T=last(m.Sa),E_T=last(m.Ea),
       I_T=last(m.Ia),R_T=last(m.Ra),R_fraction=last(m.Ra)/N0,
       ever_infected=m.initial[2]+m.infections,new_infections=m.infections,
       births=m.births,deaths=m.deaths,vaccinated=m.vaccinations,
       contacts=m.contacts,events=length(m.ta)-2,
       extinct=(last(m.Ia)+last(m.Ea)==0))
end

"""Mean-field closure for self-excluding contacts; not βSI from lab06."""
function ode_sir(u0,p,tf;dt=.02)
    isfinite(dt) && dt > 0 || throw(ArgumentError("dt must be positive"))
    isfinite(tf) && tf > 0 || throw(ArgumentError("tf must be positive"))
    β,c,γ = p
    N = sum(u0)
    function rhs(u)
        flow = N > 1 ? β*c*u[1]*u[2]/(N-1) : 0.0
        [-flow,flow-γ*u[2],γ*u[2]]
    end
    t = collect(0.0:dt:tf)
    last(t) < tf && push!(t,tf)
    u = Float64.(u0)
    rows = [(t=0.0,S=u[1],I=u[2],R=u[3])]
    for j in 2:length(t)
        h=t[j]-t[j-1]
        k1=rhs(u); k2=rhs(u+h*k1/2); k3=rhs(u+h*k2/2); k4=rhs(u+h*k3)
        u += h*(k1+2k2+2k3+k4)/6
        push!(rows,(t=t[j],S=u[1],I=u[2],R=u[3]))
    end
    DataFrame(rows)
end

end
