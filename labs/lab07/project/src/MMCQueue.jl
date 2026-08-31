module MMCQueue

using ConcurrentSim, ResumableFunctions, Distributions, StableRNGs, Random
using DataFrames, Statistics
export simulate_mmc, erlang_c, queue_summary

const QueueEvent = NamedTuple{(:time, :event, :customer, :queue, :busy, :system),
    Tuple{Float64, String, Int, Int, Int, Int}}
mutable struct QueueMonitor
    queue::Int
    busy::Int
    events::Vector{QueueEvent}
end

function record!(m::QueueMonitor, env, event, id)
    push!(m.events, (time=Float64(now(env)), event=event, customer=id,
        queue=m.queue, busy=m.busy, system=m.queue+m.busy))
end

@resumable function customer(env::Environment, server::Resource, id::Int,
        arrival::Float64, service::Exponential, rng::AbstractRNG,
        monitor::QueueMonitor, starts::Vector{Float64}, ends::Vector{Float64},
        verbose::Bool)
    @yield timeout(env, arrival)
    monitor.queue += 1
    record!(monitor, env, "arrival", id)
    verbose && println("Customer $id arrived: ", now(env))
    @yield request(server)
    monitor.queue -= 1
    monitor.busy += 1
    starts[id] = now(env)
    record!(monitor, env, "service_start", id)
    verbose && println("Customer $id entered service: ", now(env))
    @yield timeout(env, rand(rng, service))
    ends[id] = now(env)
    monitor.busy -= 1
    record!(monitor, env, "departure", id)
    @yield unlock(server)
    verbose && println("Customer $id exited service: ", now(env))
end

"""FIFO M/M/c; rates are λ and μ, while Exponential accepts their inverses."""
function simulate_mmc(; num_customers=10, num_servers=2, λ=0.9, μ=0.5,
        seed=123, rng=StableRNG(seed), verbose=false)
    num_customers > 0 || throw(ArgumentError("num_customers must be positive"))
    num_servers > 0 || throw(ArgumentError("num_servers must be positive"))
    all(isfinite, (λ, μ)) && λ > 0 && μ > 0 || throw(ArgumentError("positive finite rates required"))
    env = Simulation()
    server = Resource(env, num_servers)
    monitor = QueueMonitor(0, 0, QueueEvent[])
    record!(monitor, env, "initial", 0)
    arrivals = cumsum(rand(rng, Exponential(1 / λ), num_customers))
    starts, ends = fill(NaN, num_customers), fill(NaN, num_customers)
    for id in 1:num_customers
        @process customer(env, server, id, arrivals[id], Exponential(1 / μ),
            rng, monitor, starts, ends, verbose)
    end
    run(env)
    clients = DataFrame(id=1:num_customers, arrival=arrivals, start=starts,
        departure=ends, wait=starts-arrivals, service=ends-starts,
        sojourn=ends-arrivals)
    # run(env) can move the empty calendar to its default Inf horizon.
    # The observed completion time is the last actual departure.
    return (customers=clients, events=DataFrame(monitor.events),
        final_time=maximum(ends), num_servers=num_servers, λ=Float64(λ), μ=Float64(μ))
end

"""Erlang C stationary characteristics; missing values when ρ ≥ 1."""
function erlang_c(λ, μ, c::Integer)
    λ > 0 && μ > 0 && c > 0 || throw(ArgumentError("positive rates and capacity required"))
    ρ = λ / (c * μ)
    ρ >= 1 && return (rho=ρ, stable=false, p0=missing, p_wait=missing,
        Lq=missing, Wq=missing, W=missing, L=missing)
    a = λ / μ
    term, total = 1.0, 1.0
    for k in 1:c-1
        term *= a / k
        total += term
    end
    tail = term * a / c / (1-ρ)
    p0 = 1 / (total+tail)
    p_wait = tail * p0
    Lq = ρ / (1-ρ) * p_wait
    Wq = Lq / λ
    W = Wq + 1 / μ
    return (rho=ρ, stable=true, p0=p0, p_wait=p_wait, Lq=Lq, Wq=Wq, W=W, L=λ*W)
end

function time_average(events, field, t0, t1)
    t1 > t0 || throw(ArgumentError("nonempty observation interval required"))
    area = 0.0
    for i in 1:nrow(events)-1
        dt = max(0.0, min(t1, events.time[i+1])-max(t0, events.time[i]))
        area += dt * events[i, field]
    end
    area / (t1-t0)
end

"""Customer metrics after warm-up; state metrics on the same arrival window.

The queue is drained, so selected customers have uncensored sojourn times.
State integrals stop at the last arrival to exclude the artificial drain phase.
Finite-window Little-law discrepancies are reported, not assumed to vanish.
"""
function queue_summary(result; warmup=0)
    allclients = result.customers
    0 <= warmup < nrow(allclients)-1 || throw(ArgumentError("invalid warmup count"))
    clients = allclients[warmup+1:end, :]
    t0 = warmup == 0 ? 0.0 : first(clients.arrival)
    t1 = last(clients.arrival)
    Lq = time_average(result.events, :queue, t0, t1)
    L = time_average(result.events, :system, t0, t1)
    busy = time_average(result.events, :busy, t0, t1)
    Wq, W = mean(clients.wait), mean(clients.sojourn)
    return (λ=result.λ, μ=result.μ, c=result.num_servers, customers=nrow(allclients),
        warmup=warmup, observed=nrow(clients), t0=t0, t1=t1,
        Wq=Wq, W=W, Lq=Lq, L=L, utilization=busy/result.num_servers,
        p_wait=mean(clients.wait .> 1e-10), mean_service=mean(clients.service),
        little_Lq_residual=Lq-result.λ*Wq, little_L_residual=L-result.λ*W)
end

end
