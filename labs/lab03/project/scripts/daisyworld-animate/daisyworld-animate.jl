using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

model = daisyworld()
fig = Figure(size = (850, 700))
ax = Axis(
    fig[1, 1],
    title = "Daisyworld",
    xlabel = "x",
    ylabel = "y",
    aspect = 1,
)
temperature = Observable(copy(model.temperature))
black_positions = Observable(Point2f[])
white_positions = Observable(Point2f[])
hm = heatmap!(
    ax,
    temperature;
    colormap = :thermal,
    colorrange = (-20, 60),
)
scatter!(ax, black_positions; color = :black, markersize = 8)
scatter!(ax, white_positions; color = :white, markersize = 8)
Colorbar(fig[1, 2], hm; label = "Температура, °C")

rows = NamedTuple[]
record(
    fig,
    imagefile("01-animation.gif"),
    0:59;
    framerate = 10,
) do frame
    frame > 0 && advance!(model)
    temperature[] = copy(model.temperature)
    black_positions[] = [
        Point2f(a.pos...) for a in allagents(model) if a.breed == :black
    ]
    white_positions[] = [
        Point2f(a.pos...) for a in allagents(model) if a.breed == :white
    ]
    ax.title = "Daisyworld · t=$(model.tick)"
    push!(rows, measure(model))
end

CSV.write(datafile("daisyworld-animate", "frames.csv"), DataFrame(rows))
display(fig)
DataFrame(rows)[1:10:end, :]
