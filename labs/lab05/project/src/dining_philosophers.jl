module DiningPhilosophers

using DataFrames
using DifferentialEquations
using LinearAlgebra
using Random
using Statistics

export PetriNet, SimulationResult
export build_classical_network, build_arbiter_network
export enabled_transitions, fire_transition!, detect_deadlock
export simulate_stochastic, simulate_ode, aggregate_trajectory
export jain_fairness, default_rates

"""Ordinary place/transition Petri net with integer arc multiplicities."""
struct PetriNet
    input::Matrix{Int}
    output::Matrix{Int}
    place_names::Vector{Symbol}
    transition_names::Vector{Symbol}

    function PetriNet(input, output, place_names, transition_names)
        size(input) == size(output) || throw(ArgumentError("arc matrices must match"))
        size(input, 1) == length(place_names) || throw(ArgumentError("place count mismatch"))
        size(input, 2) == length(transition_names) || throw(ArgumentError("transition count mismatch"))
        all(input .>= 0) || throw(ArgumentError("input multiplicities must be nonnegative"))
        all(output .>= 0) || throw(ArgumentError("output multiplicities must be nonnegative"))
        new(Matrix{Int}(input), Matrix{Int}(output), collect(place_names), collect(transition_names))
    end
end

struct SimulationResult
    trajectory::DataFrame
    deadlock::Bool
    stop_time::Float64
    events::Int
    meal_counts::Vector{Int}
end

nplaces(net::PetriNet) = size(net.input, 1)
ntransitions(net::PetriNet) = size(net.input, 2)
incidence(net::PetriNet) = net.output - net.input

function default_rates(N::Integer; left_rate=2.0, right_rate=1.0, release_rate=1.4)
    N >= 2 || throw(ArgumentError("at least two philosophers are required"))
    vcat(fill(Float64(left_rate), N), fill(Float64(right_rate), N),
        fill(Float64(release_rate), N))
end

function build_network(N::Integer; arbiter::Bool)
    N >= 2 || throw(ArgumentError("at least two philosophers are required"))
    places = 4N + (arbiter ? 1 : 0)
    transitions = 3N
    input = zeros(Int, places, transitions)
    output = zeros(Int, places, transitions)
    place_names = Symbol[]
    append!(place_names, [Symbol("Think_$i") for i in 1:N])
    append!(place_names, [Symbol("Hungry_$i") for i in 1:N])
    append!(place_names, [Symbol("Eat_$i") for i in 1:N])
    append!(place_names, [Symbol("Fork_$i") for i in 1:N])
    arbiter && push!(place_names, :Arbiter)
    transition_names = vcat(
        [Symbol("GetLeft_$i") for i in 1:N],
        [Symbol("GetRight_$i") for i in 1:N],
        [Symbol("PutForks_$i") for i in 1:N],
    )

    arbiter_place = 4N + 1
    for i in 1:N
        think = i
        hungry = N + i
        eat = 2N + i
        left_fork = 3N + i
        right_fork = 3N + mod1(i + 1, N)
        get_left = i
        get_right = N + i
        put_forks = 2N + i

        input[think, get_left] = 1
        input[left_fork, get_left] = 1
        output[hungry, get_left] = 1
        if arbiter
            input[arbiter_place, get_left] = 1
        end

        input[hungry, get_right] = 1
        input[right_fork, get_right] = 1
        output[eat, get_right] = 1

        input[eat, put_forks] = 1
        output[think, put_forks] = 1
        output[left_fork, put_forks] = 1
        output[right_fork, put_forks] = 1
        if arbiter
            output[arbiter_place, put_forks] = 1
        end
    end

    marking = zeros(Int, places)
    marking[1:N] .= 1
    marking[(3N + 1):(4N)] .= 1
    arbiter && (marking[arbiter_place] = N - 1)
    PetriNet(input, output, place_names, transition_names), marking
end

build_classical_network(N::Integer) = build_network(N; arbiter=false)
build_arbiter_network(N::Integer) = build_network(N; arbiter=true)

