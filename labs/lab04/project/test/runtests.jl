using Test, Agents
include("../src/sir_model.jl")
using .AgentSIR

@testset "SIR: initial state and probabilities" begin
    m = initialize_sir()
    @test counts(m).total == 3000
    @test counts(m).infected == 1
    @test city_counts(m, 3).infected == 1
    @test all(vec(sum(m.migration_rates; dims = 2)) .≈ 1)
    M = create_migration_matrix(3, 0.3)
    @test M[1, 1] ≈ 0.7
    @test M[1, 2] ≈ 0.15
    @test_throws ArgumentError create_migration_matrix(3, 1.1)
    @test_throws ArgumentError initialize_sir(death_rate = -0.1)
    @test_throws ArgumentError initialize_sir(
        Ns = [10, 10, 10],
        Is = [11, 0, 0],
    )
    @test_throws ArgumentError initialize_sir(
        migration_rates = zeros(3, 3),
    )
end

@testset "SIR: reproducibility and accounting" begin
    a, b = initialize_sir(Ns = [50, 50, 50]),
    initialize_sir(Ns = [50, 50, 50])
    for _ in 1:20
        advance!(a)
        advance!(b)
        @test counts(a) == counts(b)
        c = counts(a)
        @test c.susceptible+c.infected+c.recovered+c.deaths == 150
        @test c.total == nagents(a)
        @test sum(city_counts(a, i).total for i in 1:3) == c.total
    end
end

@testset "SIR: limiting cases" begin
    m = initialize_sir(Ns = [10, 10, 10], Is = [0, 0, 0])
    advance!(m, 30)
    @test counts(m).infected == 0
    @test counts(m).deaths == 0
    m = initialize_sir(
        Ns = [10, 10, 10],
        β_und = zeros(3),
        β_det = zeros(3),
        death_rate = 0.0,
    )
    advance!(m, 20)
    @test counts(m).recovered == 1
    @test counts(m).total == 30
    m = initialize_sir(
        Ns = [10, 10, 10],
        β_und = zeros(3),
        β_det = zeros(3),
        death_rate = 1.0,
    )
    advance!(m, 20)
    @test counts(m).deaths == 1
    @test counts(m).total == 29
end

@testset "SIR: quarantine and independent replicates" begin
    M = create_migration_matrix(3, 0.3)
    m = initialize_sir(
        Ns = [10, 10, 10],
        Is = [2, 0, 0],
        migration_rates = M,
        quarantine_threshold = 0.1,
    )
    update_quarantine!(m)
    @test m.closed == [true, false, false]
    @test m.migration_rates[1, :] == [1, 0, 0]
    @test m.migration_rates[2, :] == M[2, :]
    @test M[1, 2] ≈ 0.15
    x = [0.1, 3.0, 0.01]
    forward = objective_replicates(
        x;
        seeds = 43:45,
        Ns = [20, 20, 20],
        n_steps = 20,
    )
    backward = objective_replicates(
        x;
        seeds = 45:-1:43,
        Ns = [20, 20, 20],
        n_steps = 20,
    )
    @test forward.peak ≈ backward.peak
    @test forward.death_fraction ≈ backward.death_fraction
    @test forward.max_peak == backward.max_peak
end
