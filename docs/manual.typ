#import "@preview/tidy:0.1.0"
#import "/src/exports.typ" as fletcher: node, edge

#set page(numbering: "1")
#set par(justify: true)
#show link: underline.with(stroke: blue.lighten(50%))

#let VERSION = toml("/typst.toml").package.version

#let scope = (
	fletcher: fletcher,
	diagram: fletcher.diagram,
	node: node,
	edge: edge,
	cetz: fletcher.cetz,
)
#let show-module(path) = {
	show heading.where(level: 3): it => {
		align(center, line(length: 100%, stroke: black.lighten(70%)))
		block(text(1.3em, raw(it.body.text + "()")))
	}
	tidy.show-module(
		tidy.parse-module(
			read(path),
			scope: scope,
		),
		show-outline: false,
	)
}

#show heading.where(level: 1): it => it + v(0.5em)

#show raw.where(block: false): it => {
	if it.text.ends-with("()") {
		link(label(it.text), it.text)
	} else { it }
}

#v(.2fr)

#align(center)[
	#stack(
		spacing: 12pt,
		{
			set text(1.3em)
			fletcher.diagram(
				edge-stroke: 1pt,
				spacing: 31mm,
				label-sep: 6pt,
				node((0,1), $A$),
				node((1,1), $B$),
				edge((0,1), (1,1), $f$, ">>->", bend: 15deg),
			)
		},
		text(2.7em, `fletcher`),
		[_(noun) a maker of arrows_],
	)

	#v(30pt)

	A #link("https://typst.app/")[Typst] package for diagrams with lots of arrows,
	built on top of #link("https://github.com/johannes-wolf/cetz")[CeTZ].

	#emph[
	Commutative diagrams,
	finite state machines,
	block diagrams...
	]

	#link("https://github.com/Jollywatt/typst-fletcher")[`github.com/Jollywatt/typst-fletcher`]

	Version #VERSION
]

#v(1fr)

#outline(indent: 1em, target:
	heading.where(level: 1)
	.or(heading.where(level: 2))
	.or(heading.where(level: 3)),
)

#v(1fr)

#pagebreak()

