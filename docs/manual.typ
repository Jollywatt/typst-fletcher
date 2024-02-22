#import "@preview/tidy:0.2.0"
#import "/src/exports.typ" as fletcher: node, edge
#import "/docs/style.typ"

#set page(numbering: "1")
#set par(justify: true)
#show link: underline.with(stroke: 1pt + blue.lighten(70%))

#let VERSION = toml("/typst.toml").package.version

// link to a specific parameter of a function
#let param(func, arg, full: false) = {
	let func = func.text
	let arg = arg.text
	let l1 = style.fn-param-label(func, arg)
	let l2 = style.fn-label(func)
	if full [
		the #link(l1, raw(arg)) option of #link(l2, raw(func + "()"))
	] else {
		link(l1, raw(arg))
	}
}
#let the-param = param.with(full: true)

#let scope = (
	fletcher: fletcher,
	diagram: fletcher.diagram,
	node: node,
	edge: edge,
	cetz: fletcher.cetz,
	param: param,
	the-param: the-param,

)

#let show-fns(file, only: none, exclude: ()) = {
	let module-doc = tidy.parse-module(read(file), scope: scope)

	module-doc.functions = module-doc.functions.filter(fn => {
		(only == none or fn.name in only ) and fn.name not in exclude
	})

	tidy.show-module(module-doc, show-outline: false, style: style)
}

#show heading.where(level: 1): it => it + v(0.5em)


#show "CeTZ": it => link("https://github.com/johannes-wolf/cetz", it)

#v(.2fr)

#align(center)[
	#stack(
		spacing: 14pt,
		{
			set text(1.3em)
			fletcher.diagram(
				edge-stroke: 1pt,
				spacing: 27mm,
				label-sep: 6pt,
				node((0,1), $A$),
				node((1,1), $B$),
				edge((0,1), (1,1), $f$, ">>->"),
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
	flow charts,
	state machines,
	block diagrams...
	]

	#link("https://github.com/Jollywatt/typst-fletcher")[`github.com/Jollywatt/typst-fletcher`]

	*Version #VERSION*
]

#set raw(lang: "typc")
#show raw.where(block: false): it => {
	if it.text.ends-with("()") {
		return link(label(it.text), it)
	} else {
		it
	}
}


#v(1fr)

// #heading(outlined: false)[Contents]
// #block(height: 40%, columns(2, outline(indent: 1em, title: none)))

#columns(2)[
	#outline(title: [Guide], indent: 1em, target: selector(heading).before(<func-ref>, inclusive: false))
	#colbreak()
	#outline(title: [Reference], indent: 1em, target: selector(heading).after(<func-ref>, inclusive: true))

]

#v(1fr)










#let gallery-page = true

#if gallery-page [
#pagebreak()

