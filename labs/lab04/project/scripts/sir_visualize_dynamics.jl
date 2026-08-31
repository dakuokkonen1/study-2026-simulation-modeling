# # Агентная SIR: анализ сохранённых данных
#
# Только читаем результат sir_scan_beta.jl, повторного моделирования нет.
#
# ## Рабочее окружение
using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

# ## Чтение CSV и усреднение
result = comprehensive_analysis()
CSV.write(
    datafile("sir_visualize_dynamics", "summary.csv"),
    result.grouped,
)
# ## Три панели сводного анализа
savefig(result.fig, imagefile("05-plot.png"))
display(result.fig)
result.grouped