#align(center)[

	#let c(x, y, z) = (x + 0.5*z, y + 0.4*z)
	#fletcher.diagram(
	  spacing: 4cm,
	  node-defocus: 0,
	  axes: (ltr, btt),
	  {

	  let v000 = c(0, 0, 0)

	  node(v000, $P$)
	  node(c(1,0,0), $P$)
	  node(c(2,0,0), $X$)
	  node(c(0,1,0), $J P$)
	  node(c(1,1,0), $J P$)
	  node(c(2,1,0), $"CP"$)
	  
	  node(c(0,0,1), $pi^*(T X times.circle T^* X)$)
	  node(c(1,0,1), $pi^*(T X times.circle T^* X)$)
	  node(c(2,0,1), $T X times.circle T^* X$)
	  node(c(0,1,1), $T P times.circle pi^* T^* X$)
	  node(c(1,1,1), $T P times.circle pi^* T^* X$)
	  node(c(2,1,1), $T_G P times.circle T^* X$)
	  

	  // aways
	  edge(v000, c(0,0,1), $"Id"$, "->", bend: 0deg)
	  edge(c(1,0,0), c(1,0,1), $"Id"$, "->")
	  edge(c(2,0,0), c(2,0,1), $"Id"$, "->")
	  
	  edge(c(0,1,0), c(0,1,1), $i_J$, "hook->")
	  edge(c(1,1,0), c(1,1,1), $i_J$, "hook->")
	  edge(c(2,1,0), c(2,1,1), $i_C$, "hook->")
	  
	  // downs
	  edge(c(0,1,0), v000, $pi_J$, "==>", label-pos: 0.2)
	  edge(c(1,1,0), c(1,0,0), $pi_J$, "->", label-pos: 0.2)
	  edge(c(2,1,0), c(2,0,0), $pi_"CP"$, "->", label-pos: 0.2)
	  
	  edge(c(0,1,1), c(0,0,1), $c_pi$, "..>", label-pos: 0.2)
	  edge(c(1,1,1), c(1,0,1), $c_pi$, "->", label-pos: 0.2)
	  edge(c(2,1,1), c(2,0,1), $overline(c)_pi$, "->", label-pos: 0.2)
	  
	  // acrosses
	  edge(v000, c(1,0,0), $lambda_g$, "->")
	  edge(c(1,0,0), c(2,0,0), $pi^G=pi$, "->")
	  
	  edge(c(0,0,1), c(1,0,1), $lambda_g times 1$, "..>", label-pos: 0.2)
	  edge(c(1,0,1), c(2,0,1), $pi^G$, "..>", label-pos: 0.2)
	  
	  edge(c(0,1,0), c(1,1,0), $j lambda_g$, "->", label-pos: 0.7)
	  
	  edge(c(0,1,1), c(1,1,1), $dif lambda_g times.circle (lambda_g times 1)$, "->")
	  edge(c(1,1,1), c(2,1,1), $pi^G$, "->")

	  edge(c(1,1,1), c(2,1,1), $Ω$, "<..>", bend: 60deg)
	})

	#v(1fr)

	#fletcher.diagram(
		node-defocus: 0,
		spacing: (1cm, 2cm),
		edge-stroke: 1pt,
		crossing-thickness: 5,
		mark-scale: 70%,
		node-fill: luma(97%),
		node-outset: 3pt,
		node((0,0), "magma"),

		node((-1,1), "semigroup"),
		node(( 0,1), "unital magma"),
		node((+1,1), "quasigroup"),

		node((-1,2), "monoid"),
		node(( 0,2), "inverse semigroup"),
		node((+1,2), "loop"),

		node(( 0,3), "group"),

		{
			let quad(a, b, label, paint, ..args) = {
				paint = paint.darken(25%)
				edge(a, b, text(paint, label), "-|>", stroke: paint, label-side: center, ..args)
			}

			quad((0,0), (-1,1), "Assoc", blue)
			quad((0,1), (-1,2), "Assoc", blue, label-pos: 0.3)
			quad((1,2), (0,3), "Assoc", blue)

			quad((0,0), (0,1), "Id", red)
			quad((-1,1), (-1,2), "Id", red, label-pos: 0.3)
			quad((+1,1), (+1,2), "Id", red, label-pos: 0.3)
			quad((0,2), (0,3), "Id", red)

			quad((0,0), (1,1), "Div", yellow)
			quad((-1,1), (0,2), "Div", yellow, label-pos: 0.3, "crossing")

			quad((-1,2), (0,3), "Inv", green)
			quad((0,1), (+1,2), "Inv", green, label-pos: 0.3)

			quad((1,1), (0,2), "Assoc", blue, label-pos: 0.3, "crossing")
		},
	)

	#v(1fr)

	#{
		set text(white, font: "Fira Sans")
		let colors = (maroon, olive, eastern)
		fletcher.diagram(
			edge-stroke: 1pt,
			node-corner-radius: 5pt,
			axes: (ltr, btt),
			node((0,0), [input], fill: colors.at(0)),
			edge((0,0), (1,0), "-"),
			edge((1,0), (2,+1), "-|>", corner: right),
			edge((1,0), (2,-1), corner: left),
			node((2,+1), [control unit (CU)], fill: colors.at(1)),
			edge((2,+1), (2,0), "<|-|>"),
			node((2, 0), align(center)[arithmetic & logic \ unit (ALU)], fill: colors.at(1)),
			edge((2, 0), (2,-1), "<|-|>"),
			node((2,-1), [memory unit (MU)], fill: colors.at(1)),
			edge((2,+1), (3,0), corner: right),
			edge((2,-1), (3,0), "<|-", corner: left),
			edge((3,0), (4,0), "-|>"),
			node((4,0), [output], fill: colors.at(2))
		)
	}

	#v(1fr)

]



#pagebreak()


= Getting started

#raw(lang: "typ", "#import \"@preview/fletcher:" + VERSION + "\" as fletcher: node, edge")

Avoid importing everything `*` as many internal functions are exported.


#let code-example(src) = (
	{
		set text(.85em)
		box(src) // box to prevent pagebreaks
	},
	eval(
		src.text,
		mode: "markup",
		scope: scope
	),
)

#let code-example-row(src) = stack(
	dir: ltr,
	spacing: 1fr,
	..code-example(src)
)