#align(center)[

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

	#fletcher.diagram(
		spacing: (40mm, 35mm),
		node-defocus: 0,
		axes: (ltr, btt),
		{
		let c(x, y, z) = (x + 0.5*z, y + 0.4*z)

		let v000 = c(0, 0, 0)

		node(v000, $P$)
		node(c(1,0,0), $P$)
		node(c(2,0,0), $X$)
		node(c(0,1,0), $J P$)
		node(c(1,1,0), $J P$)
		node(c(2,1,0), $J X$)
	  
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
		edge(c(0,1,0), v000, $pi_J$, "=>", label-pos: 0.2)
		edge(c(1,1,0), c(1,0,0), $pi_J$, "->", label-pos: 0.2)
		edge(c(2,1,0), c(2,0,0), $pi_"CP"$, "->", label-pos: 0.2)
	  
		edge(c(0,1,1), c(0,0,1), $c_pi$, "..>", label-pos: 0.2)
		edge(c(1,1,1), c(1,0,1), $c_pi$, "->", label-pos: 0.2)
		edge(c(2,1,1), c(2,0,1), $overline(c)_pi$, "-||->", label-pos: 0.2)
	  
		// acrosses
		edge(v000, c(1,0,0), $lambda_g$, "->")
		edge(c(1,0,0), c(2,0,0), $pi^G=pi$, "->")
	  
		edge(c(0,0,1), c(1,0,1), $lambda_g times 1$, "..>", label-pos: 0.2)
		edge(c(1,0,1), c(2,0,1), $pi^G$, "..>", label-pos: 0.2)
	  
		edge(c(0,1,0), c(1,1,0), $j lambda_g$, "->", label-pos: 0.7)
	  
		edge(c(0,1,1), c(1,1,1), $dif lambda_g times.circle (lambda_g times 1)$, "->")
		edge(c(1,1,1), c(2,1,1), $pi^G$, "->")

		edge(c(1,1,1), c(2,1,1), $Ω$, "<..>", bend: 40deg)
	})
	#v(1cm)

	#v(1fr)

	#{
		set text(white, font: "Fira Sans")
		let colors = (maroon, olive, eastern)
		fletcher.diagram(
			edge-stroke: 1pt,
			node-corner-radius: 5pt,
			edge-corner-radius: 8pt,
			mark-scale: 80%,
			node((0,0), [input], fill: colors.at(0)),
			node((2,+1), [memory unit (MU)], fill: colors.at(1)),
			node((2, 0), align(center)[arithmetic & logic \ unit (ALU)], fill: colors.at(1)),
			node((2,-1), [control unit (CU)], fill: colors.at(1)),
			node((4,0), [output], fill: colors.at(2), shape: fletcher.shapes.hexagon),

			edge((0,0), "r,u,r", "-}>"),
			edge((2,-1), "r,d,r", "-}>"),
			edge((2,-1), "r,dd,l", "--}>"),
			edge((2,1), "l", (1,-.5), marks: ((kind: "}>", pos: 0.65, rev: false),)),

			for i in range(-1, 2) {
				edge((2,0), (2,1), "<{-}>", shift: i*5mm, bend: i*20deg)
			},

			edge((2,-1), (2,0), "<{-}>"),
		)
	}
]

]

#pagebreak()


= Usage examples

Avoid importing everything with `*` as many internal functions are also exported.

