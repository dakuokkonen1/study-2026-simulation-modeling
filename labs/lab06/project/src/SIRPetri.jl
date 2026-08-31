module SIRPetri

using AlgebraicPetri
using Catlab.CategoricalAlgebra
using Catlab.Graphics
import Catlab.Graphics.Graphviz
using OrdinaryDiffEq
using DataFrames, Plots, Random

export build_sir_network, sir_ode, simulate_deterministic, simulate_stochastic
export plot_sir, to_graphviz_sir, stoichiometry, state_at, refined_peak

"""S + I → 2I и I → R; массовое действие βSI без нормирования на N."""
function build_sir_network(β=0.3, γ=0.1)
    all(isfinite, (β, γ)) && min(β, γ) >= 0 || throw(ArgumentError("Invalid rates"))
    net = LabelledPetriNet([:S, :I, :R],
        :infection => ((:S, :I) => (:I, :I)), :recovery => (:I => :R))
    net, [990.0, 10.0, 0.0], [:S, :I, :R]
end

"""Матрица изменений маркировки вычисляется из дуг сети, а не задаётся вручную."""
function stoichiometry(net)
    C = zeros(Int, ns(net), nt(net))
    for t in 1:nt(net)
        for s in inputs(net, t); C[s, t] -= 1; end
        for s in outputs(net, t); C[s, t] += 1; end
    end
    C
end

function validate(net, u0, tspan, rates)
    length(u0) == ns(net) == 3 || throw(ArgumentError("Three states required"))
    length(rates) == nt(net) || throw(ArgumentError("One rate per transition required"))
    all(isfinite, u0) && all(>=(0), u0) || throw(ArgumentError("Invalid marking"))
    all(isfinite, rates) && all(>=(0), rates) || throw(ArgumentError("Invalid rates"))
    all(isfinite, tspan) && tspan[2] >= tspan[1] || throw(ArgumentError("Invalid interval"))
end

"""Правая часть ОДУ автоматически порождается настоящей сетью AlgebraicPetri."""
function sir_ode(net, rates=[0.3, 0.1])
    # Сохраняем дуги и порядок состояний, снимая символьные метки для Vector.
    f! = vectorfield(PetriNet(net))
    (du, u, p, t) -> f!(du, u, rates, t)
end

function simulate_deterministic(net, u0, tspan; saveat=0.1, rates=[0.3, 0.1])
    validate(net, u0, tspan, rates)
    prob = ODEProblem(sir_ode(net, rates), Float64.(u0), tspan)
    sol = solve(prob, Tsit5(); saveat, reltol=1e-9, abstol=1e-10)
    string(sol.retcode) == "Success" || error("ODE solver failed: $(sol.retcode)")
    DataFrame(time=sol.t, S=sol[1, :], I=sol[2, :], R=sol[3, :])
end

"""Прямой метод Гиллеспи: события записываются на собственной временной сетке."""
function simulate_stochastic(net, u0, tspan; rates=[0.3, 0.1], rng=Random.default_rng())
    validate(net, u0, tspan, rates)
    all(isinteger, u0) || throw(ArgumentError("SSA requires integer tokens"))
    u = Int.(u0)
    C = stoichiometry(net)
    t, tend = Float64.(tspan)
    df = DataFrame(time=[t], S=[u[1]], I=[u[2]], R=[u[3]])
    while t < tend
        propensities = [rates[j] * prod(u[s] for s in inputs(net, j)) for j in 1:nt(net)]
        total = sum(propensities)
        total > 0 || break
        next_t = t - log(rand(rng)) / total
        next_t <= tend || break
        transition = searchsortedfirst(cumsum(propensities), rand(rng) * total)
        u .+= C[:, transition]
        minimum(u) >= 0 || error("Negative token count")
        t = next_t
        push!(df, (t, u[1], u[2], u[3]))
    end
    df.time[end] < tend && push!(df, (tend, u[1], u[2], u[3]))
    df
end

"""Правосторонне непрерывная маркировка SSA без переноса событий на чужие времена."""
function state_at(df, times)
    ids = clamp.(searchsortedlast.(Ref(df.time), times), 1, nrow(df))
    DataFrame(time=Float64.(times), S=df.S[ids], I=df.I[ids], R=df.R[ids])
end

function plot_sir(df; stochastic=false, title="SIR", kwargs...)
    plot(df.time, Matrix(df[:, [:S, :I, :R]]);
        label=["S" "I" "R"], color=[:royalblue :firebrick :seagreen],
        seriestype=stochastic ? :steppost : :path, linewidth=2,
        xlabel="Time", ylabel="Population", title, kwargs...)
end

to_graphviz_sir(net) = Graphviz.Graph(net; prog="dot")

"""Уточнённый пик по условию S=γ/β; не заменяет максимум на заданной сетке."""
function refined_peak(net, u0, tspan; rates=[0.3, 0.1])
    β, γ = rates
    β > 0 && u0[1] > γ / β || return (time=tspan[1], peak=u0[2], analytic=u0[2])
    sol = solve(ODEProblem(sir_ode(net, rates), Float64.(u0), tspan), Tsit5();
        reltol=1e-10, abstol=1e-11, dense=true)
    lo, hi = Float64.(tspan)
    if sol(hi)[1] > γ / β
        return (time=hi, peak=sol(hi)[2], analytic=NaN)
    end
    for _ in 1:70
        mid = (lo + hi) / 2
        sol(mid)[1] > γ / β ? (lo = mid) : (hi = mid)
    end
    t = (lo + hi) / 2
    sstar = γ / β
    analytic = u0[2] + u0[1] - sstar + sstar * log(sstar / u0[1])
    (time=t, peak=sol(t)[2], analytic=analytic)
end

end
