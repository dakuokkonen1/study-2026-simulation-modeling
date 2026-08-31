using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

rows = NamedTuple[]
for (i, params) in enumerate(parameter_sets())
    model = daisyworld(; params...)
    for (j, target) in enumerate((0, 5, 45))
        advance!(model, target - model.tick)
        push!(
            rows,
            merge(
                (
                    max_age = params[:max_age],
                    init_white = params[:init_white],
                ),
                measure(model),
            ),
        )
        figure = snapshot(
            model;
            title = "Возраст $(params[:max_age]), белые $(params[:init_white])",
        )
        save(
            imagefile(lpad(5 + 3*(i-1) + j, 2, '0') * "-plot.png"),
            figure,
        )
        display(figure)
    end
end

summary = DataFrame(rows)
CSV.write(datafile("daisyworld__param", "snapshots.csv"), summary)
summary
