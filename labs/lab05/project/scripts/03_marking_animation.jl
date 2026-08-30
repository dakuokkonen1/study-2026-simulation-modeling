using DrWatson
@quickactivate "project"
ENV["GKSwstype"] = "100"
using DataFrames, Plots, Random
include(srcdir("dining_philosophers.jl"))
using .DiningPhilosophers

N = 5
net, initial = build_arbiter_network(N)
result = simulate_stochastic(net, initial, 20.0;
    rates=default_rates(N), rng=MersenneTwister(202605))

frames = unique(round.(Int, range(1, nrow(result.trajectory); length=min(70, nrow(result.trajectory)))))
labels = string.(net.place_names)
animation = @animate for row_index in frames
    row = result.trajectory[row_index, :]
    marking = Float64[row[Symbol(name)] for name in net.place_names]
    bar(marking;
        label=false,
        xlabel="Позиции сети",
        ylabel="Число фишек",
        xticks=(1:length(labels), labels),
        xrotation=55,
        ylims=(0, N),
        title="Сеть с арбитром, t=$(round(row.time, digits=2))",
        fontfamily="DejaVu Sans",
        size=(1100, 650),
        color=repeat([:steelblue, :orange, :green, :gray, :purple], inner=N)[1:length(labels)],
    )
end

gif(animation, projectdir("..", "image", "01-animation.gif"); fps=5)
println("Анимация сохранена: ../image/01-animation.gif")
