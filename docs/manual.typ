#import "@preview/tidy:0.2.0"
#import "/src/exports.typ" as fletcher: diagram, node, edge
#import "/docs/style.typ"

#set page(numbering: "1")
#set par(justify: true)
#show link: underline.with(stroke: 1pt + blue.lighten(70%))

// show references to headings as the heading title with a link
// not as "Section 1.2.3"
#show ref: it => {
	if it.element.func() == heading {
		link(it.target, it.element.body)
	} else { it }
}


#let VERSION = toml("/typst.toml").package.version

// link to a specific parameter of a function
#let param(func, arg, full: false) = {
	let func = func.text
	let arg = arg.text
	let l1 = style.fn-param-label(func, arg)
	let l2 = style.fn-label(func)
	if full {
		[the #link(l1, raw(arg)) option of #link(l2, raw(func + "()"))]
	} else {
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

#let show-fns(file, only: none, exclude: (), level: 1, outline: false) = {
	let module-doc = tidy.parse-module(read(file), scope: scope)


	if only != none {
		let ordered-fns = only.map(fn-name => {
			module-doc.functions.find(fn => fn.name == fn-name)
		})
		module-doc.functions = ordered-fns
	}

	module-doc.functions = module-doc.functions.filter(fn => fn.name not in exclude)

	tidy.show-module(
		module-doc,
		show-outline: outline,
		sort-functions: none,
		first-heading-level: level,
		style: style,
	)
}

#show heading.where(level: 1): it => it + v(0.5em)

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
	// if raw block is a function call, like `foo()`, make it a link
	if it.text.match(regex("^[a-z-]+\(\)$")) == none { it }
	else {
		let l = label(it.text)
		locate(loc => {
			if query(l, loc).len() > 0 {
				link(l, it)
			} else {
				it
			}
		})
	}
}



#v(1fr)


#columns(2)[
	#outline(
		title: align(center, box(width: 100%)[Guide]),
		indent: 1em,
		target: selector(heading).before(<func-ref>, inclusive: false),
	)
	#colbreak()
	#outline(
		title: align(center, box(width: 100%)[Reference]),
		indent: 1em,
		target: selector(heading.where(level: 1)).or(heading.where(level: 2)).after(<func-ref>, inclusive: true),
	)

]

#v(1fr)




// friends :)
#show "CeTZ": it => link("https://github.com/johannes-wolf/cetz", it)
#show "Touying": it => link("https://github.com/touying-typ/touying", it)






#let gallery-page = true

#if gallery-page [
#pagebreak()

#align(center)[

	#diagram(
		node-defocus: 0,
		spacing: (1cm, 2cm),
		edge-stroke: 1pt,
		crossing-thickness: 5,
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
				edge(a, b, text(paint, label), "-latex", stroke: paint, label-side: center, ..args)
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

	#diagram(
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
			edge((2,1), "l", (1,-.5), marks: ((inherit: "}>", pos: 0.65, rev: false),)),

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

#raw(lang: "typ", "#import \"@preview/fletcher:" + VERSION + "\" as fletcher: diagram, node, edge")


