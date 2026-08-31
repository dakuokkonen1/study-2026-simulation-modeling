using DrWatson
@quickactivate "project"
include(srcdir("MMCQueue.jl"))
using .MMCQueue
include(srcdir("experiment_support.jl"))

result = simulate_mmc(num_customers=10, num_servers=2, λ=.9, μ=.5, seed=123, verbose=true)
save_table("mmc_customers.csv", result.customers)
save_table("mmc_events.csv", result.events)
result.customers

observed = DataFrame([queue_summary(result)])
save_table("mmc_summary.csv", observed)
observed

p_events = queue_plot(result.events; title="M/M/2: 10 customers, lambda=0.9, mu=0.5")
savefig(p_events, imagepath("01-plot.png"))
display(p_events)

p_clients = customer_timeline(result.customers)
savefig(p_clients, imagepath("02-plot.png"))
display(p_clients)

theory = DataFrame([erlang_c(.9, .5, 2)])
save_table("mmc_theory.csv", theory)
theory