#table(
	columns: (2fr, 1fr),
	align: (top, center),
	// inset: 10pt,

	// stroke: gray + 0.2pt,
	stroke: none,
	inset: (x: 0pt, y: 7pt),

	..code-example(```typ
	// You can specify nodes in math-mode, separated by `&`:
	#fletcher.diagram($
		G edge(f, ->) edge("d", pi, ->>) & im(f) \
		G slash ker(f) edge("ur", tilde(f), "hook-->")
	$)
	```),

	..code-example(```typ
	// Or you can use code-mode, with variables, loops, etc:
	#fletcher.diagram(spacing: 2cm, {
		let (A, B) = ((0,0), (1,0))
		node(A, $cal(A)$)
		node(B, $cal(B)$)
		edge(A, B, $F$, "->", bend: +35deg)
		edge(A, B, $G$, "->", bend: -35deg)
		let h = 0.2
		edge((.5,-h), (.5,+h), $alpha$, "=>")
	})
	```),

	..code-example(```typ
	#fletcher.diagram(
		debug: true,         // show a coordinate grid
		axes: (ltr, btt),    // make y-axis go ↑
		spacing: (8mm, 3mm), // wide columns, narrow rows
		node-stroke: 1pt,    // outline node shapes
		edge-stroke: 1pt,    // make lines thicker
		mark-scale: 60%,     // make arrowheads smaller
		edge((-2,0), (-1,0)),
		edge((-1,0), (0,+1), $f$, "..|>", corner: right),
		edge((-1,0), (0,-1), $g$, "-|>", corner: left),
		node((0,+1), $F(s)$),
		node((0,-1), $G(s)$),
		edge((0,+1), (1,0), "..|>", corner: right),
		edge((0,-1), (1,0), "-|>", corner: left),
		node((1,0), text(white, $ plus.circle $), inset: 1pt, fill: black),
		edge((1,0), (2,0), "-|>"),
	)
	```),

	..code-example(```typ
	An equation $f: A -> B$ and \
	an inline diagram #fletcher.diagram(
		node-inset: 4pt,
		label-sep: 2pt,
		$A edge(->, text(#0.8em, f)) & B$
	).
	```),


	..code-example(```typ
	#fletcher.diagram(
		node-stroke: black + 0.5pt,
		node-fill: gradient.radial(white, blue, center: (40%, 20%),
		                           radius: 150%),
		spacing: (15mm, 8mm),
		node((0,0), [1], extrude: (0, -4)), // double stroke effect 
		node((1,0), [2]),
		node((2,-1), [3a]),
		node((2,+1), [3b]),
		edge((0,0), (1,0), [go], "->"),
		edge((1,0), (2,-1), "->", bend: -15deg),
		edge((1,0), (2,+1), "->", bend: +15deg),
		edge((2,+1), (2,+1), "->", bend: +130deg, label: [loop!]),
	)
	```)
)





#set raw(lang: "typc")
#let fn-link(name) = link(label(name), raw(name))

// = Details

// The recommended way to load the package is:
// #raw(lang: "typ", "#import \"@preview/fletcher:" + VERSION + "\" as fletcher: node, edge", block: true)
// Other functions (including internal functions) are exported, so avoid importing everything with #raw(lang: none, "*") and access them as needed with, e.g., `fletcher.diagram`.

= Nodes

#link(label("node()"))[`node((x, y), label, ..options)`]

Nodes are content centered at a particular coordinate. They automatically fit to the size of their label (with an `inset` and `outset`), can be circular or rectangular (`shape`), and can be given a `stroke` and `fill`.

By default, the coorinates $(x, y)$ are $x$ going $arrow.r$ and $y$ going $arrow.t$.
This can be changed with the `axis` option of `diagram()`.

