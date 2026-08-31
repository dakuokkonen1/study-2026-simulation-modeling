module RossRepair

using ConcurrentSim, ResumableFunctions, Distributions, StableRNGs, Random
using DataFrames, LinearAlgebra
export simulate_repair, analytic_repair, one_repair_mean

const RepairEvent = NamedTuple{(:time, :event, :machine, :healthy, :working,
    :spares, :broken, :busy, :queue), Tuple{Float64, String, Int, Int, Int, Int, Int, Int, Int}}
mutable struct RepairMonitor
    N::Int
    S::Int
    broken::Int
    busy::Int
    last_time::Float64
    area_queue::Float64
    area_busy::Float64
    record_events::Bool
    events::Vector{RepairEvent}
end

function record!(m::RepairMonitor, env, event, id; broken_delta=0, busy_delta=0)
    time = Float64(now(env))
    dt = time-m.last_time
    m.area_queue += dt * (m.broken-m.busy)
    m.area_busy += dt * m.busy
    m.last_time = time
    m.broken += broken_delta
    m.busy += busy_delta
    if m.record_events
        healthy = m.N+m.S-m.broken
        push!(m.events, (time=time, event=event, machine=id, healthy=healthy,
            working=min(m.N, healthy), spares=max(healthy-m.N, 0),
            broken=m.broken, busy=m.busy, queue=m.broken-m.busy))
    end
end

@resumable function machine(env::Environment, repair::Resource, spares::Store{Process},
        id::Int, F::Exponential, G::Exponential, rng::AbstractRNG, monitor::RepairMonitor)
    while true
        try
            @yield timeout(env, Inf)
        catch exception
            exception isa ConcurrentSim.InterruptException || rethrow()
            # A spare becomes active when interrupted by the failed machine.
        end
        @yield timeout(env, rand(rng, F))
        record!(monitor, env, "failure", id; broken_delta=1)
        get_spare = take!(spares)
        @yield get_spare | timeout(env)
        if state(get_spare) != ConcurrentSim.idle
            @yield interrupt(value(get_spare))
        else
            record!(monitor, env, "crash", id)
            throw(StopSimulation("No more spares!"))
        end
        @yield request(repair)
        record!(monitor, env, "repair_start", id; busy_delta=1)
        @yield timeout(env, rand(rng, G))
        record!(monitor, env, "repair_complete", id; broken_delta=-1, busy_delta=-1)
        @yield unlock(repair)
        @yield put!(spares, active_process(env))
    end
end

@resumable function start_system(env::Environment, repair::Resource,
        spares::Store{Process}, N::Int, S::Int, F::Exponential, G::Exponential,
        rng::AbstractRNG, monitor::RepairMonitor)
    for id in 1:N
        process = @process machine(env, repair, spares, id, F, G, rng, monitor)
        @yield interrupt(process)
    end
    for id in N+1:N+S
        process = @process machine(env, repair, spares, id, F, G, rng, monitor)
        @yield put!(spares, process)
    end
end

"""Ross process model with N active machines, S cold spares and r repairers.

failure_mean and repair_mean are durations, not rates. No spare fails while idle.
Stop at the failure that reduces the number of healthy machines to N-1.
"""
function simulate_repair(; N=10, S=3, repairers=1, failure_mean=100.0,
        repair_mean=1.0, seed=42, rng=StableRNG(seed), record_events=true, verbose=false)
    N > 0 && S >= 0 && repairers > 0 || throw(ArgumentError("invalid machine or repairer count"))
    all(isfinite, (failure_mean,repair_mean)) && failure_mean > 0 && repair_mean > 0 ||
        throw(ArgumentError("positive finite mean durations required"))
    env = Simulation()
    repair = Resource(env, repairers)
    spares = Store{Process}(env)
    monitor = RepairMonitor(N, S, 0, 0, 0.0, 0.0, 0.0, record_events, RepairEvent[])
    record!(monitor, env, "initial", 0)
    @process start_system(env, repair, spares, N, S, Exponential(failure_mean),
        Exponential(repair_mean), rng, monitor)
    message = run(env)
    time = Float64(now(env))
    verbose && println("At time $time: $message")
    monitor.broken == S+1 || error("Unexpected stop before exhaustion of spares")
    summary = (N=N, S=S, repairers=repairers, failure_mean=Float64(failure_mean),
        repair_mean=Float64(repair_mean), crash_time=time,
        mean_queue=monitor.area_queue/time, utilization=monitor.area_busy/(repairers*time),
        area_queue=monitor.area_queue, area_busy=monitor.area_busy,
        final_healthy=N+S-monitor.broken, final_broken=monitor.broken)
    return (summary=summary, events=DataFrame(monitor.events))
end

"""Transient CTMC on broken-machine states 0:S; state S+1 is absorbing.

Before crash the failure rate is N/failure_mean. The total repair rate in
state k is min(k,repairers)/repair_mean. Occupation rewards are ratios of
expected integrated quantities and E[T], matching pooled simulation estimates.
"""
function analytic_repair(; N=10, S=3, repairers=1, failure_mean=100.0, repair_mean=1.0)
    N > 0 && S >= 0 && repairers > 0 && failure_mean > 0 && repair_mean > 0 ||
        throw(ArgumentError("invalid parameters"))
    failure = N/failure_mean
    Q = zeros(S+1,S+1)
    for k in 0:S
        repair = min(k,repairers)/repair_mean
        Q[k+1,k+1] = -(failure+repair)
        k < S && (Q[k+1,k+2] = failure)
        k > 0 && (Q[k+1,k] = repair)
    end
    times = -Q \ ones(S+1)
    start = zeros(S+1); start[1] = 1.0
    occupation = transpose(-Q) \ start
    total = times[1]
    busy = min.(0:S, repairers)
    queue = max.(collect(0:S).-repairers, 0)
    return (mean_time=total, utilization=dot(occupation,busy)/(repairers*total),
        mean_queue=dot(occupation,queue)/total,
        residual=norm(Q*times.+1, Inf), Q=Q, times=times,
        occupation=DataFrame(broken=0:S, expected_time=occupation,
            fraction=occupation/total, busy=busy, queue=queue))
end

"""Independent recurrence for one repairer, used to check the matrix solution."""
function one_repair_mean(N, S, failure_mean, repair_mean)
    a, b = N/failure_mean, 1/repair_mean
    sum(sum((b/a)^j for j in 0:k) for k in 0:S)/a
end

end
