using DrWatson
@quickactivate "project"
using project.SIRDES
using CSV, DataFrames, Statistics, StatsPlots
include(srcdir("experiments.jl"))
using .Experiments

rows=NamedTuple[]
fig=plot(;xlabel="Time",ylabel="I",title="Vaccination at day 0, seed=5001",size=(1000,550))
for time in [0.0,10.0], fraction in [0.0,.25,.5,.6,.75], rep in 1:10
    model,result=simulate(family="vaccination",seed=5000+rep,
        vaccine_time=time,vaccine_fraction=fraction)
    push!(rows,result)
    time==0 && rep==1 && plot!(fig,model.ta,model.Ia;label="fraction=$(fraction)",lw=2)
end
runs=save_table("vaccination-runs",DataFrame(rows));

summary=save_table("vaccination-summary",summarize(runs,[:vaccine_time,:vaccine_fraction]))
display(select(summary,:vaccine_time,:vaccine_fraction,:peak_mean,:infected_mean,:I_T_mean))
savefig(fig,figure_path("10-plot"))
display(fig)

fig2=plot(;xlabel="Fraction of S vaccinated",ylabel="Mean ever infected by T=40",size=(950,550))
for time in [0.0,10.0]
    part=sort(filter(r->r.vaccine_time==time,summary),:vaccine_fraction)
    plot!(fig2,part.vaccine_fraction,part.infected_mean;marker=:circle,label="day $(time)",lw=2)
end
savefig(fig2,figure_path("11-plot"))
display(fig2)

critical_fraction=1-BASE_P[3]*(sum(BASE_U)-1)/(BASE_P[1]*BASE_P[2]*BASE_U[1])
display((critical_fraction=critical_fraction,))
