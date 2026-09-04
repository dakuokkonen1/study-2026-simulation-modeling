using DrWatson
@quickactivate "project"
using project.SIRDES
using CSV, DataFrames, Statistics, StatsPlots
include(srcdir("experiments.jl"))
using .Experiments

using BenchmarkTools

function fresh_model(N)
    I0=N÷100
    m=MakeSIRModel([N-I0,I0,0],BASE_P;seed=1234)
    activate(m)
end

rows=NamedTuple[]
samples=NamedTuple[]
for N in (1000,10000)
    sir_run(fresh_model(N),40.0) # прогрев компиляции вне измерения
    trial=@benchmark sir_run(m,40.0) setup=(m=fresh_model($N)) evals=1 samples=10 seconds=3600
    push!(rows,(;N,samples=length(trial),median_ms=median(trial).time/1e6,
        minimum_ms=minimum(trial).time/1e6,memory_bytes=median(trial).memory,
        allocations=median(trial).allocs))
    append!(samples,[(;N,sample=j,time_ms=t/1e6) for (j,t) in enumerate(trial.times)])
    model,result=simulate(family="benchmark",u0=[N-N÷100,N÷100,0])
    save_table("benchmark-model-N$(N)",DataFrame([result]))
end
summary=save_table("benchmark-summary",DataFrame(rows))
save_table("benchmark-samples",DataFrame(samples))
display(summary)

fig=bar(string.(summary.N),summary.median_ms;label=false,xlabel="N",
    ylabel="Median sir_run (ms)",title="10 fresh samples, T=40",size=(900,550))
savefig(fig,figure_path("06-plot"))
display(fig)

scaling=summary.median_ms[2]/summary.median_ms[1]
display((population_ratio=10,time_ratio=scaling))
