# # Влияние числа TCP-потоков
#
# **Цель:** оценить загрузку узкого места и состояние RED при изменении числа
# конкурентных соединений.

using DrWatson
@quickactivate "project"
ENV["GKSwstype"] = "100"
using CSV, DataFrames, Plots, Statistics
include(srcdir("tcp_red.jl"))
using .TCPRED

name = "02_flow_scan"
mkpath(datadir(name)); mkpath(plotsdir(name))
red = REDParameters()
rows = NamedTuple[]
for flows in [5, 10, 15, 20, 25, 30, 40]
    net = NetworkParameters(flows=flows, duration=30.0, dt=0.002)
    result = simulate_tcp_red(; network=net, red, seed=202604 + flows)
    warm = result.time .>= 10.0
    push!(rows, (flows=flows,
        throughput_mbps=mean(result.throughput_mbps[warm]),
        mean_queue=mean(result.queue[warm]),
        mean_cwnd=mean(result.cwnd_mean[warm]),
        loss_events=result.losses))
end
scan = DataFrame(rows)
CSV.write(datadir(name, "flow_scan.csv"), scan)
println("=== Сканирование числа TCP-потоков ===")
show(scan; allrows=true, allcols=true); println()

default(fontfamily="DejaVu Sans", linewidth=2.3, framestyle=:box, gridalpha=0.22,
    left_margin=5 * Plots.mm)
p1 = plot(scan.flows, scan.throughput_mbps; marker=:circle, label="throughput",
    xlabel="Число потоков", ylabel="Мбит/с", title="Загрузка узкого места",
    size=(1000,620))
hline!(p1, [20.0]; label="ёмкость 20 Мбит/с", linestyle=:dash, color=:black)
savefig(p1, plotsdir(name, "flow_throughput.png"))

p2 = plot(scan.flows, scan.mean_queue; marker=:diamond, label="средняя очередь",
    xlabel="Число потоков", ylabel="Пакеты", title="Очередь при росте конкуренции",
    size=(1000,620), color=:red)
hline!(p2, [red.qmin, red.qmax]; label=["qmin" "qmax"], linestyle=:dash)
savefig(p2, plotsdir(name, "flow_queue.png"))

# С ростом числа потоков узкое место насыщается, а RED удерживает очередь в
# ограниченном диапазоне и сигнализирует TCP до переполнения буфера.
