using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

baseline =
    CSV.read(datafile("sir_run_basic", "trajectory.csv"), DataFrame)
R0 = 0.5 * 14
baseline_peak = maximum(baseline.infected ./ baseline.total)
comparison = DataFrame(
    beta = [0.5],
    gamma = [1/14],
    R0 = [R0],
    observed_peak = [baseline_peak],
)
CSV.write(
    datafile("sir_extra_1_2_3", "baseline_comparison.csv"),
    comparison,
)
display(comparison)

threshold_scan =
    beta_scan("sir_extra_1_2_3/threshold"; betas = 0.02:0.02:0.20)
table = threshold_scan.grouped
above = table.beta[table.peak .> 0.05]
empirical = isempty(above) ? NaN : minimum(above)
thresholds = DataFrame(
    theoretical = [1/14],
    empirical_grid = [empirical],
    grid_step = [0.02],
)
CSV.write(datafile("sir_extra_1_2_3", "threshold.csv"), thresholds)
figure = plot(
    table.beta,
    table.peak;
    label = "Средний пик",
    marker = :circle,
    xlabel = "β",
    ylabel = "Доля I среди живых",
)
hline!(figure, [0.05]; label = "Критерий 5%", linestyle = :dash)
vline!(figure, [1/14]; label = "β=1/14", linestyle = :dash)
savefig(figure, imagefile("10-plot.png"))
display(figure)
display(thresholds)

heterogeneous = basic_experiment(
    "sir_extra_1_2_3/heterogeneous";
    β_und = [0.2, 0.5, 0.8],
    β_det = [0.02, 0.05, 0.08],
)
panels = []
for city in 1:3
    df = heterogeneous.cities[heterogeneous.cities.city .== city, :]
    push!(
        panels,
        plot(
            df.time,
            [df.susceptible df.infected df.recovered];
            label = ["S" "I" "R"],
            title = "Город $(city)",
            xlabel = "Дни",
            ylabel = "Люди",
        ),
    )
end
figure = plot(panels...; layout = (3, 1), size = (1000, 1100))
savefig(figure, imagefile("11-plot.png"))
display(figure)
figure = plot(
    baseline.time,
    baseline.infected;
    label = "Одинаковая β=0.5",
    xlabel = "Дни",
    ylabel = "Инфицированные во всех городах",
)
plot!(
    figure,
    heterogeneous.df.time,
    heterogeneous.df.infected;
    label = "β=[0.2,0.5,0.8]",
)
savefig(figure, imagefile("12-plot.png"))
display(figure)
