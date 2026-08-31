using DrWatson, CSV, DataFrames, Plots, Statistics, Random

const IMAGE_DIR = normpath(projectdir("..", "image"))
mkpath(IMAGE_DIR)
mkpath(datadir())
default(size=(1100, 650), dpi=120, fontfamily="DejaVu Sans", titlefontsize=14,
    guidefontsize=12, tickfontsize=10, legendfontsize=10,
    linewidth=2, margin=6Plots.mm, legend=:right)
imagepath(name) = joinpath(IMAGE_DIR, name)

function save_table(name, df)
    path = datadir(name)
    mkpath(dirname(path))
    CSV.write(path, df)
end

function epidemic_summary(df)
    k = argmax(df.I)
    (peak_I=df.I[k], peak_time=df.time[k], final_R=df.R[end],
        conservation_error=maximum(abs.(df.S .+ df.I .+ df.R .- 1000)))
end

"""Все 501 отсчёт представлены отдельными кадрами; временные PNG удаляются."""
function animate_sir(df, filename; fps=25, title="SIR")
    anim = Animation()
    for row in eachrow(df)
        p = bar(["S", "I", "R"], [row.S, row.I, row.R];
            color=[:royalblue, :firebrick, :seagreen], legend=false,
            ylim=(0, 1050), ylabel="Population", size=(800, 500),
            title="$(title), t = $(round(row.time; digits=1))")
        frame(anim, p)
    end
    result = gif(anim, imagepath(filename); fps)
    rm(anim.dir; recursive=true)
    result
end
