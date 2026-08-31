using DrWatson
@quickactivate "project"
include(srcdir("RossRepair.jl"))
using .RossRepair
using StableRNGs
include(srcdir("experiment_support.jl"))

rng = StableRNG(42)
runs, trajectories = NamedTuple[], DataFrame[]
for run_id in 1:5
    result = simulate_repair(N=10,S=3,repairers=1,failure_mean=100.0,repair_mean=1.0;
        rng, verbose=true)
    push!(runs, merge((run=run_id, seed=42), result.summary))
    push!(trajectories, insertcols!(result.events, 1, :run=>run_id))
end
results, events = DataFrame(runs), vcat(trajectories...)
save_table("ross_runs.csv", results)
save_table("ross_events.csv", events)
println("Average crash time: ", mean(results.crash_time))
results

theory = analytic_repair()
estimate = mean_interval(results.crash_time)
comparison = DataFrame([(runs=5, mean_time=estimate.mean, se=estimate.se,
    ci_low=estimate.ci_low, ci_high=estimate.ci_high, theory_time=theory.mean_time,
    utilization=sum(results.area_busy)/sum(results.crash_time), theory_utilization=theory.utilization,
    mean_queue=sum(results.area_queue)/sum(results.crash_time), theory_queue=theory.mean_queue)])
save_table("ross_comparison.csv", comparison)
save_table("ross_occupation_theory.csv", theory.occupation)
comparison

first_run = filter(:run=>==(1), events)
p_full = repair_plot(first_run,10)
savefig(p_full,imagepath("06-plot.png"))
display(p_full)

t_crash = last(first_run.time)
tail_start = max(0.0,t_crash-60)
prior = max(1,searchsortedlast(first_run.time,tail_start))
p_tail = repair_plot(first_run[prior:end,:],10; title="Last 60 hours: exhaustion and crash")
savefig(p_tail,imagepath("07-plot.png"))
display(p_tail)

p_runs = bar(results.run,results.crash_time; color=:royalblue, label="Five DES runs",
    xlabel="Run", ylabel="Crash time (h)", title="Five observations are not a precise mean")
hline!(p_runs,[theory.mean_time]; color=:firebrick, linestyle=:dash, label="CTMC mean")
savefig(p_runs,imagepath("08-plot.png"))
display(p_runs)
theory.occupation
