# # M/M/c: интенсивность потока и число каналов
# Параметрическое дополнение §7.4. Аналитические показатели применимы при ρ<1.
using DrWatson
@quickactivate "project"
include(srcdir("MMCQueue.jl"))
using .MMCQueue
include(srcdir("experiment_support.jl"))

# ## План эксперимента
# Каждый опыт содержит 20000 заявок. Первые 2000 исключаются из клиентских
# оценок; интегралы состояния считаются до последнего прибытия, без фазы слива.
arrival_rates = [.3, .6, .9]
capacities = [1, 2, 3, 4]
num_customers, warmup, μ = 20_000, 2_000, .5
summaries, sampled = NamedTuple[], DataFrame[]

# ## Выполнение двенадцати сочетаний
# Сохраняются все времена клиентов; для обзорных траекторий — 1001 отсчёт
# фактического кусочно-постоянного состояния каждого календаря событий.
for (index, (λ,c)) in enumerate(Iterators.product(arrival_rates,capacities))
    seed = 7000+index
    result = simulate_mmc(; num_customers, num_servers=c, λ, μ, seed)
    observed, theory = queue_summary(result; warmup), erlang_c(λ,μ,c)
    push!(summaries, merge((experiment=index, seed=seed), observed,
        (rho=theory.rho, stable=theory.stable, theory_Wq=theory.Wq,
            theory_W=theory.W, theory_Lq=theory.Lq, theory_L=theory.L,
            theory_p_wait=theory.p_wait)))
    clients = insertcols!(result.customers, 1, :experiment=>index, :λ=>λ, :c=>c)
    CSV.write(datadir("mmc_param_customers.csv"), clients; append=index>1, writeheader=index==1)
    trace = sampled_queue(result.events, last(result.customers.arrival))
    insertcols!(trace, 1, :experiment=>index, :λ=>λ, :c=>c)
    push!(sampled, trace)
end
summary = DataFrame(summaries)
traces = vcat(sampled...)
save_table("mmc_param_summary.csv", summary)
save_table("mmc_param_states.csv", traces)
select(summary, :λ,:c,:rho,:stable,:Wq,:theory_Wq,:utilization,:p_wait,:theory_p_wait)

# ## Среднее ожидание: имитация и формула Эрланга C
p_wait = plot(; xlabel="Servers c", ylabel="Mean waiting time", title="Stationary cases: simulation and Erlang C")
for (index, λ) in enumerate(arrival_rates)
    rows = filter(row->row.λ==λ && row.stable, summary)
    color=[:royalblue,:seagreen,:darkorange][index]
    plot!(p_wait, rows.c, rows.Wq; marker=:circle, color, label="DES, lambda=$λ")
    plot!(p_wait, rows.c, rows.theory_Wq; linestyle=:dash, color, label="Theory, lambda=$λ")
end
savefig(p_wait, imagepath("03-plot.png"))
display(p_wait)

# ## Загрузка и проверка стационарных балансов
stable = filter(:stable=>identity, summary)
p_busy = scatter(stable.rho, stable.utilization; xlabel="Theoretical utilization rho",
    ylabel="Observed utilization", label="DES", color=:royalblue,
    title="Time-weighted server utilization")
plot!(p_busy, [0,1], [0,1]; color=:firebrick, linestyle=:dash, label="y = x")
savefig(p_busy, imagepath("04-plot.png"))
display(p_busy)
select(stable, :λ,:c,:Lq,:theory_Lq,:little_Lq_residual,:little_L_residual)

# ## Неустойчивые очереди
# При λ≥cμ длинный конечный прогон всё ещё завершается после обслуживания всех
# клиентов, но стационарного Wq нет. Пустые теоретические значения не заменяются нулями.
p_unstable = plot(; xlabel="Time", ylabel="Customers waiting", title="One server: overload grows the queue")
for λ in [.6,.9]
    rows = filter(row->row.λ==λ && row.c==1, traces)
    plot!(p_unstable, rows.time, rows.queue; label="lambda=$λ, c=1", seriestype=:steppost)
end
savefig(p_unstable, imagepath("05-plot.png"))
display(p_unstable)
filter(:stable=>!, summary)
