using Test
using Random
using DataFrames

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
