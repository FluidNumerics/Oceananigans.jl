using Oceananigans.Grids: XYZDirections, XYDirections, ZDirection
"""
    abstract type AbstractScalarDiffusivity <: AbstractTurbulenceClosure end

Abstract type for closures with *isotropic* diffusivities.
"""
abstract type AbstractScalarDiffusivity{TD, Iso} <: AbstractTurbulenceClosure{TD} end


"""
    viscosity(closure, diffusivities)

Returns the isotropic viscosity associated with `closure`.
"""
function viscosity end 


"""
    diffusivity(closure, diffusivities, tracer_indedx) where tracer_index

Returns the isotropic diffusivity associated with `closure` and tracer index `c_idx`.
"""
function diffusivity end 

@inline isotropy(::AbstractScalarDiffusivity{TD, Iso}) where {TD, Iso} = Iso()

#####
##### Stress divergences
#####

const AID = AbstractScalarDiffusivity{<:Any, <:XYZDirections}
const AHD = AbstractScalarDiffusivity{<:Any, <:XYDirections}
const AVD = AbstractScalarDiffusivity{<:Any, <:ZDirection}

@inline viscous_flux_ux(i, j, k, grid, closure::AID, clock, U, args...) = - 2 * ν_σᶜᶜᶜ(i, j, k, grid, clock, viscosity(closure, args...), Σ₁₁, U.u, U.v, U.w)
@inline viscous_flux_vx(i, j, k, grid, closure::AID, clock, U, args...) = - 2 * ν_σᶠᶠᶜ(i, j, k, grid, clock, viscosity(closure, args...), Σ₂₁, U.u, U.v, U.w)
@inline viscous_flux_wx(i, j, k, grid, closure::AID, clock, U, args...) = - 2 * ν_σᶠᶜᶠ(i, j, k, grid, clock, viscosity(closure, args...), Σ₃₁, U.u, U.v, U.w)
@inline viscous_flux_uy(i, j, k, grid, closure::AID, clock, U, args...) = - 2 * ν_σᶠᶠᶜ(i, j, k, grid, clock, viscosity(closure, args...), Σ₁₂, U.u, U.v, U.w)
@inline viscous_flux_vy(i, j, k, grid, closure::AID, clock, U, args...) = - 2 * ν_σᶜᶜᶜ(i, j, k, grid, clock, viscosity(closure, args...), Σ₂₂, U.u, U.v, U.w)
@inline viscous_flux_wy(i, j, k, grid, closure::AID, clock, U, args...) = - 2 * ν_σᶜᶠᶠ(i, j, k, grid, clock, viscosity(closure, args...), Σ₃₂, U.u, U.v, U.w)

@inline viscous_flux_ux(i, j, k, grid, closure::AHD, clock, U, args...) = - ν_δᶜᶜᶜ(i, j, k, grid, clock, closure.ν, U.u, U.v)   
@inline viscous_flux_vx(i, j, k, grid, closure::AHD, clock, U, args...) = - ν_ζᶠᶠᶜ(i, j, k, grid, clock, closure.ν, U.u, U.v)
@inline viscous_flux_uy(i, j, k, grid, closure::AHD, clock, U, args...) = + ν_ζᶠᶠᶜ(i, j, k, grid, clock, closure.ν, U.u, U.v)   
@inline viscous_flux_vy(i, j, k, grid, closure::AHD, clock, U, args...) = - ν_δᶜᶜᶜ(i, j, k, grid, clock, closure.ν, U.u, U.v)
# are we sure about this?? This might not be consistent for AHD
@inline viscous_flux_wx(i, j, k, grid, closure::AHD, clock, U, args...) = - ν_σᶠᶜᶠ(i, j, k, grid, clock, viscosity(closure, args...), ∂xᶠᶜᶠ, U.w)
@inline viscous_flux_wy(i, j, k, grid, closure::AHD, clock, U, args...) = - ν_σᶜᶠᶠ(i, j, k, grid, clock, viscosity(closure, args...), ∂yᶜᶠᶠ, U.w)

@inline viscous_flux_uz(i, j, k, grid, closure::AID, clock, U, args...) = - 2 * ν_σᶠᶜᶠ(i, j, k, grid, clock, viscosity(closure, args...), Σ₁₃, U.u, U.v, U.w)
@inline viscous_flux_vz(i, j, k, grid, closure::AID, clock, U, args...) = - 2 * ν_σᶜᶠᶠ(i, j, k, grid, clock, viscosity(closure, args...), Σ₂₃, U.u, U.v, U.w)
@inline viscous_flux_wz(i, j, k, grid, closure::AID, clock, U, args...) = - 2 * ν_σᶜᶜᶜ(i, j, k, grid, clock, viscosity(closure, args...), Σ₃₃, U.u, U.v, U.w)

@inline viscous_flux_uz(i, j, k, grid, closure::AVD, clock, U, args...) = - ν_σᶠᶜᶠ(i, j, k, grid, clock, viscosity(closure, args...), ∂zᶠᶜᶠ, U.u)
@inline viscous_flux_vz(i, j, k, grid, closure::AVD, clock, U, args...) = - ν_σᶜᶠᶠ(i, j, k, grid, clock, viscosity(closure, args...), ∂zᶜᶠᶠ, U.v)
@inline viscous_flux_wz(i, j, k, grid, closure::AVD, clock, U, args...) = - ν_σᶜᶜᶜ(i, j, k, grid, clock, viscosity(closure, args...), ∂zᶜᶜᶜ, U.w)

