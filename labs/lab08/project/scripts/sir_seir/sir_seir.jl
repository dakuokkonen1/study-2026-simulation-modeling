using DrWatson
@quickactivate "project"
using project.SIRDES
using CSV, DataFrames, Statistics, StatsPlots
include(srcdir("experiments.jl"))
using .Experiments

rows=NamedTuple[]
fig=plot(;xlabel="Time",ylabel="I",title="Latent period: seed=6001",size=(1000,550))
for sigma in [Inf,.25,.5,1.0], rep in 1:10
    model,result=simulate(family="seir",sigma=sigma,seed=6000+rep)
    push!(rows,result)
    if rep==1
        plot!(fig,model.ta,model.Ia;label=isinf(sigma) ? "SIR" : "SEIR sigma=$(sigma)",lw=2)
        if sigma==.5
            states=plot_states(out(model);title="SEIR sigma=0.5",exposed=true)
            savefig(states,figure_path("13-plot"))
        end
    end
end
runs=save_table("seir-runs",DataFrame(rows));

summary=save_table("seir-summary",summarize(runs,[:sigma]))
display(summary)
savefig(fig,figure_path("12-plot"))
display(fig)

selected=filter(r->r.sigma==.5 && r.seed==6001,runs)
trajectory=CSV.read(projectdir(selected.csv[1]),DataFrame)
@assert all(trajectory.S+trajectory.E+trajectory.I+trajectory.R .== 1000)
display(plot_states(trajectory;title="SEIR sigma=0.5",exposed=true))
