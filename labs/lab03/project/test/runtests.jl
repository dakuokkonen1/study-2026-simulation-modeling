using Test, Agents
include("../src/daisyworld.jl")
using .DaisyworldModel

@testset "Daisyworld: initial state and constraints" begin
    m = daisyworld()
    @test measure(m).white == 180
    @test measure(m).black == 180
    @test length(unique(a.pos for a in allagents(m))) == nagents(m)
    @test all(isfinite, m.temperature)
    @test_throws ArgumentError daisyworld(
        init_white = 0.9,
        init_black = 0.2,
    )
    @test_throws ArgumentError daisyworld(max_age = 0)
    @test_throws ArgumentError daisyworld(griddims = (2, 2))
end
@testset "Daisyworld: dynamics and reproducibility" begin
    a, b = daisyworld(seed = 165), daisyworld(seed = 165)
    advance!(a, 45)
    advance!(b, 45)
    @test measure(a) == measure(b)
    @test a.temperature == b.temperature
    @test a.tick == 45
    @test nagents(a) <= 900
    @test 0 <= measure(a).albedo <= 1
    @test all(x -> x.age < a.max_age, allagents(a))
    empty = daisyworld(init_white = 0.0, init_black = 0.0)
    advance!(empty, 10)
    @test nagents(empty) == 0
end
@testset "Daisyworld: prescribed solar schedule" begin
    m = daisyworld(scenario = :ramp, init_white = 0.0, init_black = 0.0)
    advance!(m, 200)
    @test m.solar_luminosity ≈ 1.0
    advance!(m, 200)
    @test m.solar_luminosity ≈ 2.0
    advance!(m, 100)
    @test m.solar_luminosity ≈ 2.0
    advance!(m, 250)
    @test m.solar_luminosity ≈ 1.375
    advance!(m, 250)
    @test m.solar_luminosity ≈ 1.375
end