#####
##### Diffusive fluxes
#####

@inline diffusive_flux_x(i, j, k, grid, closure::Union{AID, AHD}, c, c_idx, clock, args...) = diffusive_flux_x(i, j, k, grid, clock, diffusivity(closure, c_idx, args...), c)
@inline diffusive_flux_y(i, j, k, grid, closure::Union{AID, AHD}, c, c_idx, clock, args...) = diffusive_flux_y(i, j, k, grid, clock, diffusivity(closure, c_idx, args...), c)
@inline diffusive_flux_z(i, j, k, grid, closure::Union{AID, AVD}, c, c_idx, clock, args...) = diffusive_flux_z(i, j, k, grid, clock, diffusivity(closure, c_idx, args...), c)

#####
##### Zero out not used fluxes
#####

for (dir, closure) in zip((:x, :y, :z), (:AVD, :AVD, :AHD))
    diffusive_flux = Symbol(:diffusive_flux_, dir)
    viscous_flux_u = Symbol(:viscous_flux_u, dir)
    viscous_flux_v = Symbol(:viscous_flux_v, dir)
    viscous_flux_w = Symbol(:viscous_flux_w, dir)
    @eval begin
        @inline $diffusive_flux(i, j, k, grid, closure::$closure, c, c_idx, clock, args...) = zero(eltype(grid))
        @inline $viscous_flux_u(i, j, k, grid, closure::$closure, c, clock, U, args...)     = zero(eltype(grid))
        @inline $viscous_flux_v(i, j, k, grid, closure::$closure, c, clock, U, args...)     = zero(eltype(grid))
        @inline $viscous_flux_w(i, j, k, grid, closure::$closure, c, clock, U, args...)     = zero(eltype(grid))
    end
end

#####
##### Support for VerticallyImplicit
#####

const VITD = VerticallyImplicit

  @inline z_viscosity(closure::AbstractScalarDiffusivity, args...)        = viscosity(closure, args...)
@inline z_diffusivity(closure::AbstractScalarDiffusivity, c_idx, args...) = diffusivity(closure, c_idx, args...)

@inline ivd_viscous_flux_uz(i, j, k, grid, closure, clock, U, args...) = - ν_σᶠᶜᶠ(i, j, k, grid, clock, closure.ν, ∂xᶠᶜᶠ, U.w)
@inline ivd_viscous_flux_vz(i, j, k, grid, closure, clock, U, args...) = - ν_σᶜᶠᶠ(i, j, k, grid, clock, closure.ν, ∂yᶜᶠᶠ, U.w)

# General functions (eg for vertically periodic)
@inline viscous_flux_uz(i, j, k, grid,  ::VITD, closure::Union{AID, AVD}, args...) = ivd_viscous_flux_uz(i, j, k, grid, closure, args...)
@inline viscous_flux_vz(i, j, k, grid,  ::VITD, closure::Union{AID, AVD}, args...) = ivd_viscous_flux_vz(i, j, k, grid, closure, args...)
@inline viscous_flux_wz(i, j, k, grid,  ::VITD, closure::Union{AID, AVD}, args...) = zero(eltype(grid))
@inline diffusive_flux_z(i, j, k, grid, ::VITD, closure::Union{AID, AVD}, clock, args...) = zero(eltype(grid))
                  
# Vertically bounded grids
#
# For vertically bounded grids, we calculate _explicit_ fluxes on the boundaries, 
# and elide the implicit vertical flux component everywhere else. This is consistent
# with the formulation of the tridiagonal solver, which requires explicit treatment
# of boundary contributions (eg boundary contributions must be moved to the right
# hand side of the tridiagonal system).

@inline function viscous_flux_uz(i, j, k, grid::VerticallyBoundedGrid, ::VITD, closure::Union{AID, AVD}, args...)
    return ifelse(k == 1 || k == grid.Nz+1, 
                  viscous_flux_uz(i, j, k, grid, Explicit(), closure, args...),
                  ivd_viscous_flux_uz(i, j, k, grid, closure, args...))
end

@inline function viscous_flux_vz(i, j, k, grid::VerticallyBoundedGrid, ::VITD, closure::Union{AID, AVD}, args...)
    return ifelse(k == 1 || k == grid.Nz+1, 
                  viscous_flux_vz(i, j, k, grid, Explicit(), closure, args...),
                  ivd_viscous_flux_vz(i, j, k, grid, closure, args...))
end

@inline function viscous_flux_wz(i, j, k, grid::VerticallyBoundedGrid{FT}, ::VITD, closure::Union{AID, AVD}, args...) where FT
    return ifelse(k == 1 || k == grid.Nz+1, 
                  viscous_flux_wz(i, j, k, grid, Explicit(), closure, args...),
                  zero(FT))
end

@inline function diffusive_flux_z(i, j, k, grid::VerticallyBoundedGrid{FT}, ::VITD, closure::Union{AID, AVD}, args...) where FT
    return ifelse(k == 1 || k == grid.Nz+1, 
                  diffusive_flux_z(i, j, k, grid, Explicit(), closure, args...),
                  zero(FT))
end