#code-example-row(```typ
#fletcher.diagram(
	debug: 1,
	spacing: (1em, 4em), // (x, y)
	node((0,0), $f$),
	node((1,0), $f$, stroke: 1pt),
	node((2,0), $f$, stroke: 1pt, shape: "rect"),
	node((3,0), $f$, stroke: 1pt, radius: 6mm, extrude: (0, 3)),
	{
		let b = blue.lighten(70%)
		node((0,1), `xyz`, fill: b, )
		let dash = (paint: blue, dash: "dashed")
		node((1,1), `xyz`, stroke: dash, inset: 2em)
		node((2,1), `xyz`, fill: b, stroke: blue, extrude: (0, -2))
		node((3,1), `xyz`, fill: b, height: 5em, corner-radius: 5pt)
	}
)
```)


== Elastic coordinates

Diagrams are laid out on a flexible coordinate grid.
When a node is placed, the rows and columns grow to accommodate the node's size, like a table.
See the `diagram()` parameters for more control: `cell-size` is the minimum row and column width, and `spacing` is the gutter between rows and columns.

Elastic coordinates can be demonstrated more clearly with a debug grid and no `spacing` between cells:

#code-example-row(```typ
#let c = (orange, red, green, blue).map(x => x.lighten(50%))
#fletcher.diagram(
	debug: 1,
	spacing: 0pt,
	node-corner-radius: 3pt,
	node((0,0), [a], fill: c.at(0), width: 10mm, height: 10mm),
	node((1,0), [b], fill: c.at(1), width:  5mm, height:  5mm),
	node((1,1), [c], fill: c.at(2), width: 20mm, height:  5mm),
	node((0,2), [d], fill: c.at(3), width:  5mm, height: 10mm),
)
```)

So far, this is just like a table. However, coordinates can also be fractional.

== Fractional coordinates

Rows and columns are at integer coordinates, but nodes may have fractional coordinates.
These are dealt with by linearly interpolating the diagram between what it would be if the coordinates were rounded up or down. Both the node's position and its influence on row/column sizes are interpolated.

// As a result, diagrams are responsive to node sizes (like tables) while also allowing precise positioning.
For example, see how the column sizes change as the green box moves from $(0, 0)$ to $(1, 0)$:

#stack(
	dir: ltr,
	spacing: 1fr,
	..(0, .25, .5, .75, 1).map(t => {
		let c = (orange, red, green, blue).map(x => x.lighten(50%))
		fletcher.diagram(
			debug: 1,
			spacing: 0mm,
			node-corner-radius: 3pt,
			node((0,0), [a], fill: c.at(0), width: 10mm, height: 10mm),
			node((1,0), [b], fill: c.at(1), width: 5mm, height: 5mm),
			node((t,1), $(#t, 1)$, fill: c.at(2), width: 20mm, height: 5mm),
			node((0,2), [d], fill: c.at(3), width: 5mm, height: 10mm),
		)
	}),
)


= Edges

#link(label("edge()"))[`edge(from, to, label, marks, ..options)`]

Edges connect two coordinates. If there is a node at an endpoint, the edge attaches to the nodes' bounding shape. Edges can have `label`s, can `bend` into arcs, and can have various arrow `marks`.

#code-example-row(```typ
#fletcher.diagram(spacing: (12mm, 6mm), {
	let (a, b, c, abc) = ((-1,0), (0,1), (1,0), (0,-1))
	node(abc, $A times B times C$)
	node(a, $A$)
	node(b, $B$)
	node(c, $C$)

	edge(a, b, bend: -10deg, "dashed")
	edge(c, b, bend: +10deg, "<-<<")
	edge(a, abc, $a$)
	edge(b, abc, "<=>")
	edge(c, abc, $c$)

	node((0.6, 3), [_just a thought..._])
	edge((0.6, 3), b, "..|>", corner: right)
})
```))

== Implicit coordinates

To specify the start and end points of an edge, you may provide both explicitly (`edge(from, to)`); leave `from` implicit (`edge(to)`); or leave both implicit.
When `from` is implicit, it becomes the coordinate of the last `node`, and `to` becomes the next `node`.

#code-example-row(```typ
#fletcher.diagram(
	node((0,0), [London]),
	edge("..|>", bend: 20deg),
	node((1,1), [Paris]),
)
```)

Implicit coordinates can be handy for diagrams in math-mode:


#code-example-row(```typ
#fletcher.diagram($ L edge("->", bend: #30deg) & P $)
```)

However, don't forget you can also use variables in code-mode to avoid repeating coordinates:

#code-example-row(```typ
#fletcher.diagram(node-fill: blue, {
	let (dep, arv) = ((0,0), (1,1))
	node(dep, text(white)[London])
	node(arv, text(white)[Paris])
	edge(dep, arv, "==>", bend: 40deg)
})
```)


== Relative coordinates

It can also be handy to specify the direction of an edge, instead of its end coordinate. This can be done with `edge((x, y), (rel: (Δx, Δy)))`. For convenience, you can also specify a relative coordinate with string of _directions_, e.g., `"u"` for up or `"br"` for bottom right. Any combination of
#strong[t]op/#strong[u]p/#strong[n]orth, #strong[b]ottomp/#strong[d]own/#strong[s]outh, #strong[l]eft/#strong[w]est, and #strong[r]ight/#strong[e]ast are allowed. Together with implicit coordinates, this allows you do to things like:

#code-example-row(```typ
#fletcher.diagram($ A edge("rr", ->, bend: #30deg) & B & C $)
```)

== The `defocus` adjustment

For aesthetic reasons, lines connecting to a node need not focus to the node's exact center, especially if the node is short and wide or tall and narrow.
Notice the difference the figures below. "Defocusing" the connecting lines can make the diagram look more comfortable.

#align(center, stack(
	dir: ltr,
	spacing: 20%,
	..(("With", 0.2), ("Without", 0)).map(((with, d)) => {
		figure(
			caption: [#with defocus],
			fletcher.diagram(
				spacing: (10mm, 9mm),
				node-defocus: d,
				node((0,0), $A times B times C$),
				edge((-1,1)),
				edge(( 0,2)),
				edge((+1,1)),
			)
		)
	})
))

See the `node-defocus` argument of #link(label("diagram()"))[`diagram()`] for details.

= Marks and arrows

A few mathematical arrow heads are supported, designed to match $arrow$, $arrow.double$, $arrow.triple$, $arrow.bar$, $arrow.twohead$, $arrow.hook$, etc.
#align(center, fletcher.diagram(
	debug: 0,
	spacing: (14mm, 12mm),
{
	for (i, str) in (
		"->",
		"=>",
		"==>",
		"|->",
		"->>",
		"hook->",
	).enumerate() {
		for j in range(2) {
			let label = if j == 0 { raw("\""+str+"\"") }
			edge((2*i, j), (2*i + 1, j), str, bend: 50deg*j, stroke: 0.9pt,
			label: label, label-sep: 1em)
		}
	}
}))
]

Some other marks are supported, and can be placed anywhere along the edge.

#align(center, fletcher.diagram(
	debug: 0,
	spacing: (14mm, 12mm),
{
	for (i, str) in (
		">>-->",
		"||-/-|>",
		"o..O",
		"hook'-x-}>",
		"-*-harpoon'"
	).enumerate() {
		let label = raw("\""+str+"\"")
		edge((2*i, 0), (2*i + 1, 0), str, stroke: 0.9pt,
		label: label, label-sep: 1em)
	}
}))

All the mark shorthands are defined in `fletcher.MARK_ALIASES` and `fletcher.MARK_DEFAULTS`:

#{(fletcher.MARK_ALIASES.keys() + fletcher.MARK_DEFAULTS.keys())
	.sorted(key: i => i.len())
	.map(raw.with(lang: "none"))
	.join([, ])
}

Edge styles can be specified with a shorthand like `edge(a, b, "-->")`. See the `marks` argument of `edge()` for details.



== Adjusting marks

While shorthands exist for specifying marks and stroke styles, finer control is possible.

#code-example-row(```typ
#fletcher.diagram(
	edge-stroke: 1.5pt,
	spacing: 3cm,
	edge((0,0), (-0.1,-1), bend: -10deg, marks: (
		(kind: ">>", size: 6, delta: 70deg, sharpness: 45deg),
		(kind: "bar", size: 1, pos: 0.5),
		(kind: "head", rev: true),
		(kind: "solid", rev: true, stealth: 0.1, paint: red.mix(purple)),
	), stroke: green.darken(50%))
)
```)


Shorthands like `"<->"` expand into specific `edge()` options.
For example, `edge(a, b, "|=>")` is equivalent to `edge(a, b, marks: ("bar", "doublehead"), extrude: (−2, 2))`.
Mark names such as `"bar"` or `"doublehead"` are themselves shorthands for dictionaries defining the marks' parameters.
These parameters can be retrieved from the mark name as follows:
#code-example-row(```typ
#fletcher.interpret-mark("doublehead")
// In this particular example:
// - `kind` selects the type of arrow head
// - `size` controls the radius of the arc
// - `sharpness` is (half) the angle of the tip
// - `delta` is the angle spanned by the arcs
// - `tail` is approximately the distance from the cap's tip to
//    the end of its arms. This is used to calculate a "tail hang"
//    correction to the arrowhead's bearing for tightly curved edges.
// Distances are multiples of the stroke thickness.
```)
Finally, the fully expanded version of a `marks` shorthand can be inspected by invoking `interpret-marks-arg()`:
#code-example-row(```typ
#fletcher.interpret-marks-arg("|=>")

