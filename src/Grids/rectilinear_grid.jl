struct RectilinearGrid{FT, TX, TY, TZ, FX, FY, FZ, VX, VY, VZ, Arch} <: AbstractUnderlyingGrid{FT, TX, TY, TZ, Arch}
    architecture :: Arch
    Nx :: Int
    Ny :: Int
    Nz :: Int
    Hx :: Int
    Hy :: Int
    Hz :: Int
    Lx :: FT
    Ly :: FT
    Lz :: FT
    # All directions can be either regular (FX, FY, FZ) <: Number
    # or stretched (FX, FY, FZ) <: AbstractVector
    Δxᶠᵃᵃ :: FX
    Δxᶜᵃᵃ :: FX
    xᶠᵃᵃ  :: VX
    xᶜᵃᵃ  :: VX
    Δyᵃᶠᵃ :: FY
    Δyᵃᶜᵃ :: FY
    yᵃᶠᵃ  :: VY
    yᵃᶜᵃ  :: VY
    Δzᵃᵃᶠ :: FZ
    Δzᵃᵃᶜ :: FZ
    zᵃᵃᶠ  :: VZ
    zᵃᵃᶜ  :: VZ

    RectilinearGrid{TX, TY, TZ}(arch::Arch,
                                Nx, Ny, Nz,
                                Hx, Hy, Hz,
                                Lx :: FT, Ly :: FT, Lz :: FT,
                                Δxᶠᵃᵃ :: FX, Δxᶜᵃᵃ :: FX,
                                 xᶠᵃᵃ :: VX,  xᶜᵃᵃ :: VX,
                                Δyᵃᶠᵃ :: FY, Δyᵃᶜᵃ :: FY,
                                 yᵃᶠᵃ :: VY,  yᵃᶜᵃ :: VY,
                                Δzᵃᵃᶠ :: FZ, Δzᵃᵃᶜ :: FZ,
                                 zᵃᵃᶠ :: VZ,  zᵃᵃᶜ :: VZ) where {Arch, FT,
                                                                 TX, TY, TZ,
                                                                 FX, VX, FY,
                                                                 VY, FZ, VZ} =
        new{FT, TX, TY, TZ, FX, FY, FZ, VX, VY, VZ, Arch}(arch, Nx, Ny, Nz,
                                                          Hx, Hy, Hz, Lx, Ly, Lz, 
                                                          Δxᶠᵃᵃ, Δxᶜᵃᵃ, xᶠᵃᵃ, xᶜᵃᵃ,
                                                          Δyᵃᶠᵃ, Δyᵃᶜᵃ, yᵃᶠᵃ, yᵃᶜᵃ,
                                                          Δzᵃᵃᶠ, Δzᵃᵃᶜ, zᵃᵃᶠ, zᵃᵃᶜ)
end

const RG = RectilinearGrid

const XRegularRG   = RectilinearGrid{<:Any, <:Any, <:Any, <:Any, <:Number}
const YRegularRG   = RectilinearGrid{<:Any, <:Any, <:Any, <:Any, <:Any,    <:Number}
const ZRegularRG   = RectilinearGrid{<:Any, <:Any, <:Any, <:Any, <:Any,    <:Any,    <:Number}
const XYRegularRG  = RectilinearGrid{<:Any, <:Any, <:Any, <:Any, <:Number, <:Number}
const XYRegularRG  = RectilinearGrid{<:Any, <:Any, <:Any, <:Any, <:Number, <:Number}
const XZRegularRG  = RectilinearGrid{<:Any, <:Any, <:Any, <:Any, <:Number, <:Any,    <:Number}
const YZRegularRG  = RectilinearGrid{<:Any, <:Any, <:Any, <:Any, <:Any,    <:Number, <:Number}
const XYZRegularRG = RectilinearGrid{<:Any, <:Any, <:Any, <:Any, <:Number, <:Number, <:Number}

regular_dimensions(::XRegularRG)  = tuple(1)
regular_dimensions(::YRegularRG)  = tuple(2)
regular_dimensions(::ZRegularRG)  = tuple(3)
regular_dimensions(::XYRegularRG) = (1, 2)
regular_dimensions(::XZRegularRG) = (1, 3)
regular_dimensions(::YZRegularRG) = (2, 3)
regular_dimensions(::XYZRegularRG)   = (1, 2, 3)

