using DrWatson
@quickactivate "project"
using Literate

function generate_formats(source::AbstractString)
    isfile(source) || error("Source file not found: $(source)")
    name = splitext(basename(source))[1]
    clean_dir = scriptsdir(name)
    quarto_dir = projectdir("markdown", name)
    notebook_dir = projectdir("notebooks", name)
    foreach(mkpath, (clean_dir, quarto_dir, notebook_dir))
    Literate.script(source, clean_dir; name=name, credit=false)
    Literate.notebook(source, notebook_dir; name=name, execute=false, credit=false)
    Literate.markdown(
        source,
        quarto_dir;
        name=name,
        flavor=Literate.QuartoFlavor(),
        credit=false,
    )
end

foreach(generate_formats, ARGS)
