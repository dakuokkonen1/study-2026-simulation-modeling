using DrWatson
@quickactivate "project"
include(srcdir("SIRPetri.jl"))
using .SIRPetri
include(srcdir("experiment_support.jl"))

df_det = CSV.read(datadir("sir_det.csv"), DataFrame)
df_stoch = CSV.read(datadir("sir_stoch.csv"), DataFrame)
df_scan = CSV.read(datadir("sir_scan.csv"), DataFrame)
(nrow(df_det), nrow(df_stoch), nrow(df_scan))

p_comparison = plot(df_det.time, df_det.I; label="ODE", xlabel="Time",
    ylabel="Infected", title="ODE and SSA: original time grids")
plot!(p_comparison, df_stoch.time, df_stoch.I; label="SSA", seriestype=:steppost)
savefig(p_comparison, imagepath("08-plot.png"))
display(p_comparison)

aligned = state_at(df_stoch, df_det.time)
difference = DataFrame(time=df_det.time, ODE_I=df_det.I, SSA_I=aligned.I,
    difference=aligned.I .- df_det.I)
save_table("sir_comparison.csv", difference)
metrics = DataFrame(rmse_I=[sqrt(mean(difference.difference.^2))],
    max_abs_I=[maximum(abs.(difference.difference))])
save_table("sir_comparison_summary.csv", metrics)
metrics

p_sensitivity = plot(df_scan.β, df_scan.peak_I; marker=:circle, label=false,
    xlabel="beta", ylabel="Peak I on 0.5 grid", title="Sensitivity from saved CSV")
savefig(p_sensitivity, imagepath("09-plot.png"))
display(p_sensitivity)
