using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

result = optimize_sir()

savefig(result.fig, imagefile("04-plot.png"))
display(result.fig)
result.pareto