stretched_dimensions(::YZRegularRG) = tuple(1)
stretched_dimensions(::XZRegularRG) = tuple(2)
stretched_dimensions(::XYRegularRG) = tuple(3)


"""
    RectilinearGrid([architecture = CPU(), FT = Float64];
                    size,
                    x = nothing,
                    y = nothing,
                    z = nothing,
                    halo = nothing,
                    extent = nothing,
                    topology = (Periodic, Periodic, Bounded))

Create a `RectilinearGrid` with `size = (Nx, Ny, Nz)` grid points.

Positional arguments
====================

- `architecture`: Specifies whether arrays of coordinates and spacings are stored
                  on the CPU or GPU. Default: `CPU()`.

- `FT`: Floating point data type. Default: `Float64`.

Keyword arguments
=================

- `size` (required): A tuple prescribing the number of grid points in non-`Flat` directions.
                     `size` is a 3-tuple for 3D models, a 2-tuple for 2D models, and either a
                     scalar or 1-tuple for 1D models.

- `topology`: A 3-tuple `(TX, TY, TZ)` specifying the topology of the domain.
              `TX`, `TY`, and `TZ` specify whether the `x`-, `y`-, and `z` directions are
              `Periodic`, `Bounded`, or `Flat`. The topology `Flat` indicates that a model does
              not vary in those directions so that derivatives and interpolation are zero.
              The default is `topology = (Periodic, Periodic, Bounded)`.

- `extent`: A tuple prescribing the physical extent of the grid in non-`Flat` directions, e.g.,
            `(Lx, Ly, Lz)`. All directions are constructed with regular grid spacing and the domain
            (in the case that no direction is `Flat`) is ``0 ≤ x ≤ L_x``, ``0 ≤ y ≤ L_y``, and
            ``-L_z ≤ z ≤ 0``, which is most appropriate for oceanic applications in which ``z = 0``
            usually is the ocean's surface.

- `x`, `y`, and `z`: Each of `x, y, z` are either (i) 2-tuples that specify the end points of the domain
                     in their respect directions (in which case scalar values may be used in `Flat`
                     directions), or (ii) arrays or functions of the corresponding indices `i`, `j`, or `k`
                     that specify the locations of cell faces in the `x`-, `y`-, or `z`-direction, respectively.
                     For example, to prescribe the cell faces in `z` we need to provide a function that takes
                     `k` as argument and returns the location of the faces for indices `k = 1` through `k = Nz + 1`,
                     where `Nz` is the `size` of the stretched `z` dimension.

**Note**: _Either_ `extent`, or _all_ of `x`, `y`, and `z` must be specified.

- `halo`: A tuple of integers that specifies the size of the halo region of cells surrounding
          the physical interior for each non-`Flat` direction. The default is 3 halo cells in every direction.

The physical extent of the domain can be specified either via `x`, `y`, and `z` keyword arguments
indicating the left and right endpoints of each dimensions, e.g., `x = (-π, π)` or via
the `extent` argument, e.g., `extent = (Lx, Ly, Lz)`, which specifies the extent of each dimension
in which case ``0 ≤ x ≤ L_x``, ``0 ≤ y ≤ L_y``, and ``-L_z ≤ z ≤ 0``.

A grid topology may be specified via a tuple assigning one of `Periodic`, `Bounded`, and, `Flat`
to each dimension. By default, a horizontally periodic grid topology `(Periodic, Periodic, Bounded)`
is assumed.

Constants are stored using floating point values of type `FT`. By default this is `Float64`.
Make sure to specify the desired `FT` if not using `Float64`.

Grid properties
===============

- `(Nx, Ny, Nz) :: Int`: Number of physical points in the ``(x, y, z)``-direction.

- `(Hx, Hy, Hz) :: Int`: Number of halo points in the ``(x, y, z)``-direction.

- `(Lx, Ly, Lz) :: FT`: Physical extent of the grid in the ``(x, y, z)``-direction.

- `(Δxᶜᵃᵃ, Δyᵃᶜᵃ, Δzᵃᵃᶜ)`: Spacings in the ``(x, y, z)``-directions between the cell faces.
                           These are the lengths in ``x``, ``y``, and ``z`` of `Center` cells and are
                           defined at `Center` locations.

- `(Δxᶠᵃᵃ, Δyᵃᶠᵃ, Δzᵃᵃᶠ)`: Spacings in the ``(x, y, z)``-directions between the cell centers.
                           These are the lengths in ``x``, ``y``, and ``z`` of `Face` cells and are
                           defined at `Face` locations.

- `(xᶜᵃᵃ, yᵃᶜᵃ, zᵃᵃᶜ)`: ``(x, y, z)`` coordinates of cell `Center`s.

- `(xᶠᵃᵃ, yᵃᶠᵃ, zᵃᵃᶠ)`: ``(x, y, z)`` coordinates of cell `Face`s.

Examples
========

* A grid with the default `Float64` type:

```jldoctest
julia> using Oceananigans

julia> grid = RectilinearGrid(size=(32, 32, 32), extent=(1, 2, 3))
32×32×32 RectilinearGrid{Float64, Periodic, Periodic, Bounded} on CPU with 3×3×3 halo
├── Periodic x ∈ [0.0, 1.0)  regularly spaced with Δx=0.03125
├── Periodic y ∈ [0.0, 2.0)  regularly spaced with Δy=0.0625
└── Bounded  z ∈ [-3.0, 0.0] regularly spaced with Δz=0.09375
```

* A grid with `Float32` type:

```jldoctest
julia> using Oceananigans

julia> grid = RectilinearGrid(Float32; size=(32, 32, 16), x=(0, 8), y=(-10, 10), z=(-π, π))
32×32×16 RectilinearGrid{Float32, Periodic, Periodic, Bounded} on CPU with 3×3×3 halo
├── Periodic x ∈ [0.0, 8.0)          regularly spaced with Δx=0.25
├── Periodic y ∈ [-10.0, 10.0)       regularly spaced with Δy=0.625
└── Bounded  z ∈ [-3.14159, 3.14159] regularly spaced with Δz=0.392699
```

* A two-dimenisional, horizontally-periodic grid:

```jldoctest
julia> using Oceananigans

julia> grid = RectilinearGrid(size=(32, 32), extent=(2π, 4π), topology=(Periodic, Periodic, Flat))
32×32×1 RectilinearGrid{Float64, Periodic, Periodic, Flat} on CPU with 3×3×0 halo
├── Periodic x ∈ [3.60072e-17, 6.28319) regularly spaced with Δx=0.19635
├── Periodic y ∈ [7.20145e-17, 12.5664) regularly spaced with Δy=0.392699
└── Flat z
```

* A one-dimensional "column" grid:

```jldoctest
julia> using Oceananigans

julia> grid = RectilinearGrid(size=256, z=(-128, 0), topology=(Flat, Flat, Bounded))
1×1×256 RectilinearGrid{Float64, Flat, Flat, Bounded} on CPU with 0×0×3 halo
├── Flat x
├── Flat y
└── Bounded  z ∈ [-128.0, 0.0]    regularly spaced with Δz=0.5
```

* A horizontally-periodic regular grid with cell interfaces stretched hyperbolically near the top:

```jldoctest
julia> using Oceananigans

julia> σ = 1.1; # stretching factor

julia> Nz = 24; # vertical resolution

julia> Lz = 32; # depth (m)

julia> hyperbolically_spaced_faces(k) = - Lz * (1 - tanh(σ * (k - 1) / Nz) / tanh(σ));

julia> grid = RectilinearGrid(size = (32, 32, Nz),
                              x = (0, 64), y = (0, 64),
                              z = hyperbolically_spaced_faces)
32×32×24 RectilinearGrid{Float64, Periodic, Periodic, Bounded} on CPU with 3×3×3 halo
├── Periodic x ∈ [0.0, 64.0)   regularly spaced with Δx=2.0
├── Periodic y ∈ [0.0, 64.0)   regularly spaced with Δy=2.0
└── Bounded  z ∈ [-32.0, -0.0] variably spaced with min(Δz)=0.682695, max(Δz)=1.83091
```

* A three-dimensional grid with regular spacing in ``x``, cell interfaces at Chebyshev nodes
  in ``y``, and cell interfaces hyperbolically stretched in ``z`` near the top:

```jldoctest
julia> using Oceananigans

julia> Nx, Ny, Nz = 32, 30, 24;

julia> Lx, Ly, Lz = 200, 100, 32; # (m)

julia> chebychev_nodes(j) = - Ly/2 * cos(π * (j - 1) / Ny);

julia> σ = 1.1; # stretching factor

julia> hyperbolically_spaced_faces(k) = - Lz * (1 - tanh(σ * (k - 1) / Nz) / tanh(σ));

julia> grid = RectilinearGrid(size = (Nx, Ny, Nz),
                              topology = (Periodic, Bounded, Bounded),
                              x = (0, Lx),
                              y = chebychev_nodes,
                              z = hyperbolically_spaced_faces)
32×30×24 RectilinearGrid{Float64, Periodic, Bounded, Bounded} on CPU with 3×3×3 halo
├── Periodic x ∈ [0.0, 200.0)  regularly spaced with Δx=6.25
├── Bounded  y ∈ [-50.0, 50.0] variably spaced with min(Δy)=0.273905, max(Δy)=5.22642
└── Bounded  z ∈ [-32.0, -0.0] variably spaced with min(Δz)=0.682695, max(Δz)=1.83091
```
"""
function RectilinearGrid(architecture::AbstractArchitecture = CPU(),
                         FT::DataType = Float64;
                         size,
                         x = nothing,
                         y = nothing,
                         z = nothing,
                         halo = nothing,
                         extent = nothing,
                         topology = (Periodic, Periodic, Bounded))

    if (architecture == CUDAGPU() && !has_cuda()) || (architecture == ROCmGPU() && !has_rocm_gpu())
        throw(ArgumentError("Cannot create a GPU grid. No CUDA or ROCm enabled GPU was detected!"))
    end

    topology, size, halo, x, y, z = validate_rectilinear_grid_args(topology, size, halo, FT, extent, x, y, z)

    TX, TY, TZ = topology
    Nx, Ny, Nz = size
    Hx, Hy, Hz = halo

    Lx, xᶠᵃᵃ, xᶜᵃᵃ, Δxᶠᵃᵃ, Δxᶜᵃᵃ = generate_coordinate(FT, TX(), Nx, Hx, x, :x, architecture)
    Ly, yᵃᶠᵃ, yᵃᶜᵃ, Δyᵃᶠᵃ, Δyᵃᶜᵃ = generate_coordinate(FT, TY(), Ny, Hy, y, :y, architecture)
    Lz, zᵃᵃᶠ, zᵃᵃᶜ, Δzᵃᵃᶠ, Δzᵃᵃᶜ = generate_coordinate(FT, TZ(), Nz, Hz, z, :z, architecture)
 
    return RectilinearGrid{TX, TY, TZ}(architecture,
                                       Nx, Ny, Nz,
                                       Hx, Hy, Hz,
                                       FT(Lx), FT(Ly), FT(Lz),
                                       Δxᶠᵃᵃ, Δxᶜᵃᵃ, xᶠᵃᵃ, xᶜᵃᵃ,
                                       Δyᵃᶠᵃ, Δyᵃᶜᵃ, yᵃᶠᵃ, yᵃᶜᵃ,
                                       Δzᵃᵃᶠ, Δzᵃᵃᶜ, zᵃᵃᶠ, zᵃᵃᶜ)
