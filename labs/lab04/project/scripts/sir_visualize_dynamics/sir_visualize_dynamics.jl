using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

result = comprehensive_analysis()
CSV.write(
    datafile("sir_visualize_dynamics", "summary.csv"),
    result.grouped,
)

savefig(result.fig, imagefile("05-plot.png"))
display(result.fig)
result.grouped