#let code-example(src) = (
	{
		set text(.85em)
		let code = src.text.replace(regex("(^|\n).*// hide\n|^[\s|\S]*// setup\n"), "")
		box(raw(block: true, lang: src.lang, code)) // box to prevent pagebreaks
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
	#diagram($
		G edge(f, ->) edge("d", pi, ->>) & im(f) \
		G slash ker(f) edge("ur", tilde(f), "hook-->")
	$)
	```),

	..code-example(```typ
	// Or you can use code-mode, with variables, loops, etc:
	#diagram(spacing: 2cm, {
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
	#diagram(
		spacing: (10mm, 5mm), // wide columns, narrow rows
		node-stroke: 1pt,     // outline node shapes
		edge-stroke: 1pt,     // make lines thicker
		mark-scale: 60%,      // make arrowheads smaller
		edge((-2,0), "r,u,r", "-|>", $f$, label-side: left),
		edge((-2,0), "r,d,r", "..|>", $g$),
		node((0,-1), $F(s)$),
		node((0,+1), $G(s)$),
		node(enclose: ((0,-1), (0,+1)), stroke: teal, inset: 10pt,
		     snap: false), // prevent edges snapping to this node
		edge((0,+1), (1,0), "..|>", corner: left),
		edge((0,-1), (1,0), "-|>", corner: right),
		node((1,0), text(white, $ plus.circle $), inset: 2pt, fill: black),
		edge("-|>"),
	)
	```),

	..code-example(```typ
	An equation $f: A -> B$ and \
	an inline diagram #diagram($A edge(->, text(#0.8em, f)) & B$).
	```),


	..code-example(```typ
	#import fletcher.shapes: diamond
	#diagram(
		node-stroke: black + 0.5pt,
		node-fill: gradient.radial(white, blue, center: (40%, 20%),
		                           radius: 150%),
		spacing: (10mm, 5mm),
		node((0,0), [1], name: <1>, extrude: (0, -4)), // double stroke
		node((1,0), [2], name: <2>, shape: diamond),
		node((2,-1), [3a], name: <3a>),
		node((2,+1), [3b], name: <3b>),
		edge(<1>, <2>, [go], "->"),
		edge(<2>, <3a>, "->", bend: -15deg),
		edge(<2>, <3b>, "->", bend: +15deg),
		edge(<3b>, <3b>, "->", bend: -130deg, label: [loop!]),
	)
	```)
)


#pagebreak()

= Diagrams

Diagrams created with `diagram()` are a collection of _nodes_ and _edges_ rendered on a CeTZ canvas.

== Elastic coordinates

Diagrams are laid out on a _flexible coordinate grid_, visible when #the-param[diagram][debug] is on.
When a node is placed, the rows and columns grow to accommodate the node's size, like a table.

By default, coordinates $(u, v)$ have $u$ going $arrow.r$ and $v$ going $arrow.b$.
This can be changed with #the-param[diagram][axes].
The #param[diagram][cell-size] option is the minimum row and column width, and #param[diagram][spacing] is the gutter between rows and columns.

#code-example-row(```typ
#let c = (orange, red, green, blue).map(x => x.lighten(50%))
#diagram(
	debug: 1,
	spacing: 10pt,
	node-corner-radius: 3pt,
	node((0,0), [a], fill: c.at(0), width: 10mm, height: 10mm),
	node((1,0), [b], fill: c.at(1), width:  5mm, height:  5mm),
	node((1,1), [c], fill: c.at(2), width: 20mm, height:  5mm),
	node((0,2), [d], fill: c.at(3), width:  5mm, height: 10mm),
)
```)


So far, this is just like a table --- however, elastic coordinates can be _fractional_.
Notice how the column sizes change as the green node is gradually moved between columns:

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

== Absolute coordinates

As well as _elastic_ or $u v$ coordinates, which are row/column numbers, you can also use _absolute_ or $x y$ coordinates, which are physical lengths.
This lets you break away from flexible grid layouts.

#table(
	columns: (1fr, 1fr),
	stroke: none,
	align: center,
	..([Elastic coordinates, e.g., `(2, 1)`], [Physical coordinates, e.g., `(10mm, 5mm)`]).map(strong),
	[Dimensionless, dependent on row/column sizes.],
	[Lengths, independent of row/column sizes.],
	[Placed objects can influence diagram layout.],
	[Placed objects never affect diagram layout.],
)

Absolute coordinates aren't very useful on their own, but they may be used in combination with elastic coordinates, particularly with `(rel: (x, y), to: (u, v))`.

#code-example-row(```typ
#diagram(
	node((0, 0), name: <origin>),
	for θ in range(16).map(i => i/16*360deg) {
		node((rel: (θ, 10mm), to: <origin>), $ * $, inset: 1pt)
		edge(<origin>, "-")
	}
)
```)

== All sorts of coordinates

You can also use any CeTZ-style coordinate expression, mixing and matching elastic and physical coordinates, e.g., relative `(rel: (1, 2))`, polar `(45deg, 1cm)`, interpolating `(<P>, 80%, <Q>)`, perpendicular `(<X>, "|-", <Y>)`, and so on.
However, support for CeTZ-style anchors is incomplete.


= Nodes

#link(label("node()"))[`node(coord, label, ..options)`]

Nodes are content centered at a particular coordinate.
They can be circular, rectangular, or any custom shape.
Nodes automatically fit to the size of their label (with an #param[node][inset]), but can also be given an exact `width`, `height`, or `radius`, as well as a #param[node][stroke] and #param[node][fill]. For example:

#code-example-row(```typ
#diagram(
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

