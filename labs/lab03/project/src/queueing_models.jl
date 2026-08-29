module QueueingModels

using Random
using Statistics

export MM1Result, theoretical_mm1, simulate_mm1

struct MM1Result
    arrival_rate::Float64
    service_rate::Float64
    horizon::Float64
    arrivals::Int
    served::Int
    lost::Int
    utilization::Float64
    mean_system::Float64
    mean_queue::Float64
    mean_wait::Float64
    mean_sojourn::Float64
    times::Vector{Float64}
    queue_lengths::Vector{Int}
    waits::Vector{Float64}
end

function theoretical_mm1(lambda::Real, mu::Real)
    lambda > 0 || throw(ArgumentError("lambda must be positive"))
    mu > lambda || throw(ArgumentError("stationary M/M/1 requires mu > lambda"))
    rho = lambda / mu
    return (
        rho=rho,
        mean_system=rho / (1 - rho),
        mean_queue=rho^2 / (1 - rho),
        mean_wait=rho / (mu - lambda),
        mean_sojourn=1 / (mu - lambda),
    )
end

function simulate_mm1(lambda::Real, mu::Real; horizon::Real=1000.0,
                      capacity::Integer=typemax(Int), seed::Integer=202603)
    lambda > 0 || throw(ArgumentError("lambda must be positive"))
    mu > 0 || throw(ArgumentError("mu must be positive"))
    horizon > 0 || throw(ArgumentError("horizon must be positive"))
    capacity >= 1 || throw(ArgumentError("capacity must be at least one"))

    rng = MersenneTwister(seed)
    next_arrival = randexp(rng) / lambda
    next_departure = Inf
    queue_arrivals = Float64[]
    service_start = 0.0
    t = 0.0
    last_t = 0.0
    area_system = 0.0
    area_queue = 0.0
    busy_area = 0.0
    arrivals = served = lost = 0
    waits = Float64[]
    sojourns = Float64[]
    times = Float64[0.0]
    queue_lengths = Int[0]

    while true
        event_time = min(next_arrival, next_departure)
        event_time > horizon && break
        n_system = length(queue_arrivals)
        dt = event_time - last_t
        area_system += n_system * dt
        area_queue += max(n_system - 1, 0) * dt
        busy_area += (n_system > 0) * dt
        t = event_time
        last_t = t

        if next_arrival <= next_departure
            arrivals += 1
            if length(queue_arrivals) < capacity
                push!(queue_arrivals, t)
                if length(queue_arrivals) == 1
                    service_start = t
                    next_departure = t + randexp(rng) / mu
                end
            else
                lost += 1
            end
            next_arrival = t + randexp(rng) / lambda
        else
            arrival_time = popfirst!(queue_arrivals)
            push!(waits, service_start - arrival_time)
            push!(sojourns, t - arrival_time)
            served += 1
            if isempty(queue_arrivals)
                next_departure = Inf
            else
                service_start = t
                next_departure = t + randexp(rng) / mu
            end
        end
        push!(times, t)
        push!(queue_lengths, max(length(queue_arrivals) - 1, 0))
    end

    dt = horizon - last_t
    n_system = length(queue_arrivals)
    area_system += n_system * dt
    area_queue += max(n_system - 1, 0) * dt
    busy_area += (n_system > 0) * dt

    return MM1Result(
        Float64(lambda), Float64(mu), Float64(horizon), arrivals, served, lost,
        busy_area / horizon, area_system / horizon, area_queue / horizon,
        isempty(waits) ? NaN : mean(waits),
        isempty(sojourns) ? NaN : mean(sojourns),
        times, queue_lengths, waits,
    )
end

end
