using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

rows = NamedTuple[]
for (i, params) in enumerate(parameter_sets())
    model = daisyworld(; params..., scenario = :ramp)
    df = history(model, 1000)
    CSV.write(
        datafile("daisyworld-luminosity__param", "trajectory_$(i).csv"),
        df,
    )
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
    figure = dynamicsfigure(
        df;
        title = "Возраст $(params[:max_age]), белые $(params[:init_white])",
    )
    save(imagefile(lpad(21+i, 2, '0') * "-plot.png"), figure)
    display(figure)
end

summary = DataFrame(rows)
CSV.write(
    datafile("daisyworld-luminosity__param", "summary.csv"),
    summary,
)
summary
