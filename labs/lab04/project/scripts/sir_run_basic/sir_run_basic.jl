using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

result = basic_experiment()

savefig(result.fig, imagefile("01-plot.png"))
display(result.fig)
result.df[1:10:end, :]
