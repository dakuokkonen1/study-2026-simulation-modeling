using Test
include(joinpath(@__DIR__, "..", "src", "queueing_models.jl"))
using .QueueingModels

@testset "M/M/1 formulas" begin
    t = theoretical_mm1(3.0, 5.0)
    @test t.rho == 0.6
    @test isapprox(t.mean_system, 1.5)
    @test isapprox(t.mean_queue, 0.9)
    @test isapprox(t.mean_sojourn, 0.5)
    @test_throws ArgumentError theoretical_mm1(5.0, 5.0)
end

@testset "M/M/1 simulation" begin
    r = simulate_mm1(3.0, 5.0; horizon=20_000.0, seed=42)
    @test r.arrivals >= r.served
    @test r.lost == 0
    @test abs(r.utilization - 0.6) < 0.03
    @test abs(r.mean_system - 1.5) < 0.15
    @test all(>=(0), r.queue_lengths)
    @test all(>=(0), r.waits)
end