function enabled_transitions(net::PetriNet, marking::AbstractVector{<:Real}; tol=1e-10)
    length(marking) == nplaces(net) || throw(ArgumentError("marking length mismatch"))
    [j for j in 1:ntransitions(net)
     if all(marking[i] + tol >= net.input[i, j] for i in 1:nplaces(net))]
end

detect_deadlock(net::PetriNet, marking::AbstractVector{<:Real}) =
    isempty(enabled_transitions(net, marking))

function fire_transition!(net::PetriNet, marking::Vector{Int}, transition::Integer)
    transition in enabled_transitions(net, marking) ||
        throw(ArgumentError("transition is not enabled"))
    marking .+= incidence(net)[:, transition]
    marking
end

function trajectory_frame(times, states, net::PetriNet)
    frame = DataFrame(time=times)
    for i in 1:nplaces(net)
        frame[!, String(net.place_names[i])] = [state[i] for state in states]
    end
    frame
end

"""Simulate enabled transition firings with the direct Gillespie algorithm."""
function simulate_stochastic(net::PetriNet, initial::Vector{Int}, tmax::Real;
        rates=ones(ntransitions(net)), rng=Random.default_rng())
    length(rates) == ntransitions(net) || throw(ArgumentError("rate count mismatch"))
    all(rates .> 0) || throw(ArgumentError("rates must be positive"))
    marking = copy(initial)
    time = 0.0
    times = Float64[time]
    states = Vector{Int}[copy(marking)]
    meals = zeros(Int, div(ntransitions(net), 3))
    events = 0
    deadlock = false

    while time < tmax
        enabled = enabled_transitions(net, marking)
        if isempty(enabled)
            deadlock = true
            break
        end
        total_rate = sum(rates[enabled])
        dt = randexp(rng) / total_rate
        time + dt > tmax && break
        threshold = rand(rng) * total_rate
        cumulative = 0.0
        chosen = enabled[end]
        for transition in enabled
            cumulative += rates[transition]
            if threshold <= cumulative
                chosen = transition
                break
            end
        end
        fire_transition!(net, marking, chosen)
        time += dt
        events += 1
        if chosen > 2length(meals)
            meals[chosen - 2length(meals)] += 1
        end
        push!(times, time)
        push!(states, copy(marking))
    end

    SimulationResult(trajectory_frame(times, states, net), deadlock,
        time, events, meals)
end

"""Continuous mass-action approximation of the same Petri net."""
function simulate_ode(net::PetriNet, initial::AbstractVector{<:Real}, tmax::Real;
        rates=ones(ntransitions(net)), saveat=0.1)
    stoichiometry = incidence(net)
    function vectorfield!(du, u, parameters, time)
        activity = zeros(eltype(u), ntransitions(net))
        for transition in 1:ntransitions(net)
            value = rates[transition]
            for place in 1:nplaces(net)
                multiplicity = net.input[place, transition]
                multiplicity > 0 && (value *= max(u[place], zero(eltype(u)))^multiplicity)
            end
            activity[transition] = value
        end
        mul!(du, stoichiometry, activity)
        nothing
    end
    problem = ODEProblem(vectorfield!, Float64.(initial), (0.0, Float64(tmax)))
    solution = solve(problem, Tsit5(); saveat, abstol=1e-9, reltol=1e-8)
    frame = DataFrame(time=solution.t)
    for i in 1:nplaces(net)
        frame[!, String(net.place_names[i])] = max.(solution[i, :], 0.0)
    end
    frame
end

function aggregate_trajectory(frame::DataFrame, N::Integer)
    aggregate = DataFrame(time=frame.time)
    for group in ("Think", "Hungry", "Eat", "Fork")
        columns = [Symbol("$(group)_$i") for i in 1:N]
        aggregate[!, Symbol(group)] = vec(sum(Matrix(frame[:, columns]); dims=2))
    end
    :Arbiter in propertynames(frame) && (aggregate.Arbiter = frame.Arbiter)
    aggregate
end

function jain_fairness(values::AbstractVector{<:Real})
    isempty(values) && return 0.0
    denominator = length(values) * sum(abs2, values)
    denominator == 0 && return 0.0
    sum(values)^2 / denominator
end

end