By default, nodes are circular or rectangular depending on the aspect ratio of their label.
The #param[node][shape] option accepts `rect`, `circle`, various shapes provided in the #link(<shapes>, `fletcher.shapes`) submodule, or a function.

#code-example-row(```typ
#import fletcher.shapes: pill, parallelogram, diamond, hexagon
#diagram(
	node-fill: gradient.radial(white, blue, radius: 200%),
	node-stroke: blue,
	(
		node((0,0), [Blue Pill], shape: pill),
		node((1,0), [_Slant_], shape: parallelogram.with(angle: 20deg)),
		node((0,1), [Choice], shape: diamond),
		node((1,1), [Stop], shape: hexagon, extrude: (-3, 0), inset: 10pt),
	).intersperse(edge("o--|>")).join()
)
```)

Custom node shapes may be implemented with CeTZ via #the-param[node][shape], but it is up to the user to support outline extrusion for custom shapes.
The predefined shapes are:

#table(
	columns: (1fr,)*4,
	gutter: 2mm,
	stroke: none,
	align: center + horizon,
	..{
		let colors = (
			blue,
			red,
			orange,
			teal,
			olive,
			green,
			purple,
			fuchsia,
			eastern,
			yellow,
			aqua,
			maroon,
		)
		dictionary(fletcher.shapes).pairs()
			.filter(((key, value)) => type(value) != module)
			.zip(colors)
			.map((((name, shape), color)) => {
				diagram(node((0,0), link(label(name + "()"), raw(name)), shape: shape,
					fill: color.lighten(90%), stroke: color))
			})
	}
)

Shapes respect the #param[node][stroke], #param[node][fill], #param[node][width], #param[node][height], and #param[node][extrude] options of `edge()`.


== Node groups

Nodes are usually centered at a particular coordinate, but they can also #param[node][enclose] multiple centers.
When #the-param[node][enclose] is given, the node automatically resizes.

#code-example-row(```typ
#diagram(
	node-stroke: 0.6pt,
	node($Sigma$, enclose: ((1,1), (1,2)), // a node spanning multiple centers
	    inset: 10pt, stroke: teal, fill: teal.lighten(90%), name: <bar>),
	node((2,1), [X]),
	node((2,2), [Y]),
	edge((1,1), "r", "->", snap-to: (<bar>, auto)),
	edge((1,2), "r", "->", snap-to: (<bar>, auto)),
)
```)

You can also #param[node][enclose] other nodes by coordinate or #param[node][name] to create node groups:

#code-example-row(```typ
#diagram(
	node-stroke: 0.6pt,
	node-fill: white,
	node((0,1), [X]),
	edge("->-", bend: 40deg),
	node((1,0), [Y], name: <y>),
	node($Sigma$, enclose: ((0,1), <y>),
	     stroke: teal, fill: teal.lighten(90%),
	     snap: -1, // prioritise other nodes when auto-snapping
	     name: <group>),
	edge(<group>, <z>, "->"),
	node((2.5,0.5), [Z], name: <z>),
)
```)


= Edges

#link(label("edge()"))[`edge(..vertices, marks, label, ..options)`]

An edge connects two coordinates. If there is a node at the endpoint, the edge snaps to the nodes' bounding shape (after applying the node's #param[node][outset]). An edge can have a #param[edge][label], can #param[edge][bend] into an arc, and can have various arrow #param[edge][marks].

#code-example-row(```typ
#diagram(spacing: (12mm, 6mm), {
	let (a, b, c, abc) = ((-1,0), (0,1), (1,0), (0,-1))
	node(abc, $A times B times C$)
	node(a, $A$)
	node(b, $B$)
	node(c, $C$)

	edge(a, b, bend: -18deg, "dashed")
	edge(c, b, bend: +18deg, "<-<<")
	edge(a, abc, $a$)
	edge(b, abc, "<=>")
	edge(c, abc, $c$)

	node((.6,3), [_just a thought..._])
	edge(b, "..|>", corner: right)
})
```)

== Specifying edge vertices

The first few arguments given to `edge()` specify its #param[edge][vertices], of which there can be two or more.

=== Connecting to adjacent nodes

If an edge's first or last vertex is `auto`, the coordinate of the previous or next node is used, respectively, according to the order that nodes and edges are passed to `diagram()`.
A single vertex, as in `edge(to)`, is interpreted as `edge(auto, to)`.
Given no vertices, an edge connects the nearest nodes on either side.


#code-example-row(```typ
#diagram(
	node((0,0), [London]),
	edge("..|>", bend: 20deg),
	edge("<|--", bend: -20deg),
	node((1,1), [Paris]),
)
```)

Implicit coordinates can be handy for diagrams in math-mode:


#code-example-row(```typ
#diagram($ L edge("->", bend: #30deg) & P $)
```)

// However, don't forget you can also use variables in code-mode, which is a more explicit and flexible way to reduce repetition of coordinates.

// #code-example-row(```typ
// #diagram(node-fill: blue, {
// 	let (dep, arv) = ((0,0), (1,1))
// 	node(dep, text(white)[London])
// 	node(arv, text(white)[Paris])
// 	edge(dep, arv, "==>", bend: 40deg)
// })
// ```)

