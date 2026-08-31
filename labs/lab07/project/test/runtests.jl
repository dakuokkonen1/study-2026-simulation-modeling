using Test, Statistics, StableRNGs, DataFrames, LinearAlgebra
include("../src/MMCQueue.jl")
include("../src/RossRepair.jl")
using .MMCQueue, .RossRepair

@testset "M/M/c: process and resource invariants" begin
    q = simulate_mmc(num_customers=1000)
    c, e = q.customers, q.events
    @test nrow(c) == 1000
    @test nrow(e) == 3001
    @test all(isfinite,c.departure)
    @test all(c.arrival .<= c.start .<= c.departure)
    @test issorted(c.start) # FIFO
    @test all(e.queue .>= 0)
    @test all(0 .<= e.busy .<= 2)
    @test e.system == e.queue+e.busy
    @test last(e.system) == 0
    @test q.final_time == maximum(c.departure)
    @test c == simulate_mmc(num_customers=1000).customers
    @test c != simulate_mmc(num_customers=1000,seed=124).customers
    @test count(==("departure"),e.event) == 1000
    @test isapprox(sum(c.wait),sum(diff(e.time).*e.queue[1:end-1]);rtol=1e-12)
    @test isapprox(sum(c.service),sum(diff(e.time).*e.busy[1:end-1]);rtol=1e-12)
    @test isapprox(sum(c.sojourn),sum(diff(e.time).*e.system[1:end-1]);rtol=1e-12)
    @test_throws ArgumentError simulate_mmc(λ=0)
    @test_throws ArgumentError simulate_mmc(num_servers=0)
    @test_throws ArgumentError simulate_mmc(num_customers=0)
    @test_throws ArgumentError queue_summary(q,warmup=1000)
end

@testset "Erlang C: independent M/M/1 formulas" begin
    x = erlang_c(0.3,0.5,1)
    @test x.rho ≈ 0.6
    @test x.W ≈ 1/(0.5-0.3)
    @test x.Lq ≈ 0.6^2/(1-0.6)
    @test x.Wq ≈ 0.3/(0.5*(0.5-0.3))
    @test x.p_wait ≈ 0.6
    @test erlang_c(0.9,0.5,2).Wq ≈ 8.526315789473685
    @test !erlang_c(0.5,0.5,1).stable
    @test ismissing(erlang_c(0.6,0.5,1).Wq)
    @test_throws ArgumentError erlang_c(-0.1,0.5,1)
    q = queue_summary(simulate_mmc(num_customers=50000,λ=0.3,μ=0.5,
        num_servers=1,seed=1234);warmup=5000)
    @test isapprox(q.Wq,x.Wq;rtol=0.15)
    @test isapprox(q.utilization,x.rho;atol=0.025)
end

@testset "Ross: reference sequence and event monitoring" begin
    rng = StableRNG(42)
    reference = [12715.718224958666,37335.53567595007,30844.62667837361,
        1601.2524911974856,824.1048708405848]
    runs = [simulate_repair(;rng) for _ in 1:5]
    @test [r.summary.crash_time for r in runs] ≈ reference
    for r in runs
        e,s = r.events,r.summary
        @test all(e.healthy+e.broken .== s.N+s.S)
        @test all(e.working[1:end-2] .== s.N)
        @test last(e.healthy) == s.N-1
        @test last(e.event) == "crash"
        @test all(e.queue .>= 0)
        @test all(0 .<= e.busy .<= s.repairers)
        @test all(e.queue .== e.broken-e.busy)
        @test isapprox(sum(diff(e.time).*e.queue[1:end-1]),s.area_queue;rtol=1e-12)
        @test isapprox(sum(diff(e.time).*e.busy[1:end-1]),s.area_busy;rtol=1e-12)
        @test 0 <= s.utilization <= 1
    end
    for repairers in 1:3
        r = simulate_repair(N=20,repairers=repairers,seed=7)
        @test maximum(r.events.busy) <= repairers
        @test r.summary.final_healthy == 19
    end
    @test simulate_repair(record_events=false).summary == first(runs).summary
    @test isempty(simulate_repair(record_events=false).events)
    zero_spare = simulate_repair(N=1,S=0)
    @test zero_spare.summary.final_healthy == 0
    @test zero_spare.summary.utilization == 0
    @test_throws ArgumentError simulate_repair(N=0)
    @test_throws ArgumentError simulate_repair(S=-1)
end

@testset "Ross: absorbing CTMC and independent recurrence" begin
    @test analytic_repair().mean_time ≈ 12340
    for N in (1,5,10,20), S in 0:5
        x = analytic_repair(;N,S)
        @test isapprox(x.mean_time,one_repair_mean(N,S,100.0,1.0);rtol=1e-5)
        @test all(x.occupation.expected_time .>= 0)
        @test sum(x.occupation.fraction) ≈ 1
        @test 0 <= x.utilization <= 1
        @test x.mean_queue >= 0
    end
    @test analytic_repair(N=5,S=0).mean_time ≈ 100/5
    @test analytic_repair(S=0).utilization == 0
    @test analytic_repair(repairers=3).mean_queue == 0
    @test analytic_repair(repairers=2).mean_time > analytic_repair().mean_time
    @test analytic_repair(N=20).mean_time < analytic_repair(N=10).mean_time
    @test analytic_repair().residual < 1e-9
end
