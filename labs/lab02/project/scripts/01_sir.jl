# # Модель SIR
#
# **Цель:** исследовать развитие эпидемии в закрытой популяции, определить
# порог распространения, пик числа инфицированных и влияние числа контактов.
#
# ## Инициализация

using DrWatson
@quickactivate "project"

ENV["GKSwstype"] = "100"

using CSV
using DataFrames
using DifferentialEquations
using JLD2
using Plots

include(srcdir("epidemic_ecology.jl"))
using .EpidemicEcology

script_name = "01_sir"
mkpath(datadir(script_name))
mkpath(plotsdir(script_name))

# ## Базовый эксперимент
#
# Популяция состоит из 990 восприимчивых и 10 инфицированных. Вероятность
# передачи за один контакт равна 0,05, среднее число контактов — 10 в день,
# средняя продолжительность болезни — 4 дня.

u0 = [990.0, 10.0, 0.0]
p = (beta=0.05, contacts=10.0, gamma=0.25)
tspan = (0.0, 80.0)
saveat = 0.1

problem = ODEProblem(sir!, u0, tspan, (p.beta, p.contacts, p.gamma))
solution = solve(problem, Tsit5(); saveat=saveat, reltol=1e-9, abstol=1e-11)

trajectory = DataFrame(
    time=solution.t,
    susceptible=getindex.(solution.u, 1),
    infected=getindex.(solution.u, 2),
    recovered=getindex.(solution.u, 3),
)
trajectory.population = trajectory.susceptible .+ trajectory.infected .+ trajectory.recovered

reproduction_number = basic_reproduction_number(p.beta, p.contacts, p.gamma)
trajectory.effective_reproduction = effective_reproduction_number.(
    trajectory.susceptible,
    trajectory.population,
    reproduction_number,
)

peak_index = argmax(trajectory.infected)
peak_time = trajectory.time[peak_index]
peak_infected = trajectory.infected[peak_index]
cross_index = findfirst(<(1.0), trajectory.effective_reproduction)
threshold_time = isnothing(cross_index) ? NaN : trajectory.time[cross_index]
population_drift = maximum(abs.(trajectory.population .- first(trajectory.population)))

CSV.write(datadir(script_name, "trajectory.csv"), trajectory)
JLD2.jldsave(
    datadir(script_name, "summary.jld2");
    reproduction_number,
    peak_time,
    peak_infected,
    threshold_time,
    population_drift,
)

println("=== Базовый эксперимент SIR ===")
println("R0 = ", round(reproduction_number; digits=4))
println("Пик I = ", round(peak_infected; digits=4), " при t = ", round(peak_time; digits=4))
println("Re < 1 с t = ", round(threshold_time; digits=4))
println("R(80) = ", round(last(trajectory.recovered); digits=4))
println("Максимальный дрейф S + I + R = ", population_drift)

default(fontfamily="DejaVu Sans", linewidth=2.5, framestyle=:box, gridalpha=0.22)

dynamics_plot = plot(
    trajectory.time,
    trajectory.susceptible;
    label="S(t): восприимчивые",
    xlabel="Время, дни",
    ylabel="Численность",
    title="Динамика эпидемии в модели SIR",
    size=(1000, 620),
)
plot!(dynamics_plot, trajectory.time, trajectory.infected; label="I(t): инфицированные")
plot!(dynamics_plot, trajectory.time, trajectory.recovered; label="R(t): выздоровевшие")
vline!(dynamics_plot, [peak_time]; label="пик I(t)", linestyle=:dash, color=:black)
savefig(dynamics_plot, plotsdir(script_name, "sir_dynamics.png"))

infected_plot = plot(
    trajectory.time,
    trajectory.infected;
    label="I(t)",
    xlabel="Время, дни",
    ylabel="Число инфицированных",
    title="Пик эпидемии",
    fill=(0, 0.18),
    color=:red,
    size=(1000, 620),
)
scatter!(infected_plot, [peak_time], [peak_infected]; label="максимум", color=:black)
savefig(infected_plot, plotsdir(script_name, "sir_peak.png"))

effective_plot = plot(
    trajectory.time,
    trajectory.effective_reproduction;
    label="Re(t)",
    xlabel="Время, дни",
    ylabel="Эффективное репродуктивное число",
    title="Переход эпидемии через порог Re = 1",
    color=:green,
    size=(1000, 620),
)
hline!(effective_plot, [1.0]; label="порог", linestyle=:dash, color=:red)
savefig(effective_plot, plotsdir(script_name, "sir_effective_reproduction.png"))

phase_plot = plot(
    trajectory.susceptible,
    trajectory.infected;
    label="фазовая траектория",
    xlabel="S(t)",
    ylabel="I(t)",
    title="Фазовая плоскость S–I",
    color=:purple,
    size=(900, 650),
)
scatter!(phase_plot, [first(trajectory.susceptible)], [first(trajectory.infected)]; label="начало")
savefig(phase_plot, plotsdir(script_name, "sir_phase.png"))

# ## Параметрическое исследование
#
# Изменим среднее число контактов. Значения подобраны так, чтобы охватить
# затухающие, пороговые и выраженные эпидемические режимы.

contact_values = [3.0, 5.0, 7.5, 10.0, 15.0]
summary_rows = NamedTuple[]
scan_plot = plot(
    xlabel="Время, дни",
    ylabel="I(t)",
    title="Влияние среднего числа контактов",
    size=(1000, 620),
)

for contacts in contact_values
    local_parameters = (p.beta, contacts, p.gamma)
    local_problem = remake(problem; p=local_parameters)
    local_solution = solve(local_problem, Tsit5(); saveat=saveat, reltol=1e-9, abstol=1e-11)
    local_infected = getindex.(local_solution.u, 2)
    local_peak_index = argmax(local_infected)
    local_r0 = basic_reproduction_number(p.beta, contacts, p.gamma)
    push!(summary_rows, (
        contacts=contacts,
        reproduction_number=local_r0,
        peak_infected=local_infected[local_peak_index],
        peak_time=local_solution.t[local_peak_index],
        final_recovered=getindex(last(local_solution.u), 3),
    ))
    plot!(scan_plot, local_solution.t, local_infected; label="c=$(contacts), R0=$(round(local_r0; digits=1))")
end

scan_summary = DataFrame(summary_rows)
CSV.write(datadir(script_name, "contact_scan.csv"), scan_summary)
savefig(scan_plot, plotsdir(script_name, "sir_contact_scan.png"))

println("\n=== Сканирование числа контактов ===")
show(scan_summary; allrows=true, allcols=true)
println()

# Вычисленный результат демонстрирует пороговый характер модели: при
# $R_0<1$ число инфицированных убывает сразу, а при $R_0>1$ формируется пик.
