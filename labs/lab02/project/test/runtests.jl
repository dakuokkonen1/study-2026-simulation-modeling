using Test
using DifferentialEquations

include(joinpath(@__DIR__, "..", "src", "epidemic_ecology.jl"))
using .EpidemicEcology

@testset "SIR model" begin
    du = zeros(3)
    state = [990.0, 10.0, 0.0]
    sir!(du, state, (0.05, 10.0, 0.25), 0.0)
    @test sum(du) ≈ 0.0 atol=1e-12
    @test basic_reproduction_number(0.05, 10.0, 0.25) ≈ 2.0
    @test effective_reproduction_number(500.0, 1000.0, 2.0) ≈ 1.0

    problem = ODEProblem(sir!, state, (0.0, 80.0), (0.05, 10.0, 0.25))
    solution = solve(problem, Tsit5(); saveat=0.1, reltol=1e-9, abstol=1e-11)
    totals = sum.(solution.u)
    @test maximum(abs.(totals .- first(totals))) < 1e-7
    @test minimum(minimum.(solution.u)) >= -1e-8
    @test maximum(getindex.(solution.u, 2)) > state[2]
end

@testset "Lotka–Volterra model" begin
    equilibrium = lotka_equilibrium(0.1, 0.02, 0.01, 0.3)
    @test collect(equilibrium) ≈ [30.0, 5.0]

    du = zeros(2)
    lotka_volterra!(du, collect(equilibrium), (0.1, 0.02, 0.01, 0.3), 0.0)
    @test du ≈ zeros(2) atol=1e-12

    problem = ODEProblem(lotka_volterra!, [40.0, 9.0], (0.0, 100.0), (0.1, 0.02, 0.01, 0.3))
    solution = solve(problem, Tsit5(); saveat=0.1, reltol=1e-10, abstol=1e-12)
    values = lotka_invariant.(
        getindex.(solution.u, 1),
        getindex.(solution.u, 2),
        0.1,
        0.02,
        0.01,
        0.3,
    )
    @test maximum(abs.(values .- first(values))) < 1e-7
    @test minimum(minimum.(solution.u)) > 0.0
end
