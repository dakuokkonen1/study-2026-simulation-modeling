#!/usr/bin/env julia

using DrWatson
@quickactivate "project"
using Literate

function generate_formats(source::AbstractString)
    isfile(source) || error("Source file not found: $(source)")

    script_name = splitext(basename(source))[1]
    clean_dir = scriptsdir(script_name)
    quarto_dir = projectdir("markdown", script_name)
    notebook_dir = projectdir("notebooks", script_name)

    mkpath(clean_dir)
    mkpath(quarto_dir)
    mkpath(notebook_dir)

    println("Generating formats from $(source)")
    Literate.script(source, clean_dir; name=script_name, credit=false)
    println("  clean Julia: $(joinpath(clean_dir, script_name * ".jl"))")

    Literate.notebook(source, notebook_dir; name=script_name, execute=false, credit=false)
    println("  notebook:    $(joinpath(notebook_dir, script_name * ".ipynb"))")

    Literate.markdown(
        source,
        quarto_dir;
        name=script_name,
        flavor=Literate.QuartoFlavor(),
        credit=false,
    )
    println("  Quarto:      $(joinpath(quarto_dir, script_name * ".qmd"))")
end

isempty(ARGS) && error("Usage: julia --project=. scripts/tangle.jl <source.jl> [source.jl ...]")
foreach(generate_formats, ARGS)
