using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

figures = []
for period in (10, 14)
    result = basic_experiment(
        "sir_run_basic__param/period_$(period)";
        infection_period = period,
    )
    plot!(result.fig; title = "Период болезни: $(period) дней")
    push!(figures, result.fig)
    display(last(result.df, 3))
end

figure = plot(figures...; layout = (2, 1), size = (1000, 1000))
savefig(figure, imagefile("06-plot.png"))
display(figure)
