using DrWatson,
    Agents, CSV, DataFrames, Statistics, Random, JLD2, BlackBoxOptim
ENV["GKSwstype"] = "100"
using Plots
include(joinpath(@__DIR__, "sir_model.jl"))
using .AgentSIR
default(
    fontfamily = "DejaVu Sans",
    linewidth = 2,
    size = (1000, 650),
    margin = 6Plots.mm,
)

imagefile(name) =
    (mkpath(projectdir("..", "image")); projectdir("..", "image", name))
datafile(name, file) = (mkpath(datadir(name)); datadir(name, file))

function basic_experiment(name = "sir_run_basic"; kwargs...)
    result = simulate(; kwargs...)
    df, cities =
        DataFrame(result.global_rows), DataFrame(result.city_rows)
    CSV.write(datafile(name, "trajectory.csv"), df)
    CSV.write(datafile(name, "cities.csv"), cities)
    agent_df = select(df, :time, :susceptible, :infected, :recovered)
    model_df = select(df, :time, :total, :deaths)
    jldsave(datafile(name, "sir_basic_agent.jld2"); agent_df)
    jldsave(datafile(name, "sir_basic_model.jld2"); model_df)
    fig = plot(
        df.time,
        [df.susceptible df.infected df.recovered];
        label = ["S" "I" "R"],
        xlabel = "Дни",
        ylabel = "Число людей",
        title = "Агентная SIR",
    )
    plot!(fig, df.time, df.total; label = "Живые", linestyle = :dash)
    (; df, cities, fig)
end

function beta_scan(
    name = "sir_scan_beta";
    infection_period = 14,
    betas = 0.1:0.1:1.0,
    seeds = [42, 43, 44],
    kwargs...,
)
    rows = NamedTuple[]
    for beta in betas, seed in seeds
        model = initialize_sir(;
            β_und = fill(beta, 3),
            β_det = fill(beta/10, 3),
            seed,
            infection_period,
            kwargs...,
        )
        push!(
            rows,
            merge((; beta, seed, infection_period), metrics(model)),
        )
    end
    df = DataFrame(rows)
    CSV.write(datafile(name, "beta_scan_all.csv"), df)
    grouped = combine(
        groupby(df, :beta),
        :peak=>mean=>:peak,
        :final_inf=>mean=>:final_inf,
        :final_rec=>mean=>:final_rec,
        :deaths=>mean=>:deaths,
        :death_fraction=>mean=>:death_fraction,
    )
    CSV.write(datafile(name, "summary.csv"), grouped)
    fig = plot(
        grouped.beta,
        [grouped.peak grouped.final_inf grouped.death_fraction];
        label = ["Пик I / живые" "Конечная I / живые" "Умершие / N₀"],
        xlabel = "β",
        ylabel = "Доля",
        marker = :circle,
        title = "Средние по трём seed",
    )
    (; df, grouped, fig)
end

function migration_scan(
    name = "sir_migration_effect";
    threshold = Inf,
    intensities = 0.0:0.1:0.5,
    seeds = [42, 43, 44],
    kwargs...,
)
    rows = NamedTuple[]
    for intensity in intensities, seed in seeds
        model = initialize_sir(;
            migration_rates = create_migration_matrix(3, intensity),
            Is = [1, 0, 0],
            seed,
            quarantine_threshold = threshold,
            kwargs...,
        )
        push!(
            rows,
            merge((; intensity, seed), metrics(model; n_steps = 150)),
        )
    end
    df = DataFrame(rows)
    CSV.write(datafile(name, "migration_scan_all.csv"), df)
    grouped = combine(
        groupby(df, :intensity),
        :peak_time=>mean=>:peak_time,
        :peak=>mean=>:peak,
    )
    CSV.write(datafile(name, "summary.csv"), grouped)
    p1 = plot(
        grouped.intensity,
        grouped.peak_time;
        label = "Время пика",
        xlabel = "Интенсивность миграции",
        ylabel = "Дни",
        marker = :circle,
    )
    p2 = plot(
        grouped.intensity,
        grouped.peak;
        label = "Доля I среди живых в пике",
        xlabel = "Интенсивность миграции",
        ylabel = "Доля",
        marker = :circle,
    )
    (;
        df,
        grouped,
        fig = plot(p1, p2; layout = (2, 1), size = (1000, 850)),
    )
end

function optimize_sir(
    name = "sir_optimize_parameters";
    budget = 120.0,
    seeds = 43:47,
)
    rows = NamedTuple[]
    function cost(x)
        result = objective_replicates(x; seeds)
        push!(
            rows,
            (
                beta = x[1],
                detection_time = round(Int, x[2]),
                death_rate = x[3],
                peak = result.peak,
                death_fraction = result.death_fraction,
            ),
        )
        (result.peak, result.death_fraction)
    end
    cost([0.5, 7.0, 0.02])
    Random.seed!(202604)
    result = bboptimize(
        cost;
        Method = :borg_moea,
        FitnessScheme = ParetoFitnessScheme{2}(is_minimizing = true),
        SearchRange = [(0.1, 1.0), (3.0, 14.0), (0.01, 0.1)],
        NumDimensions = 3,
        MaxTime = budget,
        TraceMode = :silent,
    )
    best, fitness = best_candidate(result), best_fitness(result)
    df = DataFrame(rows)
    frontier = [
        i for i in 1:nrow(df) if !any(
            j ->
                df.peak[j]<=df.peak[i] &&
                df.death_fraction[j]<=df.death_fraction[i] &&
                (
                    df.peak[j]<df.peak[i] ||
                    df.death_fraction[j]<df.death_fraction[i]
                ),
            1:nrow(df),
        )
    ]
    pareto = unique(df[frontier, :])
    CSV.write(datafile(name, "evaluations.csv"), df)
    CSV.write(datafile(name, "pareto.csv"), pareto)
    jldsave(
        datafile(name, "optimization_result.jld2");
        best,
        fitness,
        seeds = collect(seeds),
        budget,
        evaluations = nrow(df),
    )
    fig = scatter(
        df.peak,
        df.death_fraction;
        label = "Оценённые параметры",
        alpha = 0.5,
        xlabel = "Средний пик I / живые",
        ylabel = "Средняя доля умерших / N₀",
    )
    scatter!(
        fig,
        pareto.peak,
        pareto.death_fraction;
        label = "Недоминируемые решения",
        color = :red,
    )
    (; df, pareto, best, fitness, fig)
end

function comprehensive_analysis(
    path = datafile("sir_scan_beta", "beta_scan_all.csv"),
)
    isfile(path) ||
        error("Run sir_scan_beta.jl before analysing its saved CSV")
    df = CSV.read(path, DataFrame)
    grouped = combine(
        groupby(df, :beta),
        :peak=>mean=>:peak,
        :final_inf=>mean=>:final_inf,
        :deaths=>mean=>:deaths,
        :final_rec=>mean=>:final_rec,
    )
    p1 = plot(
        grouped.beta,
        [grouped.peak grouped.final_inf];
        label = ["Пик" "Конечная I"],
        ylabel = "Доля среди живых",
    )
    p2 = plot(
        grouped.beta,
        grouped.deaths;
        label = "Умершие",
        ylabel = "Число людей",
    )
    p3 = plot(
        grouped.beta,
        grouped.final_rec;
        label = "Выздоровевшие",
        ylabel = "Доля среди живых",
        xlabel = "β",
    )
    (;
        grouped,
        fig = plot(p1, p2, p3; layout = (3, 1), size = (1000, 1050)),
    )
end
