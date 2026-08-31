using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

rows = DataFrame[]
for (label, population) in
    (("equal", [1000, 1000, 1000]), ("unequal", [500, 1000, 1500]))
    result = migration_scan(
        "sir_migration_effect__param/$(label)";
        Ns = population,
    )
    result.grouped[!, :configuration] =
        fill(label, nrow(result.grouped))
    push!(rows, result.grouped)
end

summary = reduce(vcat, rows)
CSV.write(
    datafile("sir_migration_effect__param", "summary.csv"),
    summary,
)
figure = plot(;
    xlabel = "Интенсивность миграции",
    ylabel = "Время пика, дни",
)
for label in ("equal", "unequal")
    subset = summary[summary.configuration .== label, :]
    plot!(
        figure,
        subset.intensity,
        subset.peak_time;
        label,
        marker = :circle,
    )
end
savefig(figure, imagefile("08-plot.png"))
display(figure)
summary
