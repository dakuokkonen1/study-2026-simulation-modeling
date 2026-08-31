using DrWatson
@quickactivate "project"
using Literate

function generate_formats(source)
    name = splitext(basename(source))[1]
    dest = projectdir("markdown", name)
    Literate.script(source, scriptsdir(name); name, credit=false)
    Literate.notebook(source, projectdir("notebooks", name); name,
        execute=false, credit=false, postprocess=nb -> begin
            nb["metadata"]["kernelspec"] = Dict("language"=>"julia",
                "name"=>"julia-lab06-1.11", "display_name"=>"Julia lab06 1.11")
            nb
        end)
    Literate.markdown(source, dest; name, flavor=Literate.QuartoFlavor(), credit=false)
    Literate.markdown(source, dest; name="$(name)-report",
        flavor=Literate.QuartoFlavor(), credit=false,
        postprocess=text -> replace(replace(text, "```{julia}"=>"```julia"),
            r"^(#+) "m => s"##\1 "))
end

sources = isempty(ARGS) ? sort(filter(f -> startswith(basename(f), "sirpetri_") &&
    endswith(f, ".jl"), readdir(scriptsdir(); join=true))) : ARGS
foreach(generate_formats, sources)
