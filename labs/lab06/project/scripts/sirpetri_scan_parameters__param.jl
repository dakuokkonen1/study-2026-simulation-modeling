# # Двухпараметрическое исследование
# §6.2: исходные 15 значений β повторяются при γ=.05, .1, .2; всего 45 ОДУ.
using DrWatson
@quickactivate "project"
include(srcdir("SIRPetri.jl"))
using .SIRPetri
include(srcdir("experiment_support.jl"))

# ## Расчёты и отдельное уточнение пика
rows = NamedTuple[]
for γ in [0.05, 0.1, 0.2], β in 0.1:0.05:0.8
    net, u0, _ = build_sir_network(β, γ)
    df = simulate_deterministic(net, u0, (0.0, 100.0); saveat=0.5, rates=[β, γ])
    peak = refined_peak(net, u0, (0.0, 100.0); rates=[β, γ])
    push!(rows, (β=β, γ=γ, peak_I=maximum(df.I), final_R=df.R[end],
        refined_peak=peak.peak, peak_time=peak.time))
end
df_scan_param = DataFrame(rows)
save_table("sir_scan_param.csv", df_scan_param)
first(df_scan_param, 15)

# ## Две панели: дискретный и уточнённый пик
p_grid = plot(; xlabel="beta", ylabel="Peak I, saveat=0.5", title="Fixed observation grid")
p_refined = plot(; xlabel="beta", ylabel="Refined peak I", title="Continuous-time peak")
for γ in [0.05, 0.1, 0.2]
    d = df_scan_param[df_scan_param.γ .== γ, :]
    plot!(p_grid, d.β, d.peak_I; marker=:circle, label="gamma=$(γ)")
    plot!(p_refined, d.β, d.refined_peak; marker=:circle, label="gamma=$(γ)")
end
p = plot(p_grid, p_refined; layout=(1,2), size=(1200,540))
savefig(p, imagepath("11-plot.png"))
display(p)
