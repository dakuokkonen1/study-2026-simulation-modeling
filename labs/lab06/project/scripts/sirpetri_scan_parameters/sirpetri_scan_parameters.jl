using DrWatson
@quickactivate "project"
include(srcdir("SIRPetri.jl"))
using .SIRPetri
include(srcdir("experiment_support.jl"))

β_range = 0.1:0.05:0.8
γ_fixed, tmax = 0.1, 100.0
df_scan = DataFrame(β=Float64[], peak_I=Float64[], final_R=Float64[])
df_refined = DataFrame(β=Float64[], peak_I=Float64[], peak_time=Float64[], analytic=Float64[])
for β in β_range
    net, u0, _ = build_sir_network(β, γ_fixed)
    df = simulate_deterministic(net, u0, (0.0, tmax); saveat=0.5, rates=[β, γ_fixed])
    push!(df_scan, (β, maximum(df.I), df.R[end]))
    peak = refined_peak(net, u0, (0.0, tmax); rates=[β, γ_fixed])
    push!(df_refined, (β, peak.peak, peak.time, peak.analytic))
end
save_table("sir_scan.csv", df_scan)
save_table("sir_scan_refined.csv", df_refined)
df_scan

p = plot(df_scan.β, [df_scan.peak_I df_scan.final_R];
    label=["Peak I, saveat=0.5" "Final R"], marker=:circle,
    xlabel="beta", ylabel="Population", title="Sensitivity to infection rate")
savefig(p, imagepath("05-plot.png"))
display(p)

p_peak = plot(df_refined.β, df_refined.peak_I; marker=:circle,
    label="Refined peak", xlabel="beta", ylabel="Peak I", title="Early epidemic peak")
savefig(p_peak, imagepath("06-plot.png"))
display(p_peak)
df_refined