#raw(lang: "typ", "#import \"@preview/fletcher:" + VERSION + "\" as fletcher: node, edge")


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
		debug: true,          // show a coordinate grid
		spacing: (10mm, 5mm), // wide columns, narrow rows
		node-stroke: 1pt,     // outline node shapes
		edge-stroke: 1pt,     // make lines thicker
		mark-scale: 60%,      // make arrowheads smaller
		edge((-2,0), "r,u,r", "-|>", $f$, label-side: left),
		edge((-2,0), "r,d,r", "..|>", $g$),
		node((0,-1), $F(s)$),
		node((0,+1), $G(s)$),
		edge((0,+1), (1,0), "..|>", corner: left),
		edge((0,-1), (1,0), "-|>", corner: right),
		node((1,0), text(white, $ plus.circle $), inset: 2pt, fill: black),
		edge("-|>"),
	)
	```),

	..code-example(```typ
	An equation $f: A -> B$ and \
	an inline diagram #fletcher.diagram(
		node-inset: 2pt,
		label-sep: 0pt,
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
		edge((2,+1), (2,+1), "->", bend: -130deg, label: [loop!]),
	)
	```)
)


#pagebreak()

= Diagrams

Diagrams are a collection of nodes and edges rendered on a CeTZ canvas.
// Nodes and edges may be passed as separate arguments, together in code blocks, or within `&`-delimited math matrices.

== Elastic coordinates

Diagrams are laid out on a flexible coordinate grid, visible when the #param[diagram][debug] option is turned on.
When a node is placed, the rows and columns grow to accommodate the node's size, like a table.

By default, coordinates $(x, y)$ have $x$ going $arrow.r$ and $y$ going $arrow.b$.
This can be changed with #the-param[diagram][axes].
The #param[diagram][cell-size] option is the minimum row and column width, and #param[diagram][spacing] is the gutter between rows and columns.

#code-example-row(```typ
#let c = (orange, red, green, blue).map(x => x.lighten(50%))
#fletcher.diagram(
	debug: true,
	spacing: 10pt,
	node-corner-radius: 3pt,
	node((0,0), [a], fill: c.at(0), width: 10mm, height: 10mm),
	node((1,0), [b], fill: c.at(1), width:  5mm, height:  5mm),
	node((1,1), [c], fill: c.at(2), width: 20mm, height:  5mm),
	node((0,2), [d], fill: c.at(3), width:  5mm, height: 10mm),
)
```)




== Fractional coordinates

So far, this is just like a table --- however, coordinates can be fractional.
These are dealt with by linearly interpolating the diagram between what it would be if the coordinates were rounded up or down.
// Both the node's position and its influence on row/column sizes are interpolated.

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


= Nodes

#link(label("node()"))[`node((x, y), label, ..options)`]

Nodes are content centered at a particular coordinate. They can be circular, rectangular, or of any custom shape. Nodes automatically fit the size of their label (with an #param[node][inset]), but can also be given an exact `width`, `height`, or `radius`, as well as a #param[node][stroke] and #param[node][fill]. For example:

#code-example-row(```typ
#fletcher.diagram(
	debug: true, // show a coordinate grid
	spacing: (5pt, 4em), // small column gaps, large row spacing
	node((0,0), $f$),
	node((1,0), $f$, stroke: 1pt),
	node((2,0), $f$, stroke: blue, shape: rect),
	node((3,0), $f$, stroke: 1pt, radius: 6mm, extrude: (0, 3)),
	{
		let b = blue.lighten(70%)
		node((0,1), `xyz`, fill: b, )
		let dash = (paint: blue, dash: "dashed")
		node((1,1), `xyz`, stroke: dash, inset: 1em)
		node((2,1), `xyz`, fill: b, stroke: blue, extrude: (0, -2))
		node((3,1), `xyz`, fill: b, height: 5em, corner-radius: 5pt)
	}
)
```)



== Node shapes

By default, nodes are circular or rectangular depending on the aspect ratio of their label. The #param[node][shape] option accepts `rect`, `circle`, various shapes provided in the `fletcher.shapes` submodule, or a function.


#code-example-row(```typ
#import fletcher.shapes: pill, parallelogram, diamond, hexagon
#let theme = rgb("8cf")
#fletcher.diagram(
	node-fill: gradient.radial(white, theme, radius: 100%),
	node-stroke: theme,
	(
		node((0,0), [Blue Pill], shape: pill),
		node((1,0), [_Slant_], shape: parallelogram.with(angle: 20deg)),
		node((0,1), [Choice], shape: diamond),
		node((1,1), [Stop], shape: hexagon, extrude: (-3, 0), inset: 10pt),
	).intersperse(edge("o--|>")).join()
)
```)

Custom CeTZ shapes are possible by passing a callback to `shape`, but it is up to the user implement outline extrusion; see the `shape` option of `node()` for details.



= Edges

#link(label("edge()"))[`edge(from, to, label, marks, ..options)`]

Edges connect two coordinates. If there is a node at an endpoint, the edge attaches to the nodes' bounding shape (after applying the node's `outset`). Edges can have `label`s, can #param[edge][bend] into arcs, and can have various arrow #param[edge][marks].

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

	node((.6,3), [_just a thought..._])
	edge(b, "..|>", corner: right)
})
```)

== Implicit coordinates

To specify the start and end points of an edge, you may provide both explicitly (like `edge(from, to)`); leave `from` implicit (like `edge(to)`); or leave both implicit.
When `from` is implicit, it becomes the coordinate of the last `node`, and if `to` is implicit, the next `node`.

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

However, don't forget you can also use variables in code-mode, which is a more explicit and flexible way to reduce repetition of coordinates.

