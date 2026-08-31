module AgentSIR

using Agents, Random, Statistics
using Agents.Graphs: complete_graph
using StatsBase: sample, Weights
using Distributions: Poisson

export Person,
    initialize_sir,
    sir_agent_step!,
    migrate!,
    transmit!,
    recover_or_die!,
    advance!,
    counts,
    city_counts,
    metrics,
    simulate,
    create_migration_matrix,
    update_quarantine!,
    objective_replicates

@agent struct Person(GraphAgent)
    days_infected::Int
    status::Symbol
end

function create_migration_matrix(C, intensity)
    C > 1 || throw(ArgumentError("at least two cities required"))
    0 <= intensity <= 1 ||
        throw(ArgumentError("intensity outside [0,1]"))
    M = fill(intensity / (C-1), C, C)
    for i in 1:C
        M[i, i] = 1 - intensity
    end
    M
end

function initialize_sir(;
    Ns = [1000, 1000, 1000],
    migration_rates = nothing,
    β_und = [0.5, 0.5, 0.5],
    β_det = [0.05, 0.05, 0.05],
    infection_period = 14,
    detection_time = 7,
    death_rate = 0.02,
    reinfection_probability = 0.1,
    Is = [0, 0, 1],
    seed = 42,
    n_steps = 100,
    quarantine_threshold = Inf,
)
    C = length(Ns)
    C >= 2 && all(>(0), Ns) ||
        throw(ArgumentError("invalid city populations"))
    length(Is) == length(β_und) == length(β_det) == C ||
        throw(ArgumentError("parameter lengths must equal city count"))
    all(0 .<= Is .<= Ns) ||
        throw(ArgumentError("invalid initial infections"))
    all(>=(0), β_und) && all(>=(0), β_det) ||
        throw(ArgumentError("negative infection rate"))
    infection_period > 0 && detection_time >= 1 ||
        throw(ArgumentError("invalid duration"))
    0 <= death_rate <= 1 && 0 <= reinfection_probability <= 1 ||
        throw(ArgumentError("invalid probability"))
    quarantine_threshold >= 0 ||
        throw(ArgumentError("invalid quarantine threshold"))
    M = if isnothing(migration_rates)
        matrix = [(Ns[i]+Ns[j])/Ns[i] for i in 1:C, j in 1:C]
        matrix ./ sum(matrix; dims = 2)
    else
        Float64.(copy(migration_rates))
    end
    size(M) == (C, C) &&
    all(isfinite, M) &&
    all(>=(0), M) &&
    all(isapprox.(vec(sum(M; dims = 2)), 1.0; atol = 1e-12)) || throw(
        ArgumentError(
            "migration rows must be probability distributions",
        ),
    )
    properties = Dict{Symbol,Any}(
        :Ns=>copy(Ns),
        :β_und=>copy(β_und),
        :β_det=>copy(β_det),
        :migration_rates=>M,
        :infection_period=>infection_period,
        :detection_time=>detection_time,
        :death_rate=>death_rate,
        :reinfection_probability=>reinfection_probability,
        :C=>C,
        :initial_population=>sum(Ns),
        :tick=>0,
        :quarantine_threshold=>quarantine_threshold,
        :closed=>falses(C),
    )
    model = StandardABM(
        Person,
        GraphSpace(complete_graph(C));
        properties,
        rng = Xoshiro(seed),
        agent_step! = sir_agent_step!,
        model_step! = sir_model_step!,
        agents_first = false,
        scheduler = Schedulers.fastest,
    )
    for city in 1:C
        for _ in 1:Ns[city]
            add_agent!(city, model, 0, :S)
        end
        ids = sample(
            abmrng(model),
            collect(ids_in_position(city, model)),
            Is[city];
            replace = false,
        )
        for id in ids
            model[id].status = :I
            model[id].days_infected = 1
        end
    end
    model
end

function migrate!(agent, model)
    target = sample(
        abmrng(model),
        1:model.C,
        Weights(view(model.migration_rates, agent.pos, :)),
    )
    target == agent.pos || move_agent!(agent, target, model)
end

