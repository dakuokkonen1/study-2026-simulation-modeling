using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

model = daisyworld()
snapshots = DataFrame[]
for (i, target) in enumerate((0, 5, 45))
    advance!(model, target - model.tick)
    push!(snapshots, DataFrame([measure(model)]))
    figure = snapshot(model)
    save(imagefile(lpad(i, 2, '0') * "-plot.png"), figure)
    display(figure)
end

summary = reduce(vcat, snapshots)
CSV.write(datafile("daisyworld", "snapshots.csv"), summary)
summary