=== Relative coordinate shorthands

Like node positions, edge vertices may be specified by CeTZ-style coordinate expressions, combining elastic and physical coordinates.

Additionally, you may specify relative shorthand strings such as `"u"` for up or `"sw"` for south west. Any combination of
#strong[t]op/#strong[u]p/#strong[n]orth,
#strong[b]ottom/#strong[d]own/#strong[s]outh,
#strong[l]eft/#strong[w]est, and
#strong[r]ight/#strong[e]ast
are allowed. Together with implicit coordinates, this allows you to do things like:

#code-example-row(```typ
#diagram($ A edge("rr", ->, #[jump!], bend: #30deg) & B & C $)
```)

=== Named or labelled coordinates

Another way coordinates can be expressed is through node names.
Nodes can be given a #param[node][name], which is a label (not a string) identifying that node.
A label as an edge vertex is interpreted as the position of the node with that label.

#code-example-row(```typ
#diagram(
	node((0,0), $frak(A)$, name: <A>),
	node((1,0.5), $frak(B)$, name: <B>),
	edge(<A>, <B>, "-->")
)
```)

Node names are _labels_ (instead of strings like in CeTZ) to disambiguate them from other positional string arguments.
Since they are not inserted into the document, they do not interfere with other labels.

== Edge types

There are three types of edges: `"line"`, `"arc"`, and `"poly"`.
All edges have at least two `vertices`, but `"poly"` edges can have more.
If unspecified, #param[edge][kind] is chosen based on #param[edge][bend] and the number of #param[edge][vertices].


#code-example-row(```typ
#diagram(
	edge((0,0), (1,1), "->", `line`),
	edge((2,0), (3,1), "->", bend: -30deg, `arc`),
	edge((4,0), (4,1), (5,1), (6,0), "->", `poly`),
)
```)

All vertices except the first can be relative coordinate shorthands (see above), so that in the example above, the `"poly"` edge could also be written in these equivalent ways:

```typc
edge((4,0), (rel: (0,1)), (rel: (1,0)), (rel: (1,-1)), "->", `poly`)
edge((4,0), "d", "r", "ur", "->", `poly`) // using relative coordinate names
edge((4,0), "d,r,ur", "->", `poly`) // shorthand
```

Only the first and last #param[edge][vertices] of an edge automatically snap to nodes.

== Tweaking where edges connect

A node's #param[node][outset] controls how _close_ edges connect to the node's boundary.
To adjust _where_ along the boundary the edge connects, you can adjust the edge's end coordinates by a fractional amount.

#code-example-row(```typ
#diagram(
	node-stroke: (thickness: .5pt, dash: "dashed"),
	node((0,0), [no outset], outset: 0pt),
	node((0,1), [big outset], outset: 10pt),
	edge((0,0), (0,1)),
	edge((-0.1,0), (-0.4,1), "-o", "wave"), // shifted with fractional coordinates
	edge((0,0), (0,1), "=>", shift: 15pt),  // shifted by a length
)
```)

Alternatively, #the-param[edge][shift] lets you shift edges sideways by an absolute length:
#block(breakable: false, code-example-row(```typ
#diagram($A edge(->, shift: #3pt) edge(<-, shift: #(-3pt)) & B$)
```))

By default, edges which are incident at an angle are automatically adjusted slightly, especially if the node is wide or tall.
Aesthetically, things can look more comfortable if edges don't all connect to the node's exact center, but instead spread out a bit.
Notice the (subtle) difference the figures below.

#align(center, stack(
	dir: ltr,
	spacing: 20%,
	..(([Node with defocus (default)], 0.2), ([No defocus adjustment], 0)).map(((label, d)) => {
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

The strength of this adjustment is controlled by #the-param[node][defocus] or #the-param[diagram][node-defocus].

= Marks and arrows

// Edges can be arrows.
Arrow marks can be specified like  `edge(a, b, "-->")` or with #the-param[edge][marks].
Some mathematical arrow heads are supported, which match $arrow$, $arrow.double$, $arrow.triple$, $arrow.bar$, $arrow.twohead$, and $arrow.hook$ in the default font.

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

A few other marks are provided, and all marks can be placed anywhere along the edge.

#align(center, fletcher.diagram(
	debug: 0,
	spacing: (14mm, 12mm),
{
	for (i, str) in (
		">>-->",
		"||-/-|>",
		"o..O",
		"hook'-x-}>",
		"-*-harpoon"
	).enumerate() {
		let label = raw("\""+str+"\"")
		edge((2*i, 0), (2*i + 1, 0), str, stroke: 0.9pt,
		label: label, label-sep: 1em)
	}
}))

All the built-in marks (see @all-marks) are defined in the state variable `fletcher.MARKS`, which you may access with `context fletcher.MARKS.get()`.
You add or tweak mark styles by modifying `fletcher.MARKS`, as described in @mark-objects.

#context [#figure(
	caption: [Default marks by name. Properties such to size, angle, spacing, or fill can be adjusted.],
	gap: 1em,
	table(
		columns: (1fr,)*6,
		stroke: none,
		..fletcher.MARKS.get().pairs().map(((k, v)) => [
			#set align(center)
			#raw(lang: none, k) \
			#diagram(spacing: 18mm, edge(stroke: 1pt, marks: (v, v)))
		]),
	)
) <all-marks>]


== Custom marks

While shorthands like `"|=>"` exist for specifying marks and stroke styles, finer control is possible.
Marks can be specified by passing an array of _mark objects_ to #the-param[edge][marks].
For example:


#code-example-row(```typ
#diagram(
	edge-stroke: 1.5pt,
	spacing: 25mm,
	edge((0,1), (-0.1,0), bend: -8deg, marks: (
		(inherit: ">>", size: 6, delta: 70deg, sharpness: 65deg),
		(inherit: "head", rev: true, pos: 0.8, sharpness: 0deg, size: 17),
		(inherit: "bar", size: 1, pos: 0.3),
		(inherit: "solid", size: 12, rev: true, stealth: 0.1, fill: red.mix(purple)),
	), stroke: green.darken(50%)),
)
```)


In fact, shorthands like `"|=>"` are expanded with `interpret-marks-arg()` into a form more like the example above.
More precisely, `edge(from, to, "|=>")` is equivalent to:

```typc
context edge(from, to, ..fletcher.interpret-marks-arg("|=>"))
```

If you want to explore the internals of mark objects, you might find it handy to inspect the output of `context fletcher.interpret-marks-arg(..)` with various mark shorthands as input.

=== Mark objects <mark-objects>

A _mark object_ is a dictionary with, at the very least, a `draw` entry containing the CeTZ objects to be drawn.
These CeTZ objects are translated and scaled to fit the edge; the mark's center should be at the origin, and the stroke's thickness is defined as the unit length.
For example, here is a basic circle mark:

#code-example-row(```typ
#import cetz.draw
#let my-mark = (
	draw: draw.circle((0,0), radius: 2, fill: none)
)
#diagram(
	edge((0,0), (1,0), stroke: 1pt, marks: (my-mark, my-mark), bend: 30deg),
	edge((0,1), (1,1), stroke: 3pt + orange, marks: (none, my-mark)),
)
```)

A mark object can contain arbitrary parameters, which may depend on parameters defined earlier by being written as a _function_ of the mark object.
For example, the mark above could also be written as:

```typ
#let my-mark = (
	size: 2,
	draw: mark => draw.circle((0,0), radius: mark.size, fill: none)
)
```

This form makes it easier to change the size without modifying the `draw` function, for example:

#code-example-row(```typ
#import cetz.draw
#let my-mark = (
	size: 2,
	draw: mark => draw.circle((0,0), radius: mark.size, fill: none)
) // setup
#diagram(edge(stroke: 3pt, marks: (my-mark + (size: 4), my-mark)))
```)

Lastly, mark objects may _inherit_ properties from other marks in `fletcher.MARKS` by containing an `inherit` entry, for example:

#code-example-row(```typ
#let my-mark = (
	inherit: "stealth", // base mark on `fletcher.MARKS.stealth`
	fill: red,
	stroke: none,
	extrude: (0, -3),
)
#diagram(edge("rr", stroke: 2pt, marks: (my-mark, my-mark + (fill: blue))))
```)

Internally, marks are passed to `resolve-mark()`, which ensures all entries are evaluated to final values.

=== Special mark properties

A mark object may contain any properties, but some have special functions.

#{
	show table.cell.where(y: 0): emph
	set par(justify: false)
	let little-mark(..args) = diagram(spacing: 5mm, edge(..args, stroke: 0.5pt))

	table(
		columns: 3,
		stroke: (x: none),

		table.header([Name], [Description], [Default]),

		`inherit`,
		[
			The name of a mark in `fletcher.MARKS` to inherit properties from.
			This can be used to make mark aliases, for instance, `"<"` is defined as `(inherit: "head", rev: true)`.
		],
		none,

		`draw`,
		[
			As described above, this contains the final CeTZ objects to be drawn. Objects should be centered at $(0,0)$ and be scaled so that one unit is the stroke thickness.
			The default `stroke` and `fill` is inherited from the edge's style.
		],
		none,

		`pos`,
		[
			Location of the mark along the edge, from `0` (start) to `1` (end).
		],
		`auto`,

		[`fill`\ `stroke`],
		[
			The default fill and stroke styles for CeTZ objects returned by `draw`.
			If `none`, polygons will not be filled/stroked by default, and if `auto`, the style is inherited from the edge's stroke style.
		],
		`auto`,

		`rev`,
		[
			Whether to reverse the mark so it points backwards.

		],
		`false`,

		`flip`,
		[
			Whether to reflect the mark across the edge; the difference between
			#diagram(spacing: 8mm, edge("hook-", stroke: 1pt))
			and
			#diagram(spacing: 8mm, edge("hook'-", stroke: 1pt)), for example.
			A suffix `'` in the name, such as `"hook'"`, results in a flip.
		],
		`false`,

		`scale`,
		[
			Overall scaling factor. See also #the-param[edge][mark-scale].
		],
		`100%`,

		`extrude`,
		[
			Whether to duplicate the mark and draw it offset at each extrude position.
			For example, `(inherit: "head", extrude: (-5, 0, 5))` looks like
			#diagram(spacing: 8mm, edge(marks: (none, (inherit: "head", extrude: (-5, 0, 5))), stroke: .7pt)).

		],
		`(0,)`,

		[`tip-origin`\ `tail-origin`],
		[
			These two properties control the $x$ coordinate of the point of the mark, relative to $(0, 0)$. If the mark is acting as a tip (#little-mark("->") or #little-mark("<-")) then `tip-origin` applies, and `tail-origin` applies when the mark is a tail (#little-mark("-<") or #little-mark(">-")).
			See `mark-debug()`.
		],
		`0`,

		[`tip-end`\ `tail-end`],
		[
			These control the $x$ coordinate at which the edge's stroke terminates, relative to $(0, 0)$.
			See `mark-debug()`.
		],
		`0`,

		`cap-offset`,
		[
			A function `(mark, y) => x` returning the $x$ coordinate at which the edge's stroke terminates relative to `tip-end` or `tail-end`, as a function of the $y$ coordinate.
			This is relevant for #param[edge][extrude]d edges.
			See `cap-offset()`.
		],
		none,

	)
}

