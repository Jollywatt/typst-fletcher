#import "utils.typ": *
#import "deps.typ": cetz

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
///   The `grid` is passed to #the-param[diagram][render].
/// - uv (array): Elastic coordinate, `(float, float)`.
#let uv-to-xy(grid, uv) = {
	let (i, j) = vector.sub(vector-2d(uv), grid.origin)

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
///   The `grid` is passed to #the-param[diagram][render].
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

/// Return a vector rooted at a $x y$ coordinate with a given angle $θ$ in $x
/// y$-space but with a length specified in either $x y$-space or $u v$-space.
#let vector-polar-with-xy-or-uv-length(grid, xy, target-length, θ) = {
	if type(target-length) == length {
		vector-polar(target-length, θ)
	} else {
		let unit = vector-polar(1pt, θ)
		let det = vector.len(dxy-to-duv(grid, xy, unit))
		vector.scale(unit, target-length/det)
	}
}



#let NAN_COORD = (float("nan"),)*2

#let default-ctx = (
	prev: (pt: (0, 0)),

	// cetz anchors assume y axis going up.
	// see lines ending with the comment
	// CETZ Y AXIS
	transform: 
		((1, 0, 0, 0),
		 (0,-1, 0, 0),
		 (0, 0, 1, 0),
		 (0, 0, 0, 1)),

	nodes: (:),
	length: 1cm,
	em-size: (width: 11pt, height: 11pt),
	style: cetz.styles.default,
	groups: (),
	debug: false,
)


#let resolve-system(coord) = {
	if type(coord) == dictionary and ("u", "v").all(k => k in coord) {
		return "uv"
	} else if type(coord) == label {
		return "element"
	}

	let cetz-system = cetz.coordinate.resolve-system(coord)
	if cetz-system == "xyz" and coord.len() == 2 {
		if coord.all(x => type(x) == length) {
			"xyz"
		} else if coord.all(x => type(x) in (int, float)) {
			"uv"
		} else {
			error("Coordinates must be two numbers (for elastic coordinates) or two lengths (for physical coordinates); got #0.", coord)
		}
	} else {
		cetz-system
	}
}

#let resolve-anchor(ctx, c) = {
	// (name: <string>, anchor: <number, angle, string> or <none>)
	// "name.anchor"
	// "name"
	if type(c) == label { c = str(c) }

	let (name, anchor) = if type(c) == str {
		let (name, ..anchor) = c.split(".")
		if anchor.len() == 0 {
			anchor = "default"
		}
		(name, anchor)
	} else {
		(str(c.name), c.at("anchor", default: "default"))
	}

	if name not in ctx.nodes {
		error("Node #0 not found. Named nodes are: #..1.", name, ctx.nodes.keys())
	}

	// Resolve length anchors
	if type(anchor) == length {
		anchor = util.resolve-number(ctx, anchor)
	}

	let calculate-anchors = ctx.nodes.at(name).anchors

	(calculate-anchors)(anchor)
}



#let resolve-relative(resolve, ctx, c) = {
	// (rel: <coordinate>, update: <bool> or <none>, to: <coordinate>)
	let update = c.at("update", default: true)

	let target-system = ctx.target-system
	let sub-ctx = ctx + (target-system: auto)

	let (ctx, rel) = resolve(sub-ctx, c.rel, update: false)

	ctx.target-system = target-system
	let (ctx, to) = if "to" in c {
		resolve(ctx, c.to, update: false)
	} else {
		(ctx, ctx.prev.pt)
	}

	if is-nan-vector(to) {
		return (coord: to, update: update)
	}


	let is-xy(coord) = coord.any(x => type(x) == length)
	let is-uv(coord) = not is-xy(coord)

	let error-value = (coord: NAN_COORD, update: update)

	if is-xy(rel) and is-uv(to) {
		if "grid" not in ctx { return error-value }
		to = uv-to-xy(ctx.grid, to)
	} else if is-uv(rel) and is-xy(to) {
		if "grid" not in ctx { return error-value }
		to = xy-to-uv(ctx.grid, to)
	}

	c = vector.add(rel, to)

	if ctx.target-system == "xyz" and is-uv(c) {
		if "grid" not in ctx { return error-value }
		c = uv-to-xy(ctx.grid, c)
	} else if ctx.target-system == "uv" and is-xy(c) {
		if "grid" not in ctx { return error-value }
		c = xy-to-uv(ctx.grid, c)
	}

	(coord: c, update: update)
}


