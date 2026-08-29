using DrWatson
@quickactivate "project"
using Literate

function generate_formats(source::AbstractString)
    name = splitext(basename(source))[1]
    foreach(mkpath, (scriptsdir(name), projectdir("markdown", name), projectdir("notebooks", name)))
    Literate.script(source, scriptsdir(name); name=name, credit=false)
    Literate.notebook(source, projectdir("notebooks", name); name=name, execute=false, credit=false)
    Literate.markdown(source, projectdir("markdown", name); name=name,
        flavor=Literate.QuartoFlavor(), credit=false)
end

foreach(generate_formats, ARGS)