The last few properties control the fine behaviours of how marks connect to the target point and to the edge's stroke.
Briefly, a mark has four possibly-distinct center points.
It is easier to show than to tell:

#context grid(
	columns: (1fr, 1fr),
	align: center + horizon,
	fletcher.mark-debug((inherit: "}>", fill: none), show-offsets: false),
	fletcher.mark-demo((inherit: "}>", fill: none)),
)

See `mark-debug()` and `cap-offset()` for details.


=== Detailed example

As a complete example, here is the implementation of a straight arrowhead in ```plain src/default-marks.typ```:

#code-example-row(```typ
#import cetz.draw
#let straight = (
	size: 8,
	sharpness: 20deg,
	tip-origin: mark => 0.5/calc.sin(mark.sharpness),
	tail-origin: mark => -mark.size*calc.cos(mark.sharpness),
	fill: none,
	draw: mark => {
		draw.line(
			(180deg + mark.sharpness, mark.size), // polar cetz coordinate
			(0, 0),
			(180deg - mark.sharpness, mark.size),
		)
	},
	cap-offset: (mark, y) => calc.tan(mark.sharpness + 90deg)*calc.abs(y),
)

#set align(center)
#fletcher.mark-debug(straight)
#fletcher.mark-demo(straight)
```)




== Custom mark shorthands <custom-marks>

While you can pass custom mark objects directly to #the-param[edge][marks], this can get annoying if you use the same mark often.
In these cases, you can define your own mark shorthands.

Mark shorthands such as `"hook->"` search the state variable `fletcher.MARKS` for defined mark names.
#code-example-row(```typ
#context fletcher.MARKS.get().at(">")
```)
With a bit of care, you can modify the `MARKS` state like so:
#code-example-row(```typ
Original marks:
#diagram(spacing: 2cm, edge("<->", stroke: 1pt))

