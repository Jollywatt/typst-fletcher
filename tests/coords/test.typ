#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge
#import "/src/diagram.typ": compute-cell-centers, interpret-axes


#import "/src/cetz-rework.typ": *


= Resolving $u v$ coordinates independently of grid

#let ctx = default-ctx + (
	target-system: "uv",
	nodes: (
		"a": (anchors: a => (100, 100)),
		"b": (anchors: a => (20, 50)),
		"o": (anchors: a => (0, 0)),
	)
)

#resolve(ctx, (rel: (v: 3, u: 4), to: "a")).at(1)

#resolve(ctx, (bary: (a: 1, b: 3))).at(1) =
#resolve(ctx, ("a", 75%, "b")).at(1)

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

#grid

#let ctx = default-ctx + (
	target-system: "xyz",
	grid: grid,
	nodes: (
		"a": (anchors: a => (100, 100)),
		"b": (anchors: a => (20, 50)),
		"o": (anchors: a => (0, 0)),
	)
)

#resolve(ctx, (1, 2)).at(1) =
#resolve(ctx, (rel: (1, 0), to: (0, 2))).at(1)

#resolve(ctx, (rel: (1pt, 1pt), to: (1, 2))).at(1) =
#resolve(ctx, (rel: (45deg, 1.414pt), to: (1, 2))).at(1)

= Going from $x y$ coordinates to $u v$

#resolve(ctx, (0, 1)).at(1) = (18pt, 84pt)

#let ctx = ctx + (target-system: "uv")
(0, 1) = #resolve(ctx, (18pt, 84pt)).at(1)

= Testing grid-dependence of coordinates

If a grid isn't provided, $x y$-derived coordinates should resolve to #((float("nan"),)*3)

#let ctx = (
	elements: ("a",)
)

#let ctx = default-ctx + (
	target-system: "xyz",
)
#resolve(ctx, (1pt, 2pt), (rel: (45deg, 1.414pt))).slice(1)

#resolve(ctx, (1pt, 2pt), (rel: (45deg, 2))).slice(1)

#resolve(ctx, (1, 2), (rel: (45deg, 2pt))).slice(1)


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

#pagebreak()

#diagram(
	node-fill: teal.transparentize(60%),
	node((0,0), [hello]),
	node((rel: (1, 0)), [right]),
	for i in range(0, 8) {
		node((rel: (i*360deg/8, 1cm), to: (1, 0)), sym.ast, fill: none)
	},
)