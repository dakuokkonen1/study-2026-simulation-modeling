using DrWatson
@quickactivate "project"
using Literate

execute_notebooks = "--execute" in ARGS
sources = filter(!=("--execute"), ARGS)
for source in sources
    name = splitext(basename(source))[1]
    Literate.script(source, scriptsdir(name); name, credit = false)
    Literate.notebook(
        source,
        projectdir("notebooks", name);
        name,
        execute = execute_notebooks,
        credit = false,
    )
    Literate.markdown(
        source,
        projectdir("markdown", name);
        name,
        flavor = Literate.QuartoFlavor(),
        credit = false,
    )
    # A static derivative is included in the report without repeating calculations.
    Literate.markdown(
        source,
        projectdir("markdown", name);
        name = name*"-report",
        flavor = Literate.QuartoFlavor(),
        credit = false,
        postprocess = text -> replace(
            replace(text, "```{julia}"=>"```julia"),
            r"^(#{1,4}) "m => heading -> "##"*heading,
        ),
    )
end
