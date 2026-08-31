using Pkg
Pkg.instantiate()
using IJulia
IJulia.installkernel("Julia lab06", "--project=$(dirname(@__DIR__))")
Pkg.status()