/// Resolve CeTZ-style coordinate expressions to absolute vectors.
///
/// This is an drop-in replacement of `cetz.coordinate.resolve()` but extended
/// to handle fletcher's elastic $u v$ coordinates alongside CeTZ' physical $x
/// y$ coordinates. The target coordinate system must be specified in the
/// context object `ctx`.
///
/// Resolving $u v$ coordinates to or from $x y$ coordinates requires the
/// diagram's `grid`, which defines the non-linear maps `uv-to-xy()` and
/// `xy-to-uv()`. The `grid` may be supplied in the context object `ctx`.
///
/// If `grid` is not supplied, *coordinate resolution may fail*, in which case 
/// the vector #fletcher.NAN_COORD is returned.
///
/// - ctx (dictionary): CeTZ canvas context object, additionally containing:
///   - `target-system`: the target coordinate system to resolve to, one of
///     `"uv"` or `"xyz"`.
///   - `grid` (optional): the diagram's grid specification, defining the
///     coordinate maps $u v <-> x y$. If not given, coordinates requiring this
///     map resolve to #fletcher.NAN_COORD.
///
/// - ..coordinates (coordinate): CeTZ-style coordinate expression(s), e.g.,
///   `(1, 2)`, `(45deg, 2cm)`, or `(rel: (+1, 0), to: "name")`.
#let resolve(ctx, ..coordinates, update: true) = {
	assert(ctx.target-system in (auto, "uv", "xyz"))

	let result = ()
	for c in coordinates.pos() {
		let t = resolve-system(c)
		let out = if t == "uv" {
			if ctx.target-system in (auto, "uv") {
				let (u, v) = c // also works for dictionaries
				(u, v)
			} else if ctx.target-system == "xyz" {
				if "grid" in ctx { uv-to-xy(ctx.grid, c) }
				else { NAN_COORD }
			}
		} else if t == "xyz" {
			let c = cetz.coordinate.resolve-xyz(c)
			c = vector-2d(c).map(x => x.abs + x.em*ctx.em-size.width)
			if ctx.target-system in (auto, "xyz") {
				c
			} else if ctx.target-system == "uv" {
				if "grid" in ctx { xy-to-uv(ctx.grid, c) }
				else { NAN_COORD }
			}
		} else if t == "previous" {
			(ctx, c) = resolve(ctx, ctx.prev.pt)
			c
		} else if t == "polar" {
			c = vector-2d(cetz.coordinate.resolve-polar(c))
			resolve(ctx, c).at(1) // ensure uv <-> xyz conversion
		} else if t == "barycentric" {
			cetz.coordinate.resolve-barycentric(ctx, c)
		} else if t in ("element", "anchor") {
			resolve-anchor(ctx, c)
		} else if t == "tangent" {
			cetz.coordinate.resolve-tangent(resolve, ctx, c)
		} else if t == "perpendicular" {
			cetz.coordinate.resolve-perpendicular(resolve, ctx, c)
		} else if t == "relative" {
			let result = resolve-relative(resolve, ctx, c)
			update = result.update
			result.coord
		} else if t == "lerp" {
			cetz.coordinate.resolve-lerp(resolve, ctx, c)
		} else if t == "function" {
			cetz.coordinate.resolve-function(resolve, ctx, c)
		} else {
			error("Failed to resolve coordinate #0.", c)
		}

		out = vector-2d(out)

		if update { ctx.prev.pt = out }
		result.push(out)
	}

	assert(result.all(c => c.len() == 2))

	return (ctx, ..result)
}


#let is-grid-independent-uv-coordinate(coord) = {
	let ctx = default-ctx + (target-system: "uv")
	(ctx, coord) = resolve(ctx, coord)
	not is-nan-vector(coord)
}