end

""" Validate user input arguments to the `RectilinearGrid` constructor. """
function validate_rectilinear_grid_args(topology, size, halo, FT, extent, x, y, z)
    TX, TY, TZ = topology = validate_topology(topology)
    size = validate_size(TX, TY, TZ, size)
    halo = validate_halo(TX, TY, TZ, halo)

    # Validate the rectilinear domain
    x, y, z = validate_rectilinear_domain(TX, TY, TZ, FT, size, extent, x, y, z)

    return topology, size, halo, x, y, z
end

#####
##### Showing grids
#####

x_domain(grid::RectilinearGrid) = domain(topology(grid, 1)(), grid.Nx, grid.xᶠᵃᵃ)
y_domain(grid::RectilinearGrid) = domain(topology(grid, 2)(), grid.Ny, grid.yᵃᶠᵃ)
z_domain(grid::RectilinearGrid) = domain(topology(grid, 3)(), grid.Nz, grid.zᵃᵃᶠ)

# architecture = CPU() default, assuming that a DataType positional arg
# is specifying the floating point type.
RectilinearGrid(FT::DataType; kwargs...) = RectilinearGrid(CPU(), FT; kwargs...)

function Base.summary(grid::RectilinearGrid)
    FT = eltype(grid)
    TX, TY, TZ = topology(grid)

    return string(size_summary(size(grid)),
                  " RectilinearGrid{$FT, $TX, $TY, $TZ} on ", summary(architecture(grid)),
                  " with ", size_summary(halo_size(grid)), " halo")
