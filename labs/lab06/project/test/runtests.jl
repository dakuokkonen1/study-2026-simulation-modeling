using Test, Random, DataFrames, CSV
include(joinpath(@__DIR__, "..", "src", "SIRPetri.jl"))
using .SIRPetri
using AlgebraicPetri

@testset "Petri structure and rates" begin
    net, u0, names = build_sir_network()
    @test ns(net) == 3
    @test nt(net) == 2
    @test names == [:S, :I, :R]
    @test stoichiometry(net) == [-1 0; 1 -1; 0 1]
    @test sum(stoichiometry(net); dims=1) == zeros(1, 2)
    du = zeros(3)
    sir_ode(net)(du, u0, nothing, 0.0)
    @test du ≈ [-2970.0, 2969.0, 1.0]
    @test_throws ArgumentError build_sir_network(-1, .1)
end

@testset "Deterministic solution" begin
    net, u0, _ = build_sir_network()
    df = simulate_deterministic(net, u0, (0.0,100.0); saveat=.5)
    @test nrow(df) == 201
    @test names(df) == ["time","S","I","R"]
    @test maximum(abs.(df.S .+ df.I .+ df.R .- 1000)) < 1e-6
    @test minimum(Matrix(df[:,2:4])) >= -1e-7
    @test df.time[end] == 100
    peak = refined_peak(net, u0, (0.0,100.0))
    @test isapprox(peak.peak, peak.analytic; atol=1e-5)
    @test 0 < peak.time < .5
    @test peak.peak > maximum(df.I)
    @test 996 < peak.peak < 998
    no_infection = simulate_deterministic(net,u0,(0.0,2.0); rates=[0.0,.1])
    @test all(isapprox.(no_infection.S, 990; atol=1e-7))
    @test isapprox(no_infection.I[end],10exp(-.2); atol=1e-7)
end

@testset "Exact event simulation" begin
    net, u0, _ = build_sir_network()
    a = simulate_stochastic(net,u0,(0.0,100.0);rng=Xoshiro(123))
    b = simulate_stochastic(net,u0,(0.0,100.0);rng=Xoshiro(123))
    @test a == b
    @test eltype(a.S) <: Integer
    @test all(a.S .+ a.I .+ a.R .== 1000)
    @test minimum(Matrix(a[:,2:4])) >= 0
    @test all(diff(a.time) .> 0)
    @test a.time[end] == 100
    @test all(diff(a.S) .<= 0)
    @test all(diff(a.R) .>= 0)
    changes = diff(Matrix(a[:,2:4]); dims=1)
    @test all(collect(r) in ([-1,1,0],[0,-1,1],[0,0,0]) for r in eachrow(changes))
    shifted = simulate_stochastic(net,u0,(5.0,5.001);rng=Xoshiro(42))
    @test first(shifted.time)==5 && last(shifted.time)==5.001
    zero = simulate_stochastic(net,[990,0,10],(0.0,100.0))
    @test nrow(zero)==2 && zero.R[end]==10
    @test_throws ArgumentError simulate_stochastic(net,[1.5,1,0],(0.0,1.0))
    @test_throws ArgumentError simulate_stochastic(net,u0,(2.0,1.0))
    toy=DataFrame(time=[0.,1.,2.],S=[5,4,3],I=[1,2,3],R=[0,0,0])
    @test state_at(toy,[0.,.9,1.,1.9,2.]).I == [1,1,2,2,3]
end

@testset "Saved scenario outputs" begin
    data = joinpath(@__DIR__, "..", "data")
    scan = CSV.read(joinpath(data,"sir_scan.csv"),DataFrame)
    @test nrow(scan)==15
    @test scan.β ≈ collect(.1:.05:.8)
    @test all(scan.peak_I .> 900)
    runs=CSV.read(joinpath(data,"sir_param_replicates.csv"),DataFrame)
    @test nrow(runs)==180
    @test length(unique(runs.seed))==180
    @test all(combine(groupby(runs,[:β,:γ]), nrow=>:n).n .== 20)
    @test nrow(CSV.read(joinpath(data,"sir_scan_param.csv"),DataFrame))==45
    @test nrow(CSV.read(joinpath(data,"sir_animation.csv"),DataFrame))==501
    anim=CSV.read(joinpath(data,"sir_animation_param_summary.csv"),DataFrame)
    @test nrow(anim)==3 && all(anim.frames .== 501)
    @test nrow(CSV.read(joinpath(data,"sir_comparison.csv"),DataFrame))==201
end