#code-example-row(```typ
#fletcher.diagram(node-fill: blue, {
	let (dep, arv) = ((0,0), (1,1))
	node(dep, text(white)[London])
	node(arv, text(white)[Paris])
	edge(dep, arv, "==>", bend: 40deg)
})
```)


== Relative coordinates

You may specify an edge's direction instead of its end coordinate. This can be done with `edge((x, y), (rel: (Δx, Δy)))`, or with string of _directions_ for short, e.g., `"u"` for up or `"br"` for bottom right. Any combination of
#strong[t]op/#strong[u]p/#strong[n]orth, #strong[b]ottomp/#strong[d]own/#strong[s]outh, #strong[l]eft/#strong[w]est, and #strong[r]ight/#strong[e]ast are allowed. Together with implicit coordinates, this allows you to do things like:

#code-example-row(```typ
#fletcher.diagram($ A edge("rr", ->, #[jump!], bend: #30deg) & B & C $)
```)

== Edge types

There are three `kind`s of edges: `"line"`, `"arc"`, and `"poly"`.
All edges have at least two `vertices`, but `"poly"` edges can have more.
In unspecified, `kind` is chosen based on `bend` and the number of `vertices`.


#code-example-row(```typ
#fletcher.diagram(
	edge((0,0), (1,1), "->", `line`),
	edge((2,0), (3,1), "->", bend: -30deg, `arc`),
	edge((4,0), (4,1), (5,1), (6,0), "->", `poly`),
)
```)


Instead of as positional arguments, an array of coordinates may be also be passed the the edge option `vertices`.
All vertices except the first can be relative (see above), so that the `"poly"` edge above could also be written in these ways:

```typc
edge((4,0), (rel: (0,1)), (rel: (1,0)), (rel: (1,-1)), "->", `poly`)
edge((4,0), "d", "r", "ur", "->", `poly`) // using relative coordinate names
edge((4,0), "d,r,ur", "->", `poly`) // shorthand
```

Only the first and last `vertices` of an edge snap to node outlines.

== Tweaking where edges connect

A node's #param[node][outset] controls how close edges connect to the node's boundary.
To adjust where along the boundary the edge connects, you can adjust the edge's end coordinates by a fractional amount.

#code-example-row(```typ
#fletcher.diagram(
	node-stroke: (thickness: .5pt, dash: "dashed"),
	node((0,0), [no outset], outset: 0pt),
	node((0,1), [big outset], outset: 10pt),
	edge((0,0), (0,1)),
	edge((-0.1,0), (-0.4,1), "-o", "wave"), // shifted with fractional coordinates
	edge((0,0), (0,1), "=>", shift: 15pt),  // shifted by a length
)
```)

The `shift` option of `edge()` lets you shift edges sideways by an absolute length:
#code-example-row(```typ
#fletcher.diagram($A edge(->, shift: #3pt) edge(<-, shift: #(-3pt)) & B$)
```)

By default, edges which are incident at an angle are automatically adjusted slightly, especially if the node is wide or tall.
Aesthetically, things can look more comfortable if edges don't all connect to the node's exact center, but instead spread out a bit.
Notice the (subtle) difference the figures below.

#align(center, stack(
	dir: ltr,
	spacing: 20%,
	..(([With focus (default)], 0.2), ([Without defocus], 0)).map(((label, d)) => {
		figure(
			caption: label,
			fletcher.diagram(
				spacing: 10mm,
				node-defocus: d,
				node((0,0), $A times B times C$),
				edge((-1,1)),
				edge(( 0,1.5)),
				edge((+1,1)),
			)
		)
	})
))

The strength of this adjustment is controlled by the `defocus` option of `node()` (or the `node-defocus` option of `diagram()`).

= Marks and arrows

Edges can be arrows.
Marks can be specified by shorthands like  `edge(a, b, "-->")` or with the `marks` option of `edge()`.
Some mathematical arrow heads are supported, matching $arrow$, $arrow.double$, $arrow.triple$, $arrow.bar$, $arrow.twohead$, and $arrow.hook$.
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

A few other marks are supported, and can be placed anywhere along the edge.

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
These can be retrieved from the mark name as follows:
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
Finally, the fully expanded version of a mark shorthand can be obtained with `interpret-marks-arg()`:
#code-example-row(```typ
#fletcher.interpret-marks-arg("|=>")