#fletcher.MARKS.update(m => m + (
	"<": (inherit: "stealth", rev: true),
	">": (inherit: "stealth", rev: false),
	"multi": (
		inherit: "straight",
		draw: mark => fletcher.cetz.draw.line(
			(0, +mark.size*calc.sin(mark.sharpness)),
			(-mark.size*calc.cos(mark.sharpness), 0),
			(0, -mark.size*calc.sin(mark.sharpness)),
		),
	),
))

Updated marks:
#diagram(spacing: 2cm, edge("multi->-multi", stroke: 1pt + eastern))
```)

Here, we redefined which mark style the `"<"` and `">"` shorthands refer to, and added an entirely new mark style with the shorthand `"multi"`.

Finally, I will restore the default state so as not to affect the rest of this manual:
#code-example-row(```typ
#fletcher.MARKS.update(fletcher.DEFAULT_MARKS) // restore to built-in mark styles
```)



= CeTZ integration


Fletcher's drawing capabilities are deliberately restricted to a few simple building blocks.
However, an escape hatch is provided with #the-param[diagram][render] so you can intercept diagram data and draw things using CeTZ directly.

== Bézier edges

Here is an example of how you might hack together a Bézier edge using the same functions that `fletcher` uses internally to anchor edges to nodes:

#code-example-row(```typ
#diagram(
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



