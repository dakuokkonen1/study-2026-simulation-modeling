using Pkg
Pkg.instantiate()
Pkg.precompile()

using IJulia
IJulia.installkernel("Julia", "--project=$(dirname(Base.active_project()))";
    env=Dict("JULIA_DEPOT_PATH"=>join(DEPOT_PATH, ':')))
