# # Дополнительное задание 6: ограниченная оптимизация
#
# Минимизируем число умерших при пике ниже 30% в каждом из пяти обучающих прогонов.
#
# ## Окружение
using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

# ## Целевая функция и ограничение
function constrained_cost(x)
    r = objective_replicates(x)
    r.max_peak < 0.30 ? r.death_fraction : 1.0 + r.max_peak
end
constrained_cost([0.1, 3.0, 0.01])
Random.seed!(202646)
result = bboptimize(
    constrained_cost,
    [0.1, 3.0, 0.01];
    Method = :adaptive_de_rand_1_bin,
    SearchRange = [(0.1, 1.0), (3.0, 14.0), (0.01, 0.1)],
    NumDimensions = 3,
    MaxTime = 120.0,
    TraceMode = :silent,
)
best = best_candidate(result)
training = objective_replicates(best)
@assert training.max_peak < 0.30

# ## Независимая проверка на двадцати новых seed
rows = NamedTuple[]
for seed in 1001:1020
    model = initialize_sir(;
        β_und = fill(best[1], 3),
        β_det = fill(best[1]/10, 3),
        detection_time = round(Int, best[2]),
        death_rate = best[3],
        seed,
    )
    push!(rows, merge((; seed), metrics(model)))
end
validation = DataFrame(rows)
validation.feasible = validation.peak .< 0.30
CSV.write(datafile("sir_extra_6", "validation.csv"), validation)
jldsave(
    datafile("sir_extra_6", "optimization_result.jld2");
    best,
    training,
    validation_passed = all(validation.feasible),
    validation_seeds = 1001:1020,
)
parameters = DataFrame(
    beta = [best[1]],
    detection_time = [round(Int, best[2])],
    death_rate = [best[3]],
    training_max_peak = [training.max_peak],
    validation_max_peak = [maximum(validation.peak)],
    validation_passed = [all(validation.feasible)],
)
CSV.write(datafile("sir_extra_6", "parameters.csv"), parameters)
display(parameters)

# ## Проверочные пики
figure = scatter(
    validation.seed,
    validation.peak;
    label = "Независимые прогоны",
    xlabel = "Seed",
    ylabel = "Пиковая доля I среди живых",
)
hline!(figure, [0.30]; label = "Ограничение 30%", linestyle = :dash)
savefig(figure, imagefile("14-plot.png"))
display(figure)
validation

# Проверка на конечном наборе seed не доказывает ограничение для всех
# случайных траекторий и не гарантирует глобального оптимума.
