module TCPRED

using Random
using Statistics

export REDParameters, NetworkParameters, TCPREDResult, red_probability, simulate_tcp_red

Base.@kwdef struct REDParameters
    qmin::Float64 = 75.0
    qmax::Float64 = 150.0
    weight::Float64 = 0.002
    pmax::Float64 = 0.1
    limit::Float64 = 300.0
end

Base.@kwdef struct NetworkParameters
    flows::Int = 25
    capacity_bps::Float64 = 20e6
    packet_bytes::Int = 500
    propagation_rtt::Float64 = 0.118
    duration::Float64 = 30.0
    dt::Float64 = 0.002
end

struct TCPREDResult
    time::Vector{Float64}
    cwnd_first::Vector{Float64}
    cwnd_mean::Vector{Float64}
    queue::Vector{Float64}
    average_queue::Vector{Float64}
    drop_probability::Vector{Float64}
    throughput_mbps::Vector{Float64}
    losses::Int
    delivered_packets::Float64
end

function red_probability(qavg::Real, red::REDParameters)
    qavg < red.qmin && return 0.0
    qavg >= red.qmax && return red.pmax
    return red.pmax * (qavg - red.qmin) / (red.qmax - red.qmin)
end

function simulate_tcp_red(; network::NetworkParameters=NetworkParameters(),
                          red::REDParameters=REDParameters(), seed::Integer=202604)
    network.flows > 0 || throw(ArgumentError("flows must be positive"))
    network.dt > 0 || throw(ArgumentError("dt must be positive"))
    network.duration > network.dt || throw(ArgumentError("duration is too short"))
    red.qmin < red.qmax <= red.limit || throw(ArgumentError("invalid RED thresholds"))

    rng = MersenneTwister(seed)
    steps = floor(Int, network.duration / network.dt) + 1
    time = collect(range(0.0; step=network.dt, length=steps))
    cwnd = fill(1.0, network.flows)
    ssthresh = fill(32.0, network.flows)
    queue = 0.0
    qavg = 0.0
    losses = 0
    delivered = 0.0
    packet_bits = 8.0 * network.packet_bytes
    service_rate = network.capacity_bps / packet_bits

    first_history = zeros(steps)
    mean_history = zeros(steps)
    queue_history = zeros(steps)
    average_history = zeros(steps)
    probability_history = zeros(steps)
    throughput_history = zeros(steps)

    for k in eachindex(time)
        first_history[k] = cwnd[1]
        mean_history[k] = mean(cwnd)
        queue_history[k] = queue
        average_history[k] = qavg
        p = red_probability(qavg, red)
        probability_history[k] = p

        rtt = network.propagation_rtt + queue / service_rate
        sent = cwnd ./ rtt .* network.dt
        arrivals = sum(sent)
        accepted = 0.0

        for i in eachindex(cwnd)
            congestion_probability = 1 - (1 - p)^sent[i]
            if queue >= red.limit || rand(rng) < congestion_probability
                cwnd[i] = max(cwnd[i] / 2, 1.0)
                ssthresh[i] = cwnd[i]
                losses += 1
            else
                accepted += sent[i]
                if cwnd[i] < ssthresh[i]
                    cwnd[i] += sent[i]
                else
                    cwnd[i] += network.dt / rtt
                end
            end
        end

        queue = min(red.limit, queue + accepted)
        served = min(queue, service_rate * network.dt)
        queue -= served
        delivered += served
        throughput_history[k] = served * packet_bits / network.dt / 1e6
        qavg = (1 - red.weight) * qavg + red.weight * queue
    end

    return TCPREDResult(time, first_history, mean_history, queue_history,
        average_history, probability_history, throughput_history, losses, delivered)
end

end
