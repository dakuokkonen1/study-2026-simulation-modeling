using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

result = migration_scan()

savefig(result.fig, imagefile("03-plot.png"))
display(result.fig)
result.grouped
