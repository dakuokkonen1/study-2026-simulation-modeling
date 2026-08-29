using Test
include(joinpath(@__DIR__, "..", "src", "tcp_red.jl"))
using .TCPRED

@testset "RED probability" begin
    red = REDParameters()
    @test red_probability(50.0, red) == 0.0
    @test isapprox(red_probability(112.5, red), 0.05)
    @test red_probability(150.0, red) == 0.1
end

@testset "TCP/RED simulation" begin
    net = NetworkParameters(flows=25, duration=12.0, dt=0.002)
    red = REDParameters()
    r = simulate_tcp_red(; network=net, red, seed=42)
    @test length(r.time) == length(r.queue)
    @test all(0 .<= r.queue .<= red.limit)
    @test all(r.cwnd_first .>= 1.0)
    @test all(0 .<= r.drop_probability .<= red.pmax)
    @test maximum(r.throughput_mbps) <= net.capacity_bps/1e6 + 1e-9
    @test r.delivered_packets > 0
    @test r.losses > 0
end
