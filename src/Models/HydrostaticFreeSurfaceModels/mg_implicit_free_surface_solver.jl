using Oceananigans.Solvers
using Oceananigans.Operators
using Oceananigans.ImmersedBoundaries: ImmersedBoundaryGrid, GridFittedBottom
using Oceananigans.Architectures
using Oceananigans.Grids: with_halo, isrectilinear
using Oceananigans.Fields: Field, ZReducedField
using Oceananigans.Architectures: device, unsafe_free!
using Oceananigans.Models.HydrostaticFreeSurfaceModels: Az_∇h²ᶜᶜᶜ
using Oceananigans.Solvers: fill_matrix_elements!
using Oceananigans.Solvers: constructors, arch_sparse_matrix, ensure_diagonal_elements_are_present!, update_diag!

import Oceananigans.Solvers: solve!, precondition!
import Oceananigans.Architectures: architecture

"""
    struct MGImplicitFreeSurfaceSolver{V, S, R}

The multigrid implicit free-surface solver.

$(TYPEDFIELDS)
"""
mutable struct MGImplicitFreeSurfaceSolver{S, V, F, R, C, D}
    "The multigrid solver"
    multigrid_solver :: S
    "The vertically-integrated lateral areas"
    vertically_integrated_lateral_areas :: V
    "The previous time step"
    previous_Δt :: F
    "The right hand side of the free surface evolution equation"
    right_hand_side :: R
    "The matrix constructors of the linear operator without the Az / (g * Δt^2) term"
    matrix_constructors :: C
    "The Az / g term"
    diagonal :: D
end

architecture(solver::MGImplicitFreeSurfaceSolver) =
    architecture(solver.multigrid_solver)

"""
    MGImplicitFreeSurfaceSolver(grid, settings)

Return a solver based on a multigrid method for the elliptic equation
    
```math
[∇ ⋅ H ∇ - 1 / (g Δt²)] ηⁿ⁺¹ = (∇ʰ ⋅ Q★ - ηⁿ / Δt) / (g Δt)
```

representing an implicit time discretization of the linear free surface evolution equation
for a fluid with variable depth `H`, horizontal areas `Az`, barotropic volume flux `Q★`, time
step `Δt`, gravitational acceleration `g`, and free surface at the `n`-th time-step `ηⁿ`.
"""
function MGImplicitFreeSurfaceSolver(grid::AbstractGrid, 
                                    settings, 
                                    gravitational_acceleration=nothing, 
                                    placeholder_timestep = -1.0)
    arch = architecture(grid)

    # Initialize vertically integrated lateral face areas
    ∫ᶻ_Axᶠᶜᶜ = Field{Face, Center, Nothing}(with_halo((3, 3, 1), grid))
    ∫ᶻ_Ayᶜᶠᶜ = Field{Center, Face, Nothing}(with_halo((3, 3, 1), grid))

    vertically_integrated_lateral_areas = (xᶠᶜᶜ = ∫ᶻ_Axᶠᶜᶜ, yᶜᶠᶜ = ∫ᶻ_Ayᶜᶠᶜ)

    compute_vertically_integrated_lateral_areas!(vertically_integrated_lateral_areas)
    fill_halo_regions!(vertically_integrated_lateral_areas)
    
    # Set some defaults
    settings = Dict{Symbol, Any}(settings)
    settings[:maxiter] = get(settings, :maxiter, grid.Nx * grid.Ny)
    settings[:reltol] = get(settings, :reltol, min(1e-7, 10 * sqrt(eps(eltype(grid)))))

    right_hand_side = Field{Center, Center, Nothing}(grid)

    # initialize solver with Δt = nothing so that linear matrix is not computed; see `initialize_matrix` methods
    solver = MultigridSolver(Az_∇h²ᶜᶜᶜ_linear_operation!, ∫ᶻ_Axᶠᶜᶜ, ∫ᶻ_Ayᶜᶠᶜ;
                             template_field = right_hand_side, settings...)

    # For updating the diagonal
    ensure_diagonal_elements_are_present!(solver.matrix)
    matrix_constructors = constructors(arch, solver.matrix)
    diagonal = compute_diag(arch, grid, gravitational_acceleration)

    return MGImplicitFreeSurfaceSolver(solver, vertically_integrated_lateral_areas, placeholder_timestep, right_hand_side, matrix_constructors, diagonal)
