using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.instantiate()
using IJulia
IJulia.installkernel("Julia lab04 1.11", "--project=$(abspath(joinpath(@__DIR__, "..")))";
    specname="julia-lab04-1.11")
