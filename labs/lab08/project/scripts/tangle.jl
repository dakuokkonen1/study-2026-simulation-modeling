using DrWatson
@quickactivate "project"
using Literate

function generate_formats(source)
    name=splitext(basename(source))[1]
    dest=projectdir("markdown",name)
    Literate.script(source,scriptsdir(name);name,credit=false)
    Literate.notebook(source,projectdir("notebooks",name);name,execute=false,credit=false,
        postprocess=nb->begin
            nb["metadata"]["kernelspec"]=Dict("language"=>"julia",
                "name"=>"julia-lab08-1.11","display_name"=>"Julia lab08 1.11")
            nb
        end)
    Literate.markdown(source,dest;name,flavor=Literate.QuartoFlavor(),credit=false)
    Literate.markdown(source,dest;name="$(name)-report",flavor=Literate.QuartoFlavor(),
        credit=false,postprocess=text->replace(replace(text,"\x60\x60\x60{julia}"=>"\x60\x60\x60julia"),r"^(#+) "m=>s"##\1 "))
end
sources=isempty(ARGS) ? [scriptsdir(name*".jl") for name in
    ["sir_des","sir_des__param","sir_duration","sir_benchmark","sir_csv_report","sir_demography","sir_vaccination","sir_seir","sir_compare_ode"]] : ARGS
foreach(generate_formats,sources)