end

function Base.show(io::IO, grid::RectilinearGrid, withsummary=true)
    TX, TY, TZ = topology(grid)

    x₁, x₂ = domain(TX(), grid.Nx, grid.xᶠᵃᵃ)
    y₁, y₂ = domain(TY(), grid.Ny, grid.yᵃᶠᵃ)
    z₁, z₂ = domain(TZ(), grid.Nz, grid.zᵃᵃᶠ)

    x_summary = domain_summary(TX(), "x", x₁, x₂)
    y_summary = domain_summary(TY(), "y", y₁, y₂)
    z_summary = domain_summary(TZ(), "z", z₁, z₂)

    longest = max(length(x_summary), length(y_summary), length(z_summary))

    x_summary = dimension_summary(TX(), "x", x₁, x₂, grid.Δxᶜᵃᵃ, longest - length(x_summary))
    y_summary = dimension_summary(TY(), "y", y₁, y₂, grid.Δyᵃᶜᵃ, longest - length(y_summary))
    z_summary = dimension_summary(TZ(), "z", z₁, z₂, grid.Δzᵃᵃᶜ, longest - length(z_summary))

    if withsummary
        print(io, summary(grid), "\n")
    end

    return print(io, "├── ", x_summary, "\n",
                     "├── ", y_summary, "\n",
                     "└── ", z_summary)
