# # Параметрическая серия и стохастические повторы
# Дополнение §6.2: девять сочетаний β/γ, по 20 независимых SSA-траекторий.
using DrWatson
@quickactivate "project"
include(srcdir("SIRPetri.jl"))
using .SIRPetri
include(srcdir("experiment_support.jl"))

# ## План: 3 × 3 сочетания и воспроизводимые seed
betas, gammas = [0.1, 0.3, 0.8], [0.05, 0.1, 0.2]
repeats = 20
rows = NamedTuple[]
det_rows = NamedTuple[]
for (case_id, (β, γ)) in enumerate(Iterators.product(betas, gammas))
    net, u0, _ = build_sir_network(β, γ)
    det = simulate_deterministic(net, u0, (0.0, 100.0); saveat=0.5, rates=[β, γ])
    peak = refined_peak(net, u0, (0.0, 100.0); rates=[β, γ])
    push!(det_rows, merge((case_id=case_id, β=β, γ=γ, refined_peak=peak.peak), epidemic_summary(det)))
    save_table("parameters/det_$(case_id).csv", det)
    for repetition in 1:repeats
        seed = 123 + 100case_id + repetition
        stoch = simulate_stochastic(net, u0, (0.0, 100.0);
            rates=[β, γ], rng=Xoshiro(seed))
        push!(rows, merge((case_id=case_id, β=β, γ=γ, repetition=repetition, seed=seed),
            epidemic_summary(stoch)))
        repetition == 1 && save_table("parameters/ssa_$(case_id).csv", stoch)
    end
end
ensemble = DataFrame(rows)
deterministic = DataFrame(det_rows)
save_table("sir_param_replicates.csv", ensemble)
save_table("sir_param_deterministic.csv", deterministic)
first(ensemble, 10)

# ## Средние и стандартные отклонения, не доверительный интервал
summary = combine(groupby(ensemble, [:case_id, :β, :γ]),
    :peak_I => mean => :peak_mean, :peak_I => std => :peak_sd,
    :final_R => mean => :final_R_mean, :final_R => std => :final_R_sd,
    :peak_time => mean => :time_mean)
save_table("sir_param_summary.csv", summary)
summary

# ## Изменение стохастического пика при разных скоростях
p_ensemble = plot(; xlabel="beta", ylabel="Peak infected", title="SSA: mean and SD, 20 runs")
for γ in gammas
    d = sort(summary[summary.γ .== γ, :], :β)
    plot!(p_ensemble, d.β, d.peak_mean; yerror=d.peak_sd, marker=:circle, label="gamma=$(γ)")
end
savefig(p_ensemble, imagepath("10-plot.png"))
display(p_ensemble)
