# # Агентная SIR: базовый опыт
#
# Три города по 1000 человек, исходный заражённый в третьем городе, seed 42, 100 дней.
#
# ## Рабочее окружение
using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

# ## Выполнение и сохранение JLD2 / CSV
result = basic_experiment()
# ## S, I, R и число живых
savefig(result.fig, imagefile("01-plot.png"))
display(result.fig)
result.df[1:10:end, :]
