# # Агентная SIR: миграция
#
# Шесть интенсивностей, три seed, 150 дней; инфекция начинается в первом городе.
#
# ## Рабочее окружение
using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

# ## Серия из 18 прогонов
result = migration_scan()
# ## Время и доля инфицированных в пике
savefig(result.fig, imagefile("03-plot.png"))
display(result.fig)
result.grouped