= Touying integration

You can create incrementally-revealed diagrams in Touying presentation slides by defining the following `touying-reducer`:

#text(.85em, ```typ
#import "@preview/touying:0.2.1": *
#let diagram = touying-reducer.with(reduce: fletcher.diagram, cover: fletcher.hide)
#let (init, slide) = utils.methods(s)
#show: init

#slide[
	Slide with animated figure:
	#diagram(
		node-stroke: .1em,
		node-fill: gradient.radial(blue.lighten(80%), blue,
			center: (30%, 20%), radius: 80%),
		spacing: 4em,
		edge((-1,0), "r", "-|>", `open(path)`, label-pos: 0, label-side: center),
		node((0,0), `reading`, radius: 2em),
		pause,
		edge((0,0), (0,0), `read()`, "--|>", bend: 130deg),
		edge(`read()`, "-|>"),
		node((1,0), `eof`, radius: 2em),
		pause,
		edge(`close()`, "-|>"),
		node((2,0), `closed`, radius: 2em, extrude: (-2.5, 0)),
		edge((0,0), (2,0), `close()`, "-|>", bend: -40deg),
	)
]
```)

#pagebreak(weak: true)

#align(center, text(2em)[*Reference*])
#v(1em)

= Main functions <func-ref>


#show-fns("/src/diagram.typ", only: ("diagram",))
#show-fns("/src/node.typ", only: ("node",))
#show-fns("/src/edge.typ", only: ("edge",))

= Behind the scenes

// == `edge.typ`
// #show-fns("/src/edge.typ", level: 2, outline: true, exclude: "edge")

== `marks.typ`

The default marks are defined in the `fletcher.MARKS` dictionary with keys:
#context fletcher.MARKS.get().keys().map(raw).join(last: [, and ])[, ].

#show-fns("/src/marks.typ", level: 2, outline: true)


== `shapes.typ` <shapes>

To use built-in shapes in a diagram, import them with:

```typ
#import fletcher: shapes
#diagram(node([Hello], stroke: 1pt, shape: shapes.hexagon))
```

or:

```typ
#import fletcher.shapes: hexagon
#diagram(node([Hello], stroke: 1pt, shape: hexagon))
```

To set a shape parameter, use `shape.with(..)`, for example `hexagon.with(angle: 45deg)`.
Shapes respect the #param[node][stroke], #param[node][fill], #param[node][width], #param[node][height], and #param[node][extrude] options of `edge()`.


#show-fns("/src/shapes.typ", level: 2, outline: true)

== `coords.typ`
#show-fns("/src/coords.typ", level: 2, outline: true)

== `diagram.typ`
#show-fns("/src/diagram.typ", level: 2, outline: true, exclude: ("diagram",))

== `node.typ`


#show-fns("/src/node.typ", level: 2, outline: true, exclude: ("node",))

== `edge.typ`
#show-fns("/src/edge.typ", level: 2, outline: true, exclude: ("edge",))

== `draw.typ`
#show-fns("/src/draw.typ", level: 2, outline: true)

== `utils.typ`
#show-fns("/src/utils.typ", level: 2, outline: true)
