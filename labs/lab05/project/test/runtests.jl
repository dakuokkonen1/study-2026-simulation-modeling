using Test
using Random
using DataFrames
using CSV

include(joinpath(@__DIR__, "..", "src", "dining_philosophers.jl"))
using .DiningPhilosophers

@testset "Petri net structure" begin
    classical, initial = build_classical_network(5)
    arbiter, arbiter_initial = build_arbiter_network(5)
    @test size(classical.input) == (20, 15)
    @test size(arbiter.input) == (21, 15)
    @test sum(initial) == 10
    @test sum(arbiter_initial) == 14
    @test arbiter.place_names[end] == :Arbiter
end

@testset "Conservation on complete trajectories" begin
    for N in (3, 5), builder in (build_classical_network, build_arbiter_network)
        net, initial = builder(N)
        result = simulate_stochastic(net, initial, 30.0; rng=MersenneTwister(123))
        df = result.trajectory
        @test issorted(df.time) && maximum(df.time) <= 30.0
        @test all(all(df[!, Symbol("Think_$i")] .+ df[!, Symbol("Hungry_$i")] .+
            df[!, Symbol("Eat_$i")] .== 1) for i in 1:N)
        @test all(all(df[!, Symbol("Fork_$i")] .+ df[!, Symbol("Hungry_$i")] .+
            df[!, Symbol("Eat_$i")] .+ df[!, Symbol("Eat_$(mod1(i - 1, N))")] .== 1)
            for i in 1:N)
    end
end

@testset "Classical animation experiment" begin
    net, initial = build_classical_network(3)
    result = simulate_stochastic(net, initial, 30.0; rng=MersenneTwister(123))
    @test result.deadlock
    @test detect_deadlock(net, Int[last(result.trajectory)[n] for n in net.place_names])
    @test all(last(result.trajectory)[Symbol("Hungry_$i")] == 1 for i in 1:3)
end

@testset "Saved CSV analysis" begin
    root = joinpath(@__DIR__, "..")
    base = joinpath(root, "data", "01_dining_philosophers")
    for (variant, builder) in (("classical", build_classical_network),
                               ("arbiter", build_arbiter_network))
        frame = CSV.read(joinpath(base, "$(variant)_trajectory.csv"), DataFrame)
        net, _ = builder(5)
        @test all(n -> n in propertynames(frame), net.place_names)
        @test detect_deadlock(net, Int[last(frame)[n] for n in net.place_names]) ==
            (variant == "classical")
    end
    analysis = CSV.read(joinpath(root, "data", "04_comparative_report", "summary.csv"), DataFrame)
    @test analysis.deadlock == [true, false]
    @test analysis.rows == [6, 99]
end

@testset "Literate outputs for every scenario" begin
    root = joinpath(@__DIR__, "..")
    for name in ("01_dining_philosophers", "02_parameter_scan",
                 "03_marking_animation", "04_comparative_report")
        @test isfile(joinpath(root, "scripts", name, "$name.jl"))
        @test isfile(joinpath(root, "notebooks", name, "$name.ipynb"))
        @test isfile(joinpath(root, "markdown", name, "$name.qmd"))
    end
end

@testset "Transition firing and invariants" begin
    net, marking = build_classical_network(5)
    @test sort(enabled_transitions(net, marking)) == collect(1:5)
    fire_transition!(net, marking, 1)
    @test marking[1] == 0
    @test marking[6] == 1
    @test marking[16] == 0
    @test sum(marking[16:20]) == 4
    @test !detect_deadlock(net, marking)
end

@testset "Known deadlock marking" begin
    net, marking = build_classical_network(5)
    marking .= 0
    marking[6:10] .= 1
    @test detect_deadlock(net, marking)
end

@testset "Stochastic models" begin
    rates = default_rates(5)
    classical_net, classical_initial = build_classical_network(5)
    arbiter_net, arbiter_initial = build_arbiter_network(5)
    classical = simulate_stochastic(classical_net, classical_initial, 50.0;
        rates, rng=MersenneTwister(202605))
    arbiter = simulate_stochastic(arbiter_net, arbiter_initial, 50.0;
        rates, rng=MersenneTwister(202605))
    @test classical.deadlock
    @test !arbiter.deadlock
    @test classical.events > 0
    @test arbiter.events > classical.events
    @test sum(arbiter.meal_counts) > 0
    @test all(Matrix(arbiter.trajectory[:, Not(:time)]) .>= 0)
end

@testset "ODE and fairness" begin
    net, initial = build_arbiter_network(3)
    frame = simulate_ode(net, initial, 2.0; rates=default_rates(3), saveat=0.2)
    @test nrow(frame) == 11
    @test all(Matrix(frame[:, Not(:time)]) .>= 0)
    @test jain_fairness([4, 4, 4]) == 1.0
    @test jain_fairness([0, 0, 0]) == 0.0
    @test 0 < jain_fairness([1, 2, 3]) < 1
end
