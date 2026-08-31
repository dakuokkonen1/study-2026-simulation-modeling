# # Агентная SIR: β и время выявления
#
# Сравним обнаружение на 3-й и 7-й день: по 30 прогонов на вариант.
#
# ## Рабочее окружение
using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

# ## Параметрическое расширение сканирования
rows = DataFrame[]
for detection in (3, 7)
    result = beta_scan(
        "sir_scan_beta__param/detection_$(detection)";
        detection_time = detection,
    )
    result.grouped[!, :detection] =
        fill(detection, nrow(result.grouped))
    push!(rows, result.grouped)
end
# ## Сопоставление средних пиков
summary = reduce(vcat, rows)
CSV.write(datafile("sir_scan_beta__param", "summary.csv"), summary)
figure = plot(; xlabel = "β", ylabel = "Средний пик I / живые")
for detection in (3, 7)
    subset = summary[summary.detection .== detection, :]
    plot!(
        figure,
        subset.beta,
        subset.peak;
        label = "Выявление: $(detection) дней",
        marker = :circle,
    )
end
savefig(figure, imagefile("07-plot.png"))
display(figure)
summary
