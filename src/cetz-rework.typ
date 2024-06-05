#import "/src/deps.typ": cetz
#import "/src/coords.typ": uv-to-xy, xy-to-uv
#import "/src/utils.typ": vector

#let default-ctx = (
  length: 1cm,
  debug: false,
  // Previous element position & bbox
  prev: (pt: (0, 0, 0)),
  style: (:),
  // Current transformation matrix, a rhs coordinate system
  // where z is sheared by a half x and y.
  //   +x = right, +y = up, +z = 1/2 (left + down)
  transform: cetz.matrix.ident(),
    // ((1, 0,-.5, 0),
    //  (0,-1,+.5, 0),
    //  (0, 0, .0, 0),
    //  (0, 0, .0, 1)),
  // Nodes, stores anchors and paths
  nodes: (:),
  // group stack
  groups: (),
)

#let resolve-system(coord) = {
	if type(coord) == dictionary and ("u", "v").all(k => k in coord) {
		return "uv"
	}

	let cetz-system = cetz.coordinate.resolve-system(coord)
	if cetz-system == "xyz" and coord.len() == 2 {
		if coord.all(x => type(x) == length) {
			"xyz"
		} else if coord.all(x => type(x) in (int, float)) {
			"uv"
		} else {
			panic("Coordinate must be two numbers (for elastic coordinates) or two lengths (for physical coordinates); got " + repr(coord))
		}
	} else {
		cetz-system
	}
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

	let is-xy(coord) = coord.any(x => type(x) == length)
	let is-uv(coord) = not is-xy(coord)

	let error-value = (coord: (float("nan"),)*3, update: update)

	if to == none {panic(c, ctx)}
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
	}

	(coord: c, update: update)
}



#let resolve(ctx, ..coordinates, update: true) = {
	assert(ctx.target-system in (auto, "uv", "xyz"))

	let error-value = (float("nan"),)*3

	let result = ()
	for c in coordinates.pos() {
		let t = resolve-system(c)
		let out = if t == "uv" {
			if ctx.target-system in (auto, "uv") {
				let (u, v) = c
				(u, v)
			} else if ctx.target-system == "xyz" {
				if "grid" in ctx {
					uv-to-xy(ctx.grid, c)
				} else {
					error-value
				}
			}
		} else if t == "xyz" {
			if ctx.target-system in (auto, "xyz") {
				cetz.coordinate.resolve-xyz(c)
			} else if ctx.target-system == "uv" {
				if "grid" in ctx {
					xy-to-uv(ctx.grid, c)
				} else {
					error-value
				}
			}
		} else if t == "previous" {
			ctx.prev.pt
		} else if t == "polar" {
			cetz.coordinate.resolve-polar(c)
		} else if t == "barycentric" {
			cetz.coordinate.resolve-barycentric(ctx, c)
		} else if t in ("element", "anchor") {
			cetz.coordinate.resolve-anchor(ctx, c)
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
			panic("Failed to resolve coordinate of format: " + repr(c))
		}

		if update { ctx.prev.pt = out }
		result.push(out)
	}

	return (ctx, ..result)
}

#let is-nan-coord(coord) = coord.all(x => float(x).is-nan())

#let is-grid-independent-uv-coordinate(coord) = {
	let ctx = default-ctx + (target-system: "uv")
	(ctx, coord) = resolve(ctx, coord)
	not is-nan-coord(coord)
}
