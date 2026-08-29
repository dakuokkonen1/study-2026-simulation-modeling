using Test
using DifferentialEquations

include(joinpath(@__DIR__, "..", "src", "exponential_growth.jl"))

@testset "Exponential growth" begin
    u0 = 1.0
    alpha = 0.3
    tspan = (0.0, 10.0)
    problem = ODEProblem(exponential_growth!, [u0], tspan, alpha)
    solution = solve(problem, Tsit5(); saveat=0.1)

    @test isapprox(last(solution.u)[1], analytic_solution(u0, alpha, last(solution.t)); rtol=1e-5)
    @test isapprox(doubling_time(alpha), 2.3104906018664844; rtol=1e-12)
    @test_throws ArgumentError doubling_time(0.0)
end

println("All lab01 tests passed")
