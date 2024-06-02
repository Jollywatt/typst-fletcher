#set page(width: auto, height: auto, margin: 1em)
#import "/src/cetz-rework.typ": *
#import "/src/deps.typ": cetz
#import "/src/coords.typ": uv-to-xy, xy-to-uv
#import "/src/diagram.typ": compute-cell-centers, interpret-axes
#import "/src/utils.typ": vector

#let dummy-ctx = (
	prev: (pt: (0,0,0)),
	length: 1cm,
	nodes: (a: (anchors: _ => (1, 2, 3))),
	transform: cetz.matrix.ident(),
)

// #cetz.coordinate.resolve(dummy-ctx, ((0,0), 100%, "a"))

#let resolve-system(coord) = {
	if type(coord) == array and coord.len() == 2 {
		// coord.all(x => type(x) in (int, float, length)) {
		if coord.all(x => type(x) == length) {
			cetz.coordinate.resolve-system(coord)
		} else if coord.all(x => type(x) in (int, float)) {
			if coord.len() == 2 { "uv" }
			else { panic() }
		} else {
			panic("Coordinate must be all numbers (for elastic coordinates) or all lengths (for physical coordinates); got " + repr(coord))
		}
	} else if type(coord) == dictionary and ("u", "v").all(k => k in coord) {
		"uv"
	} else {
		cetz.coordinate.resolve-system(coord)
	}
}



#let coord-depends-on-grid(ctx, coord) = {
	let system = cetz.coordinate.resolve-system(coord)

	if system == "xyz" {
		coord.any(x => type(x) == length)
	} else if system == "polar" {
		let (angle, radius) = coord
		type(radius) == length
	} else if system == "relative" {
		let (rel, to) = coord
		coord-depends-on-grid(ctx, rel) or coord-depends-on-grid(ctx, to)
	} else if system == "element" {
		coord not in ctx.elements
	} else {
		panic("Can't process " + system + " coordinate system.")
	}
}

#coord-depends-on-grid((elements: "a"), (rel: (1, 2), to: "a"))

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

	if is-xy(rel) and is-uv(to) {
		to = uv-to-xy(ctx.grid, to)
	} else if is-uv(rel) and is-xy(to) {
		to = xy-to-uv(ctx.grid, to)
	}

	c = vector.add(rel, to)

	if ctx.target-system == "xyz" and is-uv(c) {
		c = uv-to-xy(ctx.grid, c)
	}

	// if is-uv(c) { panic(c, ctx)}

	// if resolve-system(rel) != resolve-system(to) {panic(rel, to, rel-to-systems)}


	(coord: c, update: update)
}



#let resolve(ctx, ..coordinates, update: true) = {
	let result = ()
	for c in coordinates.pos() {
		let t = resolve-system(c)
		let out = if t == "uv" {
			if ctx.target-system in (auto, "uv") { c }
			else {
				uv-to-xy(ctx.grid, c)
			}
		} else if t == "xyz" {
			if ctx.target-system in (auto, "xyz") {
				cetz.coordinate.resolve-xyz(c)
			} else {
				panic("whoops")
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
		}//.map(cetz.util.resolve-number.with(ctx))

		if update {
			ctx.prev.pt = out
		}
		result.push(out)
	}

	return (ctx, ..result)
}


#let grid = (
	origin: (1, -1),
	axes: (ltr, btt),
	cell-sizes: (
		(36pt, 72pt, 24pt),
		(12pt, 48pt)
	),
	spacing: (12pt, 48pt),
)
#{
	grid += interpret-axes(grid.axes)
	grid += compute-cell-centers(grid)
	dummy-ctx += (grid: grid)
}


#{dummy-ctx += (target-system: "uv")}
#resolve(dummy-ctx, (rel: (0, 0), to: (1,1))).at(1)
#resolve(dummy-ctx, (1,1)).at(1)

#{dummy-ctx += (target-system: "xyz")}
#resolve(dummy-ctx, (rel: (1, 1), to: (0,0))).at(1)
#resolve(dummy-ctx, (rel: (0pt, 0pt), to: (1,1))).at(1)
#resolve(dummy-ctx, (1,1)).at(1)
