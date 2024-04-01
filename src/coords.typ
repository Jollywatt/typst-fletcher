#import "utils.typ": *

/// Convert from elastic to absolute coordinates, $(u, v) |-> (x, y)$.
///
/// _Elastic_ coordinates are specific to the diagram and adapt to row/column
/// sizes; _absolute_ coordinates are the final, physical lengths which are
/// passed to `cetz`.
///
/// - grid (dictionary): Representation of the grid layout, including:
///   - `origin`
///   - `centers`
///   - `spacing`
///   - `flip`
/// - uv (array): Elastic coordinate, `(float, float)`.
#let uv-to-xy(grid, uv) = {
	let (i, j) = vector.sub(uv, grid.origin)

	let (n-x, n-y) = grid.centers.map(array.len)
	if grid.flip.xy { (n-x, n-y) = (n-y, n-x) }
	if grid.flip.x { i = (n-x - 1) - i }
	if grid.flip.y { j = (n-y - 1) - j }
	if grid.flip.xy { (i, j) = (j, i) }

	(i, j).zip(grid.centers, grid.spacing)
		.map(((t, c, s)) => interp(c, t, spacing: s))
}

/// Convert from absolute to elastic coordinates, $(x, y) |-> (u, v)$.
///
/// Inverse of `uv-to-xy()`.
#let xy-to-uv(grid, xy) = {
	let (i, j) = xy.zip(grid.centers, grid.spacing)
		.map(((x, c, s)) => interp-inv(c, x, spacing: s))

	let (n-x, n-y) = grid.centers.map(array.len)
	if grid.flip.xy { (n-x, n-y) = (n-y, n-x) }
	if grid.flip.xy { (i, j) = (j, i) }
	if grid.flip.x { i = (n-x - 1) - i }
	if grid.flip.y { j = (n-y - 1) - j }

	vector.add((i, j), grid.origin)
}

/// Jacobian of the coordinate map `uv-to-xy()`.
///
/// Used to convert a "nudge" in $u v$ coordinates to a "nudge" in $x y$
/// coordinates. This is needed because $u v$ coordinates are non-linear
/// (they're elastic). Uses a balanced finite differences approximation.
///
/// - grid (dictionary): Representation of the grid layout.
/// - uv (array): The point `(float, float)` in the $u v$-manifold where the
///   shift tangent vector is rooted.
/// - duv (array): The shift tangent vector `(float, float)` in $u v$ coordinates.
#let duv-to-dxy(grid, uv, duv) = {
	let duv = vector.scale(duv, 0.5)
	vector.sub(
		uv-to-xy(grid, vector.add(uv, duv)),
		uv-to-xy(grid, vector.sub(uv, duv)),
	)
}

/// Jacobian of the coordinate map `xy-to-uv()`.
#let dxy-to-duv(grid, xy, dxy) = {
	let dxy = vector.scale(dxy, 0.5)
	vector.sub(
		xy-to-uv(grid, vector.add(xy, dxy)),
		xy-to-uv(grid, vector.sub(xy, dxy)),
	)
}

/// Return a vector in $x y$ coordinates with a given angle $θ$ in $x y$-space
/// but with a length specified in either $x y$-space or $u v$-space.
#let vector-polar-with-xy-or-uv-length(grid, xy, target-length, θ) = {
	if type(target-length) == length {
		vector-polar(target-length, θ)
	} else {
		let unit = vector-polar(1pt, θ)
		let det = vector.len(dxy-to-duv(grid, xy, unit))
		vector.scale(unit, target-length/det)
	}
}

/// Convert labels into the coordinates of a node with that label, leaving
/// anything else unchanged.
#let resolve-label-coordinate(nodes, coord) = {
	if type(coord) == label {
		let node = nodes.find(node => node.name == coord)
		assert(node != none, message: "Couldn't find label " + repr(coord))
		node.pos
	} else {
		coord
	}
}

/// Given a sequence of coordinates of the form `(x, y)` or `(rel: (Δx, Δy))`,
/// return a sequence in the form `(x, y)` where relative coordinates are
/// applied relative to the previous coordinate in the sequence.
///
/// The first coordinate must be of the form `(x, y)`.
#let resolve-relative-coordinates(coords) = {
	let resolved = coords
	for i in range(1, coords.len()) {
		let prev = resolved.at(i - 1)
		if type(coords.at(i)) == dictionary and "rel" in coords.at(i) {
			resolved.at(i) = vector.add(coords.at(i).rel, prev)
		}
	}
	resolved
}
