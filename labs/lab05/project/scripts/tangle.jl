using DrWatson
@quickactivate "project"
using Literate

function generate_formats(source::AbstractString)
    name = splitext(basename(source))[1]
    foreach(mkpath, (scriptsdir(name), projectdir("markdown", name),
        projectdir("notebooks", name)))
    Literate.script(source, scriptsdir(name); name, credit=false)
    Literate.notebook(source, projectdir("notebooks", name); name,
        execute=false, credit=false)
    Literate.markdown(source, projectdir("markdown", name); name,
        flavor=Literate.QuartoFlavor(), credit=false)
    Literate.markdown(source, projectdir("markdown", name);
        name="$(name)-report", flavor=Literate.QuartoFlavor(), credit=false,
        postprocess=text -> replace(
            replace(text, "```{julia}" => "```julia"),
            r"^(#+) "m => s"##\1 "))
end

foreach(generate_formats, ARGS)
