using DrWatson
@quickactivate "project"

ENV["GKSwstype"] = "100"

using BenchmarkTools
using CSV
using DataFrames
using DifferentialEquations
using JLD2
using Plots

include(srcdir("exponential_growth.jl"))

script_name = "02_exponential_growth"
mkpath(datadir(script_name, "single"))
mkpath(datadir(script_name, "parametric_scan"))
mkpath(plotsdir(script_name))

function run_experiment(parameters::Dict)
    u0 = parameters[:u0]
    alpha = parameters[:alpha]
    tspan = (0.0, parameters[:tmax])
    saveat = parameters[:saveat]

    problem = ODEProblem(exponential_growth!, [u0], tspan, (alpha=alpha,))
    solution = solve(problem, Tsit5(); saveat=saveat)

    return Dict(
        "time" => collect(solution.t),
        "population" => first.(solution.u),
        "final_population" => last(solution.u)[1],
        "doubling_time" => doubling_time(alpha),
    )
end

base_parameters = Dict(
    :u0 => 1.0,
    :alpha => 0.3,
    :tmax => 10.0,
    :saveat => 0.1,
)

base_data, base_path = produce_or_load(
    datadir(script_name, "single"),
    base_parameters,
    run_experiment;
    prefix="exp_growth",
    tag=false,
    verbose=false,
)

base_plot = plot(
    base_data["time"],
    base_data["population"];
    label="α = $(base_parameters[:alpha])",
    xlabel="Время, t",
    ylabel="Величина, u(t)",
    title="Базовый эксперимент",
    linewidth=3,
    legend=:topleft,
    size=(900, 540),
    dpi=150,
)
savefig(base_plot, plotsdir(script_name, "single_experiment.png"))

parameter_grid = Dict(
    :u0 => [1.0],
    :alpha => [0.1, 0.3, 0.5, 0.8, 1.0],
    :tmax => [10.0],
    :saveat => [0.1],
)
parameter_sets = dict_list(parameter_grid)

summary_rows = NamedTuple[]
trajectories = DataFrame[]

for parameters in parameter_sets
    data, path = produce_or_load(
        datadir(script_name, "parametric_scan"),
        parameters,
        run_experiment;
        prefix="scan",
        tag=false,
        verbose=false,
    )

    push!(
        summary_rows,
        (
            alpha=parameters[:alpha],
            final_population=data["final_population"],
            doubling_time=data["doubling_time"],
            result_file=path,
        ),
    )
    push!(
        trajectories,
        DataFrame(
            time=data["time"],
            population=data["population"],
            alpha=fill(parameters[:alpha], length(data["time"])),
        ),
    )
end

summary = sort(DataFrame(summary_rows), :alpha)
CSV.write(datadir(script_name, "parameter_summary.csv"), summary)

comparison_plot = plot(
    xlabel="Время, t",
    ylabel="Величина, u(t)",
    title="Влияние скорости роста α",
    legend=:topleft,
    size=(900, 540),
    dpi=150,
)
for trajectory in trajectories
    alpha = first(trajectory.alpha)
    plot!(
        comparison_plot,
        trajectory.time,
        trajectory.population;
        label="α = $(alpha)",
        linewidth=2,
    )
end
savefig(comparison_plot, plotsdir(script_name, "parametric_scan_comparison.png"))

doubling_plot = scatter(
    summary.alpha,
    summary.doubling_time;
    label="Результаты экспериментов",
    xlabel="Скорость роста, α",
    ylabel="Время удвоения",
    title="Время удвоения: ln(2) / α",
    markersize=7,
    legend=:topright,
    size=(900, 540),
    dpi=150,
)
alpha_range = range(0.1, 1.0; length=100)
plot!(
    doubling_plot,
    alpha_range,
    doubling_time.(alpha_range);
    label="Теоретическая зависимость",
    linestyle=:dash,
    linewidth=2,
)
savefig(doubling_plot, plotsdir(script_name, "doubling_time_vs_alpha.png"))

benchmark_rows = NamedTuple[]
for alpha in parameter_grid[:alpha]
    problem = ODEProblem(exponential_growth!, [1.0], (0.0, 10.0), (alpha=alpha,))
    elapsed = @belapsed solve($problem, Tsit5(); saveat=0.1) samples=100 evals=1
    push!(benchmark_rows, (alpha=alpha, seconds=elapsed))
end
benchmarks = DataFrame(benchmark_rows)
CSV.write(datadir(script_name, "benchmark_summary.csv"), benchmarks)

benchmark_plot = scatter(
    benchmarks.alpha,
    benchmarks.seconds;
    label="Время решения",
    xlabel="Скорость роста, α",
    ylabel="Время, с",
    title="Время численного решения",
    markersize=7,
    legend=:topleft,
    size=(900, 540),
    dpi=150,
)
savefig(benchmark_plot, plotsdir(script_name, "computation_time_vs_alpha.png"))

jldsave(
    datadir(script_name, "all_results.jld2");
    base_parameters=base_parameters,
    parameter_grid=parameter_grid,
    summary=summary,
    benchmarks=benchmarks,
)
jldsave(
    datadir(script_name, "all_plots.jld2");
    base_plot=base_plot,
    comparison_plot=comparison_plot,
    doubling_plot=doubling_plot,
    benchmark_plot=benchmark_plot,
)

println("Параметрическое исследование экспоненциального роста")
println("  базовый результат: $(base_path)")
println("  число экспериментов: $(nrow(summary))")
println(summary[:, [:alpha, :final_population, :doubling_time]])
println("Результаты: data/$(script_name), plots/$(script_name)")