// `edge(..args, marks: "|=>")` is equivalent to
// `edge(..args, ..fletcher.interpret-marks-arg("|=>"))`
```)



You can customise the basic marks somewhat by adjusting these parameters.
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

#pagebreak()

= CeTZ integration


Fletcher's drawing cababilities are deliberately restricted to a few simple building blocks.
However, an escape hatch is provided with #the-param[diagram][render] so you can intercept diagram data and draw things using CeTZ directly.

== Bézier edges

Here is an example of how you might hack together a Bézier edge using the same functions that `fletcher` uses internally to anchor edges to nodes:

#code-example-row(```typ
#fletcher.diagram(
	node((0,1), $A$, stroke: 1pt, shape: fletcher.shapes.diamond),
	node((2,0), [Bézier], fill: purple.lighten(80%)),

	render: (grid, nodes, edges, options) => {
		// cetz is also exported as fletcher.cetz
		cetz.canvas({
			// this is the default code to render the diagram
			fletcher.draw-diagram(grid, nodes, edges, debug: options.debug)

			// retrieve node data by coordinates
			let n1 = fletcher.find-node-at(nodes, (0,1))
			let n2 = fletcher.find-node-at(nodes, (2,0))

			let out-angle = 45deg
			let in-angle = -110deg

			fletcher.get-node-anchor(n1, out-angle, p1 => {
				fletcher.get-node-anchor(n2, in-angle, p2 => {
					// make some control points
					let c1 = (to: p1, rel: (out-angle, 10mm))
					let c2 = (to: p2, rel: (in-angle, 20mm))
					cetz.draw.bezier(
						p1, p2, c1, c2,
						mark: (end: ">") // cetz-style mark
					)
				})
			})

		})
	}
)
```)

#pagebreak(weak: true)

== Node groups

Here is another example of how you could automatically draw "node groups" around selected nodes.
First, we find all nodes of a certain fill, obtain their final coordinates, and then draw a rectangle around their bounding box.

#code-example-row(```typ
#let in-group = orange.lighten(60%)
#let out-group = blue.lighten(60%)

// draw a blob around nodes
#let enclose-nodes(nodes, clearance: 8mm) = {
	let points = nodes.map(node => node.final-pos)
	let (center, size) = fletcher.bounding-rect(points)

	cetz.draw.content(
		center,
		rect(
			width: size.at(0) + 2*clearance,
			height: size.at(1) + 2*clearance,
			radius: clearance,
			stroke: in-group,
			fill: in-group.lighten(85%),
		)
	)
}

#fletcher.diagram(
  node((-1,0), `α`, fill: out-group, radius: 5mm),
  edge("o-o"),
  node((0, 0), `β`, fill: in-group, radius: 5mm),
  edge("o-o"),
  node((1,.5), `γ`, fill: in-group, radius: 5mm),
  edge("o-o"),
  node((1,-1), `δ`, fill: out-group, radius: 5mm),

  render: (grid, nodes, edges, options) => {
    // find nodes by color
    let group = nodes.filter(node => node.fill == in-group)
    cetz.canvas({
      enclose-nodes(group) // draw a node group in the background
      fletcher.draw-diagram(grid, nodes, edges, debug: options.debug)
    })
  }
)
```)

#pagebreak()

= Main functions <func-ref>


#show-fns("/src/main.typ", only: (
	"diagram",
	"node",
	"edge",
))


= Behind the scenes
#show-fns("/src/main.typ", exclude: (
	"diagram",
	"node",
	"edge",
))
#show-fns("/src/marks.typ")
#show-fns("/src/utils.typ")
#show-fns("/src/layout.typ")
#show-fns("/src/draw.typ")