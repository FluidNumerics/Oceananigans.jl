"""Upwinding treatment of Kinetic Energy Gradient and Divergence fluxes for the Vector Invariant formulation""" 
abstract type AbstractUpwindingTreatment end

"""Upwinding _inside_ the gradient Operators. i.e., reconstruction of velocity components"""
struct VelocityUpwinding <: AbstractUpwindingTreatment end

struct OnlySelfUpwinding{A, U, V, U2, V2} <: AbstractUpwindingTreatment 
    "advection scheme for cross-reconstructed terms (in both divergence flux and KE gradient)"
    cross_scheme    :: A
    "stencil used for assessing u-derivative smoothness"
    δU_stencil      :: U
    "stencil used for assessing v-derivative smoothness"
    δV_stencil      :: V
    "stencil used for assessing u²-derivative smoothness"
    δu²_stencil     :: U2
    "stencil used for assessing v²-derivative smoothness"
    δv²_stencil     :: V2
end

struct CrossAndSelfUpwinding{A, D, U, V} <: AbstractUpwindingTreatment 
    "advection scheme for cross-reconstructed terms in the kinetic energy gradient"
    cross_scheme       :: A
    "stencil used for assessing divergence smoothness"
    divergence_stencil :: D
    "stencil used for assessing u²-derivative smoothness"
    δu²_stencil        :: U
    "stencil used for assessing v²-derivative smoothness"
    δv²_stencil        :: V
end

"""
    OnlySelfUpwinding(; cross_scheme = CenteredSecondOrder(),
                        δU_stencil   = FunctionStencil(divergence_smoothness),
                        δV_stencil   = FunctionStencil(divergence_smoothness),
                        δu²_stencil  = FunctionStencil(u_smoothness),
                        δv²_stencil  = FunctionStencil(v_smoothness),
                        ) = OnlySelfUpwinding(cross_scheme, δU_stencil, δV_stencil, δu²_stencil, δv²_stencil)

Upwinding treatment for Kinetic Energy Gradient and Divergence fluxes in the Vector Invariant formulation, where only 
the terms correspoding to the transporting velocity are upwinded. (i.e., terms in `u` in the zonal momentum equation and 
terms in `v` in the meridional momentum equation). The terms corresponding to the tangential velocities (`v` in zonal 
direction and `u` in meridional direction) are not upwinded.
This is the default upwinding treatment for the Vector Invariant formulation.

Keyword arguments
=================  

- `δU_stencil`: Stencil used for smoothness indicators of `δx_U` in case of a `WENO` upwind reconstruction. 
                Defaults to `FunctionStencil(divergence_smoothness)`
- `δV_stencil`: Same as `δU_stencil` but for the smoothness of `δy_V`
- `δu²_stencil`: Stencil used for smoothness indicators of `δx_u²` in case of a `WENO` upwind reconstruction. 
                 Defaults to `FunctionStencil(u_smoothness)` 
- `δv²_stencil`: Same as `δu²_stencil` but for the smoothness of `δy_v²`
                 Defaults to `FunctionStencil(v_smoothness)`
"""
OnlySelfUpwinding(; cross_scheme = CenteredSecondOrder(),
                    δU_stencil   = FunctionStencil(divergence_smoothness),
                    δV_stencil   = FunctionStencil(divergence_smoothness),
                    δu²_stencil  = FunctionStencil(u_smoothness),
                    δv²_stencil  = FunctionStencil(v_smoothness),
                    ) = OnlySelfUpwinding(cross_scheme, δU_stencil, δV_stencil, δu²_stencil, δv²_stencil)

"""
    CrossAndSelfUpwinding(; cross_scheme       = CenteredSecondOrder(),
                            divergence_stencil = DefaultStencil(),
                            δu²_stencil        = FunctionStencil(u_smoothness),
                            δv²_stencil        = FunctionStencil(v_smoothness),
                            ) = CrossAndSelfUpwinding(cross_scheme, divergence_stencil, δu²_stencil, δv²_stencil)
                            
Upwinding treatment for Divergence fluxes in the Vector Invariant formulation, where both terms corresponding to
the transporting velocity (`u` in the zonal direction and terms in `v` in the meridional direction) and the 
tangential velocities (`v` in the zonal direction and terms in `u` in the meridional direction) are upwinded. 
Contrarily, only the Kinetic Energy gradient term corresponding to the transporting velocity is upwinded.

Keyword arguments
=================  

- `divergence_stencil`: Stencil used for smoothness indicators of `δx_U + δy_V` in case of a 
                        `WENO` upwind reconstruction. Defaults to `DefaultStencil()`.
- `δu²_stencil`: Stencil used for smoothness indicators of `δx_u²` in case of a `WENO` upwind reconstruction. 
                 Defaults to `FunctionStencil(u_smoothness)` 
- `δv²_stencil`: Same as `δu²_stencil` but for the smoothness of `δy_v²`
                 Defaults to `FunctionStencil(v_smoothness)`
"""
CrossAndSelfUpwinding(; cross_scheme       = CenteredSecondOrder(),
                        divergence_stencil = DefaultStencil(),
                        δu²_stencil        = FunctionStencil(u_smoothness),
                        δv²_stencil        = FunctionStencil(v_smoothness),
                        ) = CrossAndSelfUpwinding(cross_scheme, divergence_stencil, δu²_stencil, δv²_stencil)

Base.summary(a::CrossAndSelfUpwinding) = "CrossAndSelfUpwinding"
Base.summary(a::OnlySelfUpwinding)     = "OnlySelfUpwinding"

Base.show(io::IO, a::OnlySelfUpwinding) =
    print(io, summary(a), " \n",
            " KE gradient cross terms reconstruction: ", "\n",
            "    └── $(summary(a.cross_scheme))", "\n",
            " Smoothness measures: ", "\n",
            "    └── smoothness δU: $(a.δU_stencil)", "\n", 
            "    └── smoothness δV: $(a.δV_stencil)", "\n",
            "    └── smoothness δu²: $(a.δu²_stencil)", "\n",
            "    └── smoothness δv²: $(a.δv²_stencil)")

Adapt.adapt_structure(to, scheme::OnlySelfUpwinding) = 
    OnlySelfUpwinding(Adapt.adapt(to, scheme.cross_scheme),
                      Adapt.adapt(to, scheme.δU_stencil),
                      Adapt.adapt(to, scheme.δV_stencil),
                      Adapt.adapt(to, scheme.δu²_stencil),
                      Adapt.adapt(to, scheme.δv²_stencil))

Base.show(io::IO, a::CrossAndSelfUpwinding) =
print(io, summary(a), " \n",
        " KE gradient cross terms reconstruction: ", "\n",
        "    └── $(summary(a.cross_scheme))", "\n",
        " Smoothness measures: ", "\n",
        "    └── smoothness δ: $(a.divergence_stencil)", "\n", 
        "    └── smoothness δu²: $(a.δu²_stencil)", "\n",
        "    └── smoothness δv²: $(a.δv²_stencil)")

Adapt.adapt_structure(to, scheme::CrossAndSelfUpwinding) = 
    CrossAndSelfUpwinding(Adapt.adapt(to, scheme.cross_scheme),
                          Adapt.adapt(to, scheme.divergence_stencil),
                          Adapt.adapt(to, scheme.δu²_stencil),
                          Adapt.adapt(to, scheme.δv²_stencil))