end

#####
##### Utilities
#####

function Adapt.adapt_structure(to, grid::RectilinearGrid)
    TX, TY, TZ = topology(grid)
    return RectilinearGrid{TX, TY, TZ}(nothing,
                                       grid.Nx, grid.Ny, grid.Nz,
                                       grid.Hx, grid.Hy, grid.Hz,
                                       grid.Lx, grid.Ly, grid.Lz,
                                       Adapt.adapt(to, grid.Δxᶠᵃᵃ),
                                       Adapt.adapt(to, grid.Δxᶜᵃᵃ),
                                       Adapt.adapt(to, grid.xᶠᵃᵃ),
                                       Adapt.adapt(to, grid.xᶜᵃᵃ),
                                       Adapt.adapt(to, grid.Δyᵃᶠᵃ),
                                       Adapt.adapt(to, grid.Δyᵃᶜᵃ),
                                       Adapt.adapt(to, grid.yᵃᶠᵃ),
                                       Adapt.adapt(to, grid.yᵃᶜᵃ),
                                       Adapt.adapt(to, grid.Δzᵃᵃᶠ),
                                       Adapt.adapt(to, grid.Δzᵃᵃᶜ),
                                       Adapt.adapt(to, grid.zᵃᵃᶠ),
                                       Adapt.adapt(to, grid.zᵃᵃᶜ))
end

cpu_face_constructor_x(grid::XRegularRG) = x_domain(grid)
cpu_face_constructor_y(grid::YRegularRG) = y_domain(grid)
cpu_face_constructor_z(grid::ZRegularRG) = z_domain(grid)

function with_halo(new_halo, old_grid::RectilinearGrid)

    size = (old_grid.Nx, old_grid.Ny, old_grid.Nz)
    topo = topology(old_grid)

    x = cpu_face_constructor_x(old_grid)
    y = cpu_face_constructor_y(old_grid)
    z = cpu_face_constructor_z(old_grid)

    # Remove elements of size and new_halo in Flat directions as expected by grid
    # constructor
    size     = pop_flat_elements(size, topo)
    new_halo = pop_flat_elements(new_halo, topo)

    new_grid = RectilinearGrid(architecture(old_grid), eltype(old_grid);
                               size, x, y, z,
                               topology = topo,
                               halo = new_halo)

    return new_grid
