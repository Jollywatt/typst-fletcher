#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge
#import "/src/diagram.typ": compute-cell-centers, interpret-axes

#import "/src/utils.typ": vector-2d, interp, interp-inv
#import "/src/coords.typ": *

// this test contains no visual output
#show: none


= Test `interp()` and `interp-inv()` are inverses

#let values = (1pt, 2pt, 4pt)
#let indices = (-1, 0, 0.5, 1, 1.75, 3, 4)

#for i in indices {
	let value = interp(values, i, spacing: 10pt)
	let i2 = interp-inv(values, value, spacing: 10pt)
	assert(i == i2)
}

#for v in values {
	let index = interp-inv(values, v , spacing: 10pt)
	let v2 = interp(values, index, spacing: 10pt)
	assert(v == v2)
}


= Test `uv-to-xy()` and `xy-to-uv()` are inverses

#for grid in (
	(
		origin: (0, 0),
		axes: (ltr, ttb),
	),
	(
		origin: (1, -1),
		axes: (ttb, rtl),
	),
) {
	let grid = grid + (
		cell-sizes: (
			(36pt, 72pt, 24pt),
			(12pt, 48pt)
		),
		spacing: (12pt, 48pt),
	)
	grid += fletcher.interpret-axes(grid.axes)
	grid += fletcher.compute-cell-centers(grid)

	for uv in ((0,0), (1,2), (-5.5, 0.75), (3,1.125)) {
		let xy = uv-to-xy(grid, uv)
		assert(uv == xy-to-uv(grid, xy))
		assert(xy == uv-to-xy(grid, uv))

	}
}





#let assert-resolve(ctx, lhs, rhs) = {
	lhs = vector-2d(resolve(ctx, lhs).at(1))
	rhs = vector-2d(resolve(ctx, rhs).at(1))
	assert(lhs == rhs, message: repr((lhs, rhs)))
}

= Resolving $u v$ coordinates independently of grid

#let ctx = default-ctx + (
	target-system: "uv",
	nodes: (
		"a": (anchors: _ => (100, 100)),
		"b": (anchors: _ => (20, 50)),
		"o": (anchors: _ => (0, 0)),
	)
)

#assert-resolve(ctx, (rel: (2, 3), to: (10, 10)), (12, 13))
#assert-resolve(ctx, (rel: (v: 3, u: 4), to: "a"), (104, 103))
#assert-resolve(ctx, (bary: (a: 1, b: 3)), ("a", 75%, "b"))

#assert(is-nan-vector(resolve(ctx, (45deg, 1cm)).at(1)))



== Polar coordinates
#assert-resolve(ctx, (90deg, 1), (calc.cos(90deg), 1))



= Resolving $x y$ coordinates

#let grid = {
	let g = (
		origin: (0, 0),
		axes: (ltr, btt),
		cell-sizes: (
			(36pt, 72pt, 24pt),
			(12pt, 48pt)
		),
		spacing: (12pt, 48pt),
	)
	g += interpret-axes(g.axes)
	g += compute-cell-centers(g)
	g
}

#assert(grid.centers == ((18pt, 84pt, 144pt), (6pt, 84pt)))

#let ctx = default-ctx + (
	target-system: "xyz",
	grid: grid,
	nodes: (
		"a": (anchors: a => (100, 100)),
		"b": (anchors: a => (20, 50)),
		"o": (anchors: a => (0, 0)),
	)
)

#assert-resolve(ctx, (0, 0), (18pt, 6pt))
#assert-resolve(ctx, (0, 1), (18pt, 84pt))

#assert-resolve(ctx, (rel: (1, 0), to: (0, 2)), (1, 2))


#assert-resolve(ctx,
	(rel: (1pt, 1pt), to: (1, 2)),
	(rel: (45deg, calc.sqrt(2)*1pt), to: (1, 2)),
)

#assert(
	resolve(ctx, (-1, 0), (rel: (1, 0))).slice(1) ==
	resolve(ctx, (-1, 0), (0, 0)).slice(1)
)

= Going from $x y$ coordinates to $u v$

#let ctx = ctx + (target-system: "uv")
#assert-resolve(ctx, (18pt, 6pt), (0, 0))
#assert-resolve(ctx, (18pt, 84pt), (0, 1))

= Testing grid-dependence of coordinates

If a grid isn't provided, $x y$-derived coordinates should resolve to #NAN_COORD.

#let ctx = default-ctx + (
	target-system: "xyz",
)

#assert(is-nan-vector(resolve(ctx, (1, 2)).at(1)))
#assert(not is-nan-vector(resolve(ctx, (1pt, 2pt)).at(1)))

#assert(
	resolve(ctx, (1pt, 2pt), (rel: (0deg, 1pt))).slice(1) ==
	resolve(ctx, (1pt, 2pt), (2pt, 2pt)).slice(1)
)

#assert(is-nan-vector(resolve(ctx, (rel: (45deg, 2), to: (1pt, 2pt))).at(1)))

#assert(resolve(ctx, (1, 2), (rel: (45deg, 2pt))).slice(1).all(is-nan-vector))


#assert(is-grid-independent-uv-coordinate((1,2)))
#assert(not is-grid-independent-uv-coordinate((1pt,2pt)))

#let uv-coord-is-grid-independent(coord) = {
	let ctx = default-ctx + (
		target-system: "uv",
	)
	(ctx, coord) = resolve(ctx, coord)
	not coord.all(x => type(x) == float and x.is-nan())
}

#assert(uv-coord-is-grid-independent((1, 2)))
#assert(uv-coord-is-grid-independent((rel: (+10, 0), to: (1, 2))))
#assert(not uv-coord-is-grid-independent((1pt, 2pt)))
#assert(not uv-coord-is-grid-independent((rel: (+10pt, 0pt), to: (1, 2))))


= Previous coordinate

#let ctx = default-ctx + (
	target-system: "xyz",
	grid: grid,
	prev: (pt: (4, 5))
)
#assert-resolve(ctx, (), (4, 5))


= `em` coordinates

#let ctx = default-ctx + (
	target-system: "uv",
	grid: grid,
)

#assert-resolve(ctx,
	(rel: (0pt, 1em), to: (0pt, 1pt)),
	(0pt, 1em + 1pt),
)

#assert-resolve(ctx + (em-size: (width: 1cm)),
	(0deg, 1pt + 1em),
	(0deg, 1pt + 1cm),
)
