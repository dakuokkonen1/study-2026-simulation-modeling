using Agents, CSV, DataFrames, DrWatson, Statistics, CairoMakie
include(joinpath(@__DIR__, "daisyworld.jl"))
using .DaisyworldModel

imagefile(name) =
    (mkpath(projectdir("..", "image")); projectdir("..", "image", name))
datafile(name, file) = (mkpath(datadir(name)); datadir(name, file))
set_theme!(Theme(font = "DejaVu Sans", fontsize = 16))

function snapshot(model; title = "Daisyworld")
    fig = Figure(size = (850, 700))
    ax = Axis(
        fig[1, 1],
        title = "$title · t=$(model.tick)",
        xlabel = "x",
        ylabel = "y",
        aspect = 1,
    )
    hm = heatmap!(
        ax,
        model.temperature;
        colormap = :thermal,
        colorrange = (-20, 60),
    )
    for (breed, color) in ((:white, :white), (:black, :black))
        plants = [a.pos for a in allagents(model) if a.breed == breed]
        isempty(plants) || scatter!(
            ax,
            [p[1] for p in plants],
            [p[2] for p in plants];
            color,
            marker = :circle,
            markersize = 8,
            strokewidth = 0.4,
            strokecolor = :gray,
        )
    end
    Colorbar(fig[1, 2], hm; label = "Температура, °C")
    fig
end

function history(model, steps = 1000)
    rows = [measure(model)]
    for _ in 1:steps
        advance!(model)
        push!(rows, measure(model))
    end
    DataFrame(rows)
end

function countfigure(df; title = "Численность маргариток")
    fig = Figure(size = (1000, 550))
    ax = Axis(
        fig[1, 1],
        title = title,
        xlabel = "Модельный шаг",
        ylabel = "Число растений",
    )
    lines!(ax, df.time, df.black; color = :black, label = "Чёрные")
    lines!(ax, df.time, df.white; color = :orange, label = "Белые")
    axislegend(ax; position = :rt)
    fig
end

function dynamicsfigure(df; title = "Daisyworld: обратная связь")
    fig = Figure(size = (1000, 1000))
    axes = [
        Axis(fig[i, 1], ylabel = label) for
        (i, label) in enumerate((
            "Число растений",
            "Температура, °C",
            "Светимость",
            "Среднее альбедо",
        ))
    ]
    axes[1].title = title
    lines!(axes[1], df.time, df.black; color = :black, label = "Чёрные")
    lines!(axes[1], df.time, df.white; color = :orange, label = "Белые")
    axislegend(axes[1]; position = :rt)
    for (ax, column) in
        zip(axes[2:4], (:temperature, :luminosity, :albedo))
        lines!(ax, df.time, df[!, column]; color = :royalblue)
    end
    axes[4].xlabel = "Модельный шаг"
    linkxaxes!(axes...)
    fig
end

parameter_sets() = dict_list(
    Dict(
        :max_age=>[25, 40],
        :init_white=>[0.2, 0.8],
        :init_black=>0.2,
        :seed=>165,
    ),
)

function savehistory(df, name)
    CSV.write(datafile(name, "trajectory.csv"), df)
    show(last(df, 5); allcols = true)
    println()
    df
end
