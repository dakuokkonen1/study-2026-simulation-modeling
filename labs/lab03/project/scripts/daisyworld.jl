# # Daisyworld: пространственное состояние
#
# Базовый опыт: сетка 30×30, два вида, светимость 1.0, seed 165.
#
# ## Окружение и модель
using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

# ## Последовательная эволюция
model = daisyworld()
snapshots = DataFrame[]
for (i, target) in enumerate((0, 5, 45))
    advance!(model, target - model.tick)
    push!(snapshots, DataFrame([measure(model)]))
    figure = snapshot(model)
    save(imagefile(lpad(i, 2, '0') * "-plot.png"), figure)
    display(figure)
end
# ## Сохранённые измерения
summary = reduce(vcat, snapshots)
CSV.write(datafile("daisyworld", "snapshots.csv"), summary)
summary