function transmit!(agent, model)
    rate =
        agent.days_infected < model.detection_time ?
        model.β_und[agent.pos] : model.β_det[agent.pos]
    remaining = rand(abmrng(model), Poisson(rate))
    remaining == 0 && return
    contacts = [
        id for id in ids_in_position(agent.pos, model) if id != agent.id
    ]
    shuffle!(abmrng(model), contacts)
    for id in contacts
        contact = model[id]
        susceptible =
            contact.status == :S || (
                contact.status == :R &&
                rand(abmrng(model)) < model.reinfection_probability
            )
        if susceptible
            contact.status = :I
            contact.days_infected = 1
            remaining -= 1
            remaining == 0 && break
        end
    end
    nothing
end

function recover_or_die!(agent, model)
    if agent.status == :I &&
       agent.days_infected >= model.infection_period
        if rand(abmrng(model)) < model.death_rate
            remove_agent!(agent, model)
        else
            agent.status = :R
            agent.days_infected = 0
        end
    end
    nothing
end

function sir_agent_step!(agent, model)
    migrate!(agent, model)
    if agent.status == :I
        transmit!(agent, model)
        agent.days_infected += 1
    end
    recover_or_die!(agent, model)
end

function city_counts(model, city)
    S=0
    I=0
    R=0
    for agent in agents_in_position(city, model)
        S += agent.status == :S
        I += agent.status == :I
        R += agent.status == :R
    end
    (;
        time = model.tick,
        city,
        susceptible = S,
        infected = I,
        recovered = R,
        total = S+I+R,
    )
end

function counts(model)
    S=0
    I=0
    R=0
    for agent in allagents(model)
        S += agent.status == :S
        I += agent.status == :I
        R += agent.status == :R
    end
    (;
        time = model.tick,
        susceptible = S,
        infected = I,
        recovered = R,
        total = S+I+R,
        deaths = model.initial_population-S-I-R,
    )
end

function update_quarantine!(model)
    isfinite(model.quarantine_threshold) || return
    for city in 1:model.C
        c = city_counts(model, city)
        if !model.closed[city] &&
           c.total > 0 &&
           c.infected/c.total > model.quarantine_threshold
            model.migration_rates[city, :] .= 0.0
            model.migration_rates[city, city] = 1.0
            model.closed[city] = true
        end
    end
    nothing
end

function sir_model_step!(model)
    update_quarantine!(model)
    model.tick += 1
end

advance!(model, n = 1) = Agents.step!(model, n)

function metrics(model; n_steps = 100)
    initial = counts(model)
    peak = initial.infected / max(initial.total, 1)
    peak_time = 0
    for day in 1:n_steps
        advance!(model)
        c = counts(model)
        fraction = c.infected / max(c.total, 1)
        if fraction > peak
            peak = fraction
            peak_time = day
        end
    end
    c = counts(model)
    (;
        peak,
        peak_time,
        final_inf = c.infected/max(c.total, 1),
        final_rec = c.recovered/max(c.total, 1),
        deaths = c.deaths,
        death_fraction = c.deaths/model.initial_population,
    )
end

function simulate(; n_steps = 100, kwargs...)
    model = initialize_sir(; kwargs...)
    global_rows = [counts(model)]
    city_rows = [city_counts(model, i) for i in 1:model.C]
    for _ in 1:n_steps
        advance!(model)
        push!(global_rows, counts(model))
        append!(city_rows, [city_counts(model, i) for i in 1:model.C])
    end
    (; model, global_rows, city_rows)
end

function objective_replicates(
    x;
    seeds = 43:47,
    n_steps = 100,
    Ns = [1000, 1000, 1000],
)
    rows = [
        metrics(
            initialize_sir(;
                Ns,
                β_und = fill(x[1], 3),
                β_det = fill(x[1]/10, 3),
                detection_time = round(Int, x[2]),
                death_rate = x[3],
                seed,
            );
            n_steps,
        ) for seed in seeds
    ]
    (;
        peak = mean(r.peak for r in rows),
        death_fraction = mean(r.death_fraction for r in rows),
        max_peak = maximum(r.peak for r in rows),
    )
end

end
