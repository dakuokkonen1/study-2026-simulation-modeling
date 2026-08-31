# # Агентная SIR: многокритериальная оптимизация
#
# Borg MOEA минимизирует средний пик и смертность; каждая оценка содержит пять прогонов.
#
# ## Рабочее окружение
using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

# ## Поиск с бюджетом методички 120 секунд
result = optimize_sir()
# ## Исследованные точки и недоминируемые решения
savefig(result.fig, imagefile("04-plot.png"))
display(result.fig)
result.pareto