end

function on_architecture(new_arch::AbstractArchitecture, old_grid::RectilinearGrid)
    old_properties = (old_grid.Δxᶠᵃᵃ, old_grid.Δxᶜᵃᵃ, old_grid.xᶠᵃᵃ, old_grid.xᶜᵃᵃ,
                      old_grid.Δyᵃᶠᵃ, old_grid.Δyᵃᶜᵃ, old_grid.yᵃᶠᵃ, old_grid.yᵃᶜᵃ,
                      old_grid.Δzᵃᵃᶠ, old_grid.Δzᵃᵃᶜ, old_grid.zᵃᵃᶠ, old_grid.zᵃᵃᶜ)

    new_properties = Tuple(arch_array(new_arch, p) for p in old_properties)

    TX, TY, TZ = topology(old_grid)

    return RectilinearGrid{TX, TY, TZ}(new_arch,
                                       old_grid.Nx, old_grid.Ny, old_grid.Nz,
                                       old_grid.Hx, old_grid.Hy, old_grid.Hz,
                                       old_grid.Lx, old_grid.Ly, old_grid.Lz,
                                       new_properties...)
end

coordinates(::RectilinearGrid) = (:xᶠᵃᵃ, :xᶜᵃᵃ, :yᵃᶠᵃ, :yᵃᶜᵃ, :zᵃᵃᶠ, :zᵃᵃᶜ)

#####
##### Definition of RectilinearGrid nodes
#####

ξname(::RG) = :x
ηname(::RG) = :y
rname(::RG) = :z

@inline xnode(i, grid::RG, ::Center) = @inbounds grid.xᶜᵃᵃ[i]
@inline xnode(i, grid::RG, ::Face)   = @inbounds grid.xᶠᵃᵃ[i]
@inline ynode(j, grid::RG, ::Center) = @inbounds grid.yᵃᶜᵃ[j]
@inline ynode(j, grid::RG, ::Face)   = @inbounds grid.yᵃᶠᵃ[j]
@inline znode(k, grid::RG, ::Center) = @inbounds grid.zᵃᵃᶜ[k]
@inline znode(k, grid::RG, ::Face)   = @inbounds grid.zᵃᵃᶠ[k]

@inline ξnode(i, j, k, grid::RG, ℓx, ℓy, ℓz) = xnode(i, grid, ℓx)
@inline ηnode(i, j, k, grid::RG, ℓx, ℓy, ℓz) = ynode(j, grid, ℓy)
@inline rnode(i, j, k, grid::RG, ℓx, ℓy, ℓz) = znode(k, grid, ℓz)

# Convenience definitions for x, y, znode
@inline xnode(i, j, k, grid::RG, ℓx, ℓy, ℓz) = xnode(i, grid, ℓx)
@inline ynode(i, j, k, grid::RG, ℓx, ℓy, ℓz) = ynode(j, grid, ℓy)
@inline znode(i, j, k, grid::RG, ℓx, ℓy, ℓz) = znode(k, grid, ℓz)

function nodes(grid::RectilinearGrid, ℓx, ℓy, ℓz; reshape=false, with_halos=false)
    x = xnodes(grid, ℓx, ℓy, ℓz; with_halos)
    y = ynodes(grid, ℓx, ℓy, ℓz; with_halos)
    z = znodes(grid, ℓx, ℓy, ℓz; with_halos)

    if reshape
        N = (length(x), length(y), length(z))
        x = Base.reshape(x, N[1], 1, 1)
        y = Base.reshape(y, 1, N[2], 1)
        z = Base.reshape(z, 1, 1, N[3])
    end

    return (x, y, z)
end

const F = Face
const C = Center

@inline xnodes(grid::RG, ℓx::F; with_halos=false) = with_halos ? grid.xᶠᵃᵃ : view(grid.xᶠᵃᵃ, interior_indices(ℓx, topology(grid, 1)(), size(grid, 1)))
@inline xnodes(grid::RG, ℓx::C; with_halos=false) = with_halos ? grid.xᶜᵃᵃ : view(grid.xᶜᵃᵃ, interior_indices(ℓx, topology(grid, 1)(), size(grid, 1)))

@inline ynodes(grid::RG, ℓy::F; with_halos=false) = with_halos ? grid.yᵃᶠᵃ : view(grid.yᵃᶠᵃ, interior_indices(ℓy, topology(grid, 2)(), size(grid, 2)))
@inline ynodes(grid::RG, ℓy::C; with_halos=false) = with_halos ? grid.yᵃᶜᵃ : view(grid.yᵃᶜᵃ, interior_indices(ℓy, topology(grid, 2)(), size(grid, 2)))

@inline znodes(grid::RG, ℓz::F; with_halos=false) = with_halos ? grid.zᵃᵃᶠ : view(grid.zᵃᵃᶠ, interior_indices(ℓz, topology(grid, 3)(), size(grid, 3)))
@inline znodes(grid::RG, ℓz::C; with_halos=false) = with_halos ? grid.zᵃᵃᶜ : view(grid.zᵃᵃᶜ, interior_indices(ℓz, topology(grid, 3)(), size(grid, 3)))

# convenience
@inline xnodes(grid::RG, ℓx, ℓy, ℓz; with_halos=false) = xnodes(grid, ℓx; with_halos)
@inline ynodes(grid::RG, ℓx, ℓy, ℓz; with_halos=false) = ynodes(grid, ℓy; with_halos)
@inline znodes(grid::RG, ℓx, ℓy, ℓz; with_halos=false) = znodes(grid, ℓz; with_halos)

#####
##### Grid spacings
#####

@inline xspacings(grid::RG,         ℓx::C; with_halos=false) = with_halos ? grid.Δxᶜᵃᵃ : view(grid.Δxᶜᵃᵃ, interior_indices(ℓx, topology(grid, 1)(), size(grid, 1)))
@inline xspacings(grid::XRegularRG, ℓx::C; with_halos=false) = grid.Δxᶜᵃᵃ
@inline xspacings(grid::RG,         ℓx::F; with_halos=false) = with_halos ? grid.Δxᶠᵃᵃ : view(grid.Δxᶠᵃᵃ, interior_indices(ℓx, topology(grid, 1)(), size(grid, 1)))
@inline xspacings(grid::XRegularRG, ℓx::F; with_halos=false) = grid.Δxᶠᵃᵃ

@inline yspacings(grid::RG,         ℓy::C; with_halos=false) = with_halos ? grid.Δyᵃᶜᵃ : view(grid.Δyᵃᶜᵃ, interior_indices(ℓy, topology(grid, 2)(), size(grid, 2)))
@inline yspacings(grid::YRegularRG, ℓy::C; with_halos=false) = grid.Δyᵃᶜᵃ
@inline yspacings(grid::RG,         ℓy::F; with_halos=false) = with_halos ? grid.Δyᵃᶠᵃ : view(grid.Δyᵃᶠᵃ, interior_indices(ℓy, topology(grid, 2)(), size(grid, 2)))
@inline yspacings(grid::YRegularRG, ℓy::F; with_halos=false) = grid.Δyᵃᶠᵃ

@inline zspacings(grid::RG,         ℓz::C; with_halos=false) = with_halos ? grid.Δzᵃᵃᶜ : view(grid.Δzᵃᵃᶜ, interior_indices(ℓz, topology(grid, 3)(), size(grid, 3)))
@inline zspacings(grid::ZRegularRG, ℓz::C; with_halos=false) = grid.Δzᵃᵃᶜ
@inline zspacings(grid::RG,         ℓz::F; with_halos=false) = with_halos ? grid.Δzᵃᵃᶠ : view(grid.Δzᵃᵃᶠ, interior_indices(ℓz, topology(grid, 3)(), size(grid, 3)))
@inline zspacings(grid::ZRegularRG, ℓz::F; with_halos=false) = grid.Δzᵃᵃᶠ

@inline xspacings(grid::RG, ℓx, ℓy, ℓz; kwargs...) = xspacings(grid, ℓx; kwargs...)
@inline yspacings(grid::RG, ℓx, ℓy, ℓz; kwargs...) = yspacings(grid, ℓy; kwargs...)
@inline zspacings(grid::RG, ℓx, ℓy, ℓz; kwargs...) = zspacings(grid, ℓz; kwargs...)

@inline isrectilinear(::RG) = true

