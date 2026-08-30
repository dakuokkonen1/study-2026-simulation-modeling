using Pkg

project = abspath(joinpath(@__DIR__, ".."))
Pkg.activate(project)
Pkg.instantiate()

using IJulia
IJulia.installkernel("Julia lab05 1.11", "--project=$project";
    specname="julia-lab05-1.11")
