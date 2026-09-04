using Pkg
Pkg.instantiate()
using IJulia
IJulia.installkernel("Julia lab08","--project=$(dirname(@__DIR__))")
Pkg.status()
