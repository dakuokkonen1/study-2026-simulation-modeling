using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

result = beta_scan()

savefig(result.fig, imagefile("02-plot.png"))
display(result.fig)
result.grouped
