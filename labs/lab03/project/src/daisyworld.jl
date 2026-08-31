module DaisyworldModel

using Agents, Random, Statistics
using StatsBase: sample

export Daisy,
    daisyworld,
    daisy_step!,
    daisyworld_step!,
    measure,
    advance!,
    update_surface_temperature!,
    diffuse_temperature!,
    propagate!,
    solar_activity!

@agent struct Daisy(GridAgent{2})
    breed::Symbol
    age::Int
    albedo::Float64
end

function update_surface_temperature!(pos, model)
    albedo =
        isempty(pos, model) ? model.surface_albedo :
        model[id_in_position(pos, model)].albedo
    absorbed = (1 - albedo) * model.solar_luminosity
    heating = absorbed > 0 ? 72 * log(absorbed) + 80 : 80.0
    model.temperature[pos...] =
        (model.temperature[pos...] + heating) / 2
end

function diffuse_temperature!(pos, model)
    neighbors = nearby_positions(pos, model)
    model.temperature[pos...] =
        (1 - model.ratio) * model.temperature[pos...] +
        model.ratio * sum(model.temperature[p...] for p in neighbors) /
        8
end

function propagate!(pos, model)
    isempty(pos, model) && return
    parent = model[id_in_position(pos, model)]
    temperature = model.temperature[pos...]
    probability = clamp(
        0.1457 * temperature - 0.0032 * temperature^2 - 0.6443,
        0,
        1,
    )
    if rand(abmrng(model)) < probability
        target = random_nearby_position(
            pos,
            model,
            1,
            p -> isempty(p, model),
        )
        isnothing(target) ||
            add_agent!(target, model, parent.breed, 0, parent.albedo)
    end
    nothing
end

function daisy_step!(agent, model)
    agent.age += 1
    agent.age >= model.max_age && remove_agent!(agent, model)
    nothing
end

function solar_activity!(model)
    if model.scenario == :ramp
        200 < model.tick <= 400 &&
            (model.solar_luminosity += model.solar_change)
        500 < model.tick <= 750 &&
            (model.solar_luminosity -= model.solar_change / 2)
    elseif model.scenario == :change
        model.solar_luminosity += model.solar_change
    end
    nothing
end

function daisyworld_step!(model)
    for pos in positions(model)
        update_surface_temperature!(pos, model)
        diffuse_temperature!(pos, model)
        propagate!(pos, model)
    end
    model.tick += 1
    solar_activity!(model)
end

function daisyworld(;
    griddims = (30, 30),
    max_age = 25,
    init_white = 0.2,
    init_black = 0.2,
    albedo_white = 0.75,
    albedo_black = 0.25,
    surface_albedo = 0.4,
    solar_change = 0.005,
    solar_luminosity = 1.0,
    scenario = :default,
    seed = 165,
)
    all(>=(3), griddims) ||
        throw(ArgumentError("grid dimensions must be at least 3"))
    max_age > 0 || throw(ArgumentError("max_age must be positive"))
    0 <= init_white <= 1 &&
    0 <= init_black <= 1 &&
    init_white + init_black <= 1 || throw(
        ArgumentError("initial fractions must sum to at most one"),
    )
    all(
        x -> 0 <= x <= 1,
        (albedo_white, albedo_black, surface_albedo),
    ) || throw(ArgumentError("albedo outside [0,1]"))
    scenario in (:default, :ramp, :change) ||
        throw(ArgumentError("unknown scenario"))
    properties = Dict{Symbol,Any}(
        :max_age=>max_age,
        :surface_albedo=>surface_albedo,
        :solar_luminosity=>solar_luminosity,
        :solar_change=>solar_change,
        :scenario=>scenario,
        :tick=>0,
        :ratio=>0.5,
        :temperature=>zeros(griddims),
    )
    model = StandardABM(
        Daisy,
        GridSpaceSingle(griddims; periodic = true);
        properties,
        rng = MersenneTwister(seed),
        agent_step! = daisy_step!,
        model_step! = daisyworld_step!,
        scheduler = Schedulers.fastest,
    )
    cells = collect(positions(model))
    white_cells = sample(
        abmrng(model),
        cells,
        floor(Int, init_white * length(cells));
        replace = false,
    )
    for pos in white_cells
        add_agent!(
            pos,
            model,
            :white,
            rand(abmrng(model), 0:max_age),
            albedo_white,
        )
    end
    black_cells = sample(
        abmrng(model),
        setdiff(cells, white_cells),
        floor(Int, init_black * length(cells));
        replace = false,
    )
    for pos in black_cells
        add_agent!(
            pos,
            model,
            :black,
            rand(abmrng(model), 0:max_age),
            albedo_black,
        )
    end
    for pos in positions(model)
        update_surface_temperature!(pos, model)
    end
    model
end

advance!(model, n = 1) = Agents.step!(model, n)

function measure(model)
    black = count(a -> a.breed == :black, allagents(model))
    white = count(a -> a.breed == :white, allagents(model))
    albedo = mean(
        isempty(p, model) ? model.surface_albedo :
        model[id_in_position(p, model)].albedo for
        p in positions(model)
    )
    (;
        time = model.tick,
        black,
        white,
        temperature = mean(model.temperature),
        luminosity = model.solar_luminosity,
        albedo,
    )
end

end