end


# Construct a Nx*Ny array with elements Az/g
function compute_diag(arch, grid, g)
    diag = arch_array(arch, zeros(eltype(grid), grid.Nx, grid.Ny, 1))

    event_c = launch!(arch, grid, :xy, _compute_diag!, diag, grid, g,
                      dependencies = device_event(arch))
    wait(event_c)
    return diag
end

@kernel function _compute_diag!(diag, grid, g)
    i, j = @index(Global, NTuple)
    @inbounds diag[i, j, 1]  = - Azᶜᶜᶜ(i, j, 1, grid) / g
end

"""
Returns `L(ηⁿ)`, where `ηⁿ` is the free surface displacement at time step `n`
and `L` is the linear operator that arises
in an implicit time step for the free surface displacement `η` 
without the final term that is dependent on Δt

(See the docs section on implicit time stepping.)
"""
function Az_∇h²ᶜᶜᶜ_linear_operation!(L_ηⁿ⁺¹, ηⁿ⁺¹, ∫ᶻ_Axᶠᶜᶜ, ∫ᶻ_Ayᶜᶠᶜ)
    grid = L_ηⁿ⁺¹.grid
    arch = architecture(L_ηⁿ⁺¹)
    fill_halo_regions!(ηⁿ⁺¹)

    event = launch!(arch, grid, :xy, _Az_∇h²ᶜᶜᶜ_linear_operation!,
                    L_ηⁿ⁺¹, grid,  ηⁿ⁺¹, ∫ᶻ_Axᶠᶜᶜ, ∫ᶻ_Ayᶜᶠᶜ,
                    dependencies = device_event(arch))

    wait(device(arch), event)

    return nothing
end

@kernel function _Az_∇h²ᶜᶜᶜ_linear_operation!(L_ηⁿ⁺¹, grid, ηⁿ⁺¹, ∫ᶻ_Axᶠᶜᶜ, ∫ᶻ_Ayᶜᶠᶜ)
    i, j = @index(Global, NTuple)
    @inbounds L_ηⁿ⁺¹[i, j, 1] = Az_∇h²ᶜᶜᶜ(i, j, 1, grid, ∫ᶻ_Axᶠᶜᶜ, ∫ᶻ_Ayᶜᶠᶜ, ηⁿ⁺¹)
end

build_implicit_step_solver(::Val{:Multigrid}, grid, settings, gravitational_acceleration) =
    MGImplicitFreeSurfaceSolver(grid, settings, gravitational_acceleration)

#####
##### Solve...
#####

function solve!(η, implicit_free_surface_solver::MGImplicitFreeSurfaceSolver, rhs, g, Δt)
    solver = implicit_free_surface_solver.multigrid_solver

    # if `Δt` changed then re-compute the matrix elements
    if Δt != implicit_free_surface_solver.previous_Δt
        arch = architecture(solver.matrix)
        constructors = deepcopy(implicit_free_surface_solver.matrix_constructors)
        M = prod(size(η))
        update_diag!(constructors, arch, M, M, implicit_free_surface_solver.diagonal, Δt, 0)
        solver.matrix = arch_sparse_matrix(arch, constructors) 

        unsafe_free!(constructors)

        implicit_free_surface_solver.previous_Δt = Δt
    end
    solve!(η, solver, rhs)

    return nothing
end


function compute_implicit_free_surface_right_hand_side!(rhs, implicit_solver::MGImplicitFreeSurfaceSolver,
                                                        g, Δt, ∫ᶻQ, η)
    solver = implicit_solver.multigrid_solver
    arch = architecture(solver)
    grid = solver.grid

    event = launch!(arch, grid, :xy,
                    implicit_free_surface_right_hand_side!,
                    rhs, grid, g, Δt, ∫ᶻQ, η,
                    dependencies = device_event(arch))
    
    wait(device(arch), event)
    return nothing
end
