# # Daisyworld: параметры и численность
#
# Четыре базовые комбинации, по 1000 шагов на каждую.
#
# ## Окружение и модель
using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

# ## Независимые прогоны
rows = NamedTuple[]
for (i, params) in enumerate(parameter_sets())
    model = daisyworld(; params...)
    df = history(model, 1000)
    CSV.write(
        datafile("daisyworld-count__param", "trajectory_$(i).csv"),
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
    figure = countfigure(
        df;
        title = "Возраст $(params[:max_age]), белые $(params[:init_white])",
    )
    save(imagefile(lpad(17+i, 2, '0') * "-plot.png"), figure)
    display(figure)
end
# ## Итоговые значения
summary = DataFrame(rows)
CSV.write(datafile("daisyworld-count__param", "summary.csv"), summary)
summary
