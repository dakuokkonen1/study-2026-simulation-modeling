using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

model = daisyworld(; solar_luminosity = 1.0, scenario = :ramp)
df = savehistory(history(model, 1000), "daisyworld-luminosity")

figure = dynamicsfigure(df)
save(imagefile("05-plot.png"), figure)
display(figure)
df[[1, 201, 401, 501, 751, 1001], :]
