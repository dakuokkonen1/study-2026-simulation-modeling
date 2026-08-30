using DrWatson
@quickactivate "project"
ENV["GKSwstype"] = "100"
using CSV, DataFrames, Plots, Random, Statistics
include(srcdir("dining_philosophers.jl"))
using .DiningPhilosophers

const N = 5
const TMAX = 50.0
const RATES = default_rates(N; left_rate=2.0, right_rate=1.0, release_rate=1.4)
const IMAGE_DIR = projectdir("..", "image")
const DATA_DIR = datadir("01_dining_philosophers")
mkpath(IMAGE_DIR)
mkpath(DATA_DIR)

classical_net, classical_initial = build_classical_network(N)
arbiter_net, arbiter_initial = build_arbiter_network(N)

classical = simulate_stochastic(classical_net, classical_initial, TMAX;
    rates=RATES, rng=MersenneTwister(202605))
arbiter = simulate_stochastic(arbiter_net, arbiter_initial, TMAX;
    rates=RATES, rng=MersenneTwister(202605))

CSV.write(joinpath(DATA_DIR, "classical_trajectory.csv"), classical.trajectory)
CSV.write(joinpath(DATA_DIR, "arbiter_trajectory.csv"), arbiter.trajectory)

ode_classical = simulate_ode(classical_net, classical_initial, 20.0;
    rates=RATES, saveat=0.1)
ode_arbiter = simulate_ode(arbiter_net, arbiter_initial, 20.0;
    rates=RATES, saveat=0.1)
CSV.write(joinpath(DATA_DIR, "classical_ode.csv"), ode_classical)
CSV.write(joinpath(DATA_DIR, "arbiter_ode.csv"), ode_arbiter)

summary = DataFrame(
    variant=["Классическая сеть", "Сеть с арбитром"],
    deadlock=[classical.deadlock, arbiter.deadlock],
    stop_time=[classical.stop_time, arbiter.stop_time],
    events=[classical.events, arbiter.events],
    completed_meals=[sum(classical.meal_counts), sum(arbiter.meal_counts)],
    fairness=[jain_fairness(classical.meal_counts), jain_fairness(arbiter.meal_counts)],
)
CSV.write(joinpath(DATA_DIR, "summary.csv"), summary)

println("=== Обедающие философы: базовый эксперимент ===")
println("Философов: $N, горизонт: $TMAX")
show(summary; allrows=true, allcols=true)
println()
println("Завершённые приёмы пищи, классическая сеть: $(classical.meal_counts)")
println("Завершённые приёмы пищи, сеть с арбитром: $(arbiter.meal_counts)")

default(fontfamily="DejaVu Sans", linewidth=2.1, framestyle=:box,
    gridalpha=0.22, legendfontsize=8, guidefontsize=11, titlefontsize=13,
    left_margin=7Plots.mm, bottom_margin=5Plots.mm)

classical_aggregate = aggregate_trajectory(classical.trajectory, N)
arbiter_aggregate = aggregate_trajectory(arbiter.trajectory, N)

p1 = plot(classical_aggregate.time, classical_aggregate.Think;
    label="размышляют", xlabel="Время", ylabel="Число философов",
    title="Классическая сеть: эволюция маркировки", size=(1000, 620))
plot!(p1, classical_aggregate.time, classical_aggregate.Hungry; label="держат левую вилку")
plot!(p1, classical_aggregate.time, classical_aggregate.Eat; label="едят")
savefig(p1, joinpath(IMAGE_DIR, "01-plot.png"))

p2 = plot(arbiter_aggregate.time, arbiter_aggregate.Think;
    label="размышляют", xlabel="Время", ylabel="Число философов",
    title="Сеть с арбитром: эволюция маркировки", size=(1000, 620))
plot!(p2, arbiter_aggregate.time, arbiter_aggregate.Hungry; label="держат левую вилку")
plot!(p2, arbiter_aggregate.time, arbiter_aggregate.Eat; label="едят")
plot!(p2, arbiter_aggregate.time, arbiter_aggregate.Arbiter; label="разрешения арбитра",
    linestyle=:dash, color=:black)
savefig(p2, joinpath(IMAGE_DIR, "02-plot.png"))

eat_columns = [Symbol("Eat_$i") for i in 1:N]
p3a = plot(classical.trajectory.time, Matrix(classical.trajectory[:, eat_columns]);
    label=permutedims(["Философ $i" for i in 1:N]), xlabel="Время",
    ylabel="Маркер Eat", title="Классическая сеть")
p3b = plot(arbiter.trajectory.time, Matrix(arbiter.trajectory[:, eat_columns]);
    label=permutedims(["Философ $i" for i in 1:N]), xlabel="Время",
    ylabel="Маркер Eat", title="Сеть с арбитром")
p3 = plot(p3a, p3b; layout=(2, 1), size=(1000, 850))
savefig(p3, joinpath(IMAGE_DIR, "03-plot.png"))

classical_ode_aggregate = aggregate_trajectory(ode_classical, N)
arbiter_ode_aggregate = aggregate_trajectory(ode_arbiter, N)
p4 = plot(classical_ode_aggregate.time, classical_ode_aggregate.Eat;
    label="классическая сеть", xlabel="Время", ylabel="Сумма Eat",
    title="Детерминированная mass-action аппроксимация", size=(1000, 620))
plot!(p4, arbiter_ode_aggregate.time, arbiter_ode_aggregate.Eat;
    label="с арбитром")
savefig(p4, joinpath(IMAGE_DIR, "04-plot.png"))

matrix_plot = heatmap(classical_net.output - classical_net.input;
    xlabel="Переход", ylabel="Позиция", title="Матрица инцидентности классической сети",
    color=:balance, size=(1000, 700))
savefig(matrix_plot, joinpath(IMAGE_DIR, "05-plot.png"))