// `edge(..args, marks: "|=>")` is equivalent to
// `edge(..args, ..fletcher.interpret-marks-arg("|=>"))`
```)



You can customise these basic marks by adjusting these parameters.
For example:

#stack(dir: ltr, spacing: 1fr, ..code-example(```typ
#let my-head = (kind: "head", sharpness: 4deg, size: 50, delta: 15deg)
#let my-bar = (kind: "bar", extrude: (0, -3, -6))
#let my-solid = (kind: "solid", sharpness: 45deg)
#fletcher.diagram(
	edge-stroke: 1.4pt,
	spacing: (3cm, 1cm),
	edge((0,0), (1,0), marks: (my-head, my-head + (sharpness: 20deg))),
	edge((0,1), (1,1), marks: (my-bar, my-solid + (pos: 0.8), my-solid)),
)
```))

The particular marks and parameters are hard-wired and will likely change as this package is updated (so they are not documented).
However, you are encouraged to use the functions `interpret-marks-arg()` and `interpret-mark()` to discover the parameters for finer control.

#box[
== Hanging tail correction

All marks accept an `outer-len` parameter, the effect of which can be seen below:
#code-example-row(```typ
#fletcher.diagram(
	edge-stroke: 2pt,
	spacing: 2cm,
	debug: 4,

	edge((0,0), (1,0), stroke: gray, bend: 90deg, label-pos: 0.1, label: [without],
		marks: (none, (kind: "solid", outer-len: 0))),
	edge((0,1), (1,1), stroke: gray, bend: 90deg, label-pos: 0.1, label: [with],
		marks: (none, (kind: "solid"))), // use default hang
)
```)
]
The tail length (specified in multiples of the stroke thickness) is the distance that the arrow head visually extends backwards over the stroke.
This is visualised by the green line shown above.
The mark is rotated so that the ends of the line both lie on the arc.

= CeTZ integration
Currently, only straight, arc and right-angled connectors are supported.
However, an escape hatch is provided with the `render` argument of `diagram()` so you can intercept diagram data and draw things using CeTZ directly.

Here is an example of how you might hack together a Bézier connector using the same functions that `fletcher` uses internally to anchor edges to nodes and draw arrow heads:

#stack(dir: ltr, spacing: 1fr, ..code-example(```typ
#fletcher.diagram(
	node((0,1), $A$),
	node((2,0), [Bézier], fill: purple.lighten(80%)),
	render: (grid, nodes, edges, options) => {
		// cetz is also exported as fletcher.cetz
		cetz.canvas({
			// this is the default code to render the diagram
			fletcher.draw-diagram(grid, nodes, edges, options)

			// retrieve node data by coordinates
			let n1 = fletcher.find-node-at(nodes, (0,1))
			let n2 = fletcher.find-node-at(nodes, (2,0))

			// get anchor points for the connector
			let p1 = fletcher.get-node-anchor(n1, 0deg)
			let p2 = fletcher.get-node-anchor(n2, -90deg)

			// make some control points
			let c1 = cetz.vector.add(p1, (20pt, 0pt))
			let c2 = cetz.vector.add(p2, (0pt, -80pt))

			cetz.draw.bezier(p1, p2, c1, c2)

			// place an arrow head at a given point and angle
			fletcher.draw-arrow-cap(p2,  90deg, 1pt + black, ">>")
			fletcher.draw-arrow-cap(p1, 180deg, 1pt + black,
				(kind: "hook'", outer-len: 0))
		})
	}
)
```))

#pagebreak()

= Function reference
#show-module("/src/main.typ")
#show-module("/src/layout.typ")
#show-module("/src/draw.typ")
#show-module("/src/marks.typ")
#show-module("/src/utils.typ")