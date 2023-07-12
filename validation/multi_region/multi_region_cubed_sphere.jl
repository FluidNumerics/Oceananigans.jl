using Oceananigans

using Oceananigans.Architectures: architecture
using Oceananigans.Grids: halo_size
using Oceananigans.MultiRegion: getregion
using Oceananigans.Utils: Iterate, get_lat_lon_nodes_and_vertices, get_cartesian_nodes_and_vertices
using Oceananigans.BoundaryConditions: fill_halo_regions!

using GLMakie
Makie.inline!(false)
GLMakie.activate!()

function recreate_with_bounded_panels(grid::ConformalCubedSphereGrid)
    arch, FT = architecture(grid), eltype(grid)
    Nx, Ny, Nz = size(grid)

    horizontal_direction_halo, _, z_halo = halo_size(grid)

    z = (getregion(grid, 1).zᵃᵃᶠ[1], getregion(grid, 1).zᵃᵃᶠ[grid.Nz+1])

    radius = getregion(grid, 1).radius

    partition = grid.partition

    return ConformalCubedSphereGrid(arch, FT;
                                    panel_size = (Nx, Ny, Nz),
                                    z, horizontal_direction_halo, z_halo,
                                    radius,
                                    partition,
                                    horizontal_topology = Bounded)
end

function heatsphere!(ax::Axis3, field::CubedSphereField, k=1; kwargs...)
    LX, LY, LZ = location(field)

    grid = recreate_with_bounded_panels(field.grid)

    for region in 1:6
        region_grid = getregion(grid, region)
        _, (xvertices, yvertices, zvertices) = get_cartesian_nodes_and_vertices(region_grid, LX(), LY(), LZ())

        quad_points3 = vcat([Point3.(xvertices[:, i, j], yvertices[:, i, j], zvertices[:, i, j]) 
                            for i in axes(xvertices, 2), j in axes(xvertices, 3)]...)
        quad_faces = vcat([begin; j = (i-1) * 4 + 1; [j j+1  j+2; j+2 j+3 j]; end for i in 1:length(quad_points3)÷4]...)

        colors_per_point = vcat(fill.(vec(interior(getregion(field, region), :, :, k)), 4)...)

        mesh!(ax, quad_points3, quad_faces; color = colors_per_point, shading = false, kwargs...)
    end

    return ax
end

function heatlatlon!(ax::Axis, field::CubedSphereField, k=1; kwargs...)
    LX, LY, LZ = location(field)

    grid = recreate_with_bounded_panels(field.grid)

    for region in 1:6
        region_grid = getregion(grid, region)
        _, (λvertices, φvertices) = get_lat_lon_nodes_and_vertices(region_grid, LX(), LY(), LZ())

        quad_points = vcat([Point2.(λvertices[:, i, j], φvertices[:, i, j]) 
                            for i in axes(λvertices, 2), j in axes(λvertices, 3)]...)
        quad_faces = vcat([begin; j = (i-1) * 4 + 1; [j j+1  j+2; j+2 j+3 j]; end for i in 1:length(quad_points)÷4]...)

        colors_per_point = vcat(fill.(vec(interior(getregion(field, region), :, :, k)), 4)...)

        mesh!(ax, quad_points, quad_faces; color = colors_per_point, shading = false, kwargs...)
    end

    xlims!(ax, (-180, 180))
    ylims!(ax, (-90, 90))

    return ax
end

Nx, Ny, Nz = 16, 16, 2

grid = ConformalCubedSphereGrid(panel_size=(Nx, Ny, Nz), z=(-1, 0), radius=1, horizontal_direction_halo = 3, 
                                z_topology=Bounded)

c = CenterField(grid)

regions = Iterate(Tuple(j for j in 1:length(grid.partition)))

set!(c, regions)

colorrange = (1, 6)
colormap = :Accent_6

@apply_regionally set!(c, (x, y, z) -> cosd(3x)^2 * sind(3y))
colorrange = (-1, 1)

@apply_regionally set!(c, (x, y, z) -> y)
colorrange = (-90, 90)
colormap = :balance

colorrange = (1, Ny)
for region in 1:6, j in 1:Ny, i in 1:Nx
    getregion(c, region).data[i, j, 1] = j
end

fill_halo_regions!(c)


fig = Figure()

ax = Axis3(fig[1, 1], aspect=(1, 1, 1), limits=((-1, 1), (-1, 1), (-1, 1)))

heatsphere!(ax, c; colorrange, colormap)

save("multi_region_cubed_sphere_figure_1.png", fig)


fig = Figure()

ax = Axis(fig[1, 1])

heatlatlon!(ax, c; colorrange, colormap)

save("multi_region_cubed_sphere_figure_2.png", fig)


using GeoMakie

fig = Figure(resolution = (1200, 600))

ax = GeoAxis(fig[1, 1], coastlines = true, lonlims = automatic)

heatlatlon!(ax, c; colorrange, colormap)

save("multi_region_cubed_sphere_figure_3.png", fig)
