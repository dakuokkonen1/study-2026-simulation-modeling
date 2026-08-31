# # Агентная SIR: сканирование β
#
# Десять значений β и три seed, всего 30 независимых прогонов по 100 дней.
#
# ## Рабочее окружение
using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

# ## Численные эксперименты
result = beta_scan()
# ## Средние показатели по повторам
savefig(result.fig, imagefile("02-plot.png"))
display(result.fig)
result.grouped
