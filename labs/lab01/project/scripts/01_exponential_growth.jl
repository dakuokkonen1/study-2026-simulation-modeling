# # Экспоненциальный рост
#
# **Цель:** численно решить уравнение $du/dt = \alpha u$ и сравнить результат
# с аналитическим решением $u(t)=u_0e^{\alpha t}$.
#
# ## Инициализация проекта

using DrWatson
@quickactivate "project"

ENV["GKSwstype"] = "100"

using CSV
using DataFrames
using DifferentialEquations
using JLD2
using Plots

include(srcdir("exponential_growth.jl"))

script_name = "01_exponential_growth"
mkpath(datadir(script_name))
mkpath(plotsdir(script_name))

# ## Параметры модели
#
# Начальная величина равна единице, скорость роста равна `0.3`, а наблюдение
# продолжается десять единиц времени.

u0 = 1.0
alpha = 0.3
tspan = (0.0, 10.0)
saveat = 0.1

# ## Численное решение

problem = ODEProblem(exponential_growth!, [u0], tspan, alpha)
solution = solve(problem, Tsit5(); saveat=saveat)

results = DataFrame(
    time=solution.t,
    numerical=first.(solution.u),
    analytical=analytic_solution.(u0, alpha, solution.t),
)
results.error = abs.(results.numerical .- results.analytical)

# ## Проверка и сохранение результатов

final_population = last(results.numerical)
expected_population = last(results.analytical)
relative_error = abs(final_population - expected_population) / expected_population
time_to_double = doubling_time(alpha)

CSV.write(datadir(script_name, "trajectory.csv"), results)
jldsave(
    datadir(script_name, "all_results.jld2");
    parameters=(u0=u0, alpha=alpha, tspan=tspan, saveat=saveat),
    results=results,
    relative_error=relative_error,
)

trajectory_plot = plot(
    results.time,
    results.numerical;
    label="Численное решение",
    xlabel="Время, t",
    ylabel="Величина, u(t)",
    title="Экспоненциальный рост (α = $(alpha))",
    linewidth=3,
    legend=:topleft,
    size=(900, 540),
    dpi=150,
)
plot!(
    trajectory_plot,
    results.time,
    results.analytical;
    label="Аналитическое решение",
    linestyle=:dash,
    linewidth=2,
)
savefig(trajectory_plot, plotsdir(script_name, "exponential_growth.png"))

println("Экспоненциальный рост: одиночный эксперимент")
println("  u(0) = $(u0), α = $(alpha), t ∈ $(tspan)")
println("  u(10) численно      = $(round(final_population; digits=6))")
println("  u(10) аналитически  = $(round(expected_population; digits=6))")
println("  относительная ошибка = $(round(relative_error; sigdigits=4))")
println("  время удвоения       = $(round(time_to_double; digits=4))")
println("Результаты: data/$(script_name), plots/$(script_name)")

# Полученная численная траектория совпадает с аналитической с малой
# относительной ошибкой, что подтверждает корректность реализации.
