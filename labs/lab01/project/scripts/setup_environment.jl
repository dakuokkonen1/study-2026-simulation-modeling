using Pkg

Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.instantiate()
Pkg.precompile()

using IJulia

project_path = dirname(Base.active_project())
IJulia.installkernel("Julia lab01", "--project=$(project_path)")

println("Environment is ready")
println("Julia: ", VERSION)
println("Project: ", project_path)
