#import "/src/exports.typ" as fletcher: diagram, node, edge

#set page(width: 10cm, height: auto)
#show heading.where(level: 1): it => pagebreak(weak: true) + it


#let todo = highlight[TODO!]

#outline()

= Arc edges

#diagram(
	cell-size: 3cm,
	debug: 3,
{
	node((0,0), "from")
	node((1,0), "to")
	for θ in (0deg, 20deg, -50deg) {
		edge((0,0), (1,0), $#θ$, bend: θ, marks: (none, "head"))
	}
})

#diagram(
	node((0,0), $X$),
	node((1,0), $Y$),
	edge((0,0), (1,0), bend: 45deg, marks: ">->"),
)

#for (i, to) in ((0,1), (1,0), (calc.sqrt(1/2),-calc.sqrt(1/2))).enumerate() {
	diagram(debug: 0, {
		node((0,0), $A$)
		node(to, $B$)
		let N = 6
		range(N + 1).map(x => (x/N - 0.5)*2*120deg).map(θ => edge((0,0), to, bend: θ, marks: ">->")).join()
	})
}


= Matching math arrows

Compare to $->$, $=>$, $arrow.triple$, $arrow.twohead$, $arrow.hook$, $|->$.

#let (result-color, target-color) = (rgb("f066"), rgb("0bf5"))

#text(result-color)[Our output] versus #text(target-color)[reference symbol] in default math font. \
#{
	set text(10em)
	diagram(
		spacing: 0.825em,
		crossing-fill: none,
		label-sep: 0.0915em,
		edge-stroke: result-color,
		for (i, a) in (
			("->", $->$,
				0em, 0),
			("=>", $=>$,
				0em, -0.01),
			("==>", $arrow.triple$,
				0em, 0.017),
			("->>", $->>$,
				0em, 0.021),
			("hook->", $arrow.hook$,
				0.005em, 0.006),
			("|->", $|->$,
				0em, -.023),
		).enumerate() {
			let (marks, label, δl, δr) = a
			edge(
				(0, i), (1 + δr,i),
				move(dx: δl - 0.48em, text(target-color, label)),
				marks: marks,
				label-anchor: "west",
				label-pos: 0,
			)
		},
	)
}




= Double and triple lines

#for (i, a) in ("->", "=>", "==>").enumerate() [
	Diagram #diagram(
		node-inset: 2.5pt,
		label-sep: 1pt + i*1pt,
		node((0, -i), $A$),
		edge((0, -i), (1, -i), text(0.6em, $f$), a),
		node((1, -i), $B$),
	) and equation #($A -> B$, $A => B$, $A arrow.triple B$).at(i). \
]

= Arrow head shorthands

$
#for i in (
	"->",
	"<-",
	">-<",
	"<->",
	"<=>",
	"<==>",
	"|->",
	"|=>",
	">->",
	"<<->>",
	">>-<<",
	">>>-}>",
	"hook->",
	"hook'--hook",
	"|=|",
	"||-||",
	"|||-|||",
	"/--\\",
	"\\=\\",
	"/=/",
	"x-X",
	">>-<<",
	"harpoon-harpoon'",
	"harpoon'-<<",
	"<--hook'",
	"|..|",
	"hooks--hooks",
	"o-O",
	"O-o",
	"*-@",
	"o==O",
	"||->>",
	"<|-|>",
	"|>-<|",
	"-|-",
	"hook-/->",
	"<{-}>",
) {
	$ #block(inset: 2pt, fill: white.darken(5%), raw(repr(i)))
	&= #align(center, box(width: 15mm, diagram(edge((0,0), (1,0), marks: i), debug: 0))) \ $
}
$

= Symbol arrow aliases


#table(
	columns: 4,
	align: horizon,
	[Math], [Unicode], [Mark], [Diagram],
	..(
		$->$, $-->$, $<-$, $<->$, $<-->$,
		$->>$, $<<-$,
		$>->$, $<-<$,
		$=>$, $==>$, $<==$, $<=>$, $<==>$,
		$|->$, $|=>$,
		$~>$, $<~$,
		$arrow.hook$, $arrow.hook.l$,
	).map(x => {
		let unicode = x.body.text
		(x, unicode)
		if unicode in fletcher.MARK_SYMBOL_ALIASES {
			let marks = fletcher.MARK_SYMBOL_ALIASES.at(unicode)
			(raw(marks), diagram(edge((0,0), (1,0), marks: marks)))
		} else {
			(text(red)[none!],) * 2
		}
	}).flatten()
)


= Bending arrows

#diagram(
	spacing: (10mm, 5mm),
	for (i, bend) in (0deg, 40deg, 80deg, -90deg).enumerate() {
		let x = 2*i
		(
			(">->->",),
			("<<->>",),
			(">>-<<",),
			(marks: ((kind: "hook", rev: true), "head")),
			(marks: ((kind: "hook", rev: true), "hook'")),
			(marks: ("bar", "bar", "bar")),
			(marks: ("||", "||")),
			(marks: (none, none), extrude: (2.5,0,-2.5)),
			(marks: ("head", "head"), extrude: (1.5,-1.5)),
			(marks: (">", "<"), extrude: (1.5,-1.5)),
			(marks: ("bar", "head"), extrude: (2,0,-2)),
			(marks: ("o", "O")),
			(marks: ((kind: "solid", rev: true), "solid")),
		).enumerate().map(((i, args)) => {
			edge((x, i), (x + 1, i), ..args, bend: bend)
		}).join()

	}
)



= Fine mark angle corrections
#diagram(
	debug: 4,
	spacing: 10mm,
	edge-stroke: 0.8pt,
	for (i, m) in ("<=>", ">==<", ">>->>", "<<-<<", "|>-|>", "<|-<|", "O-|-O", "hook-hook'").enumerate() {
		edge((0,i), (1,i), m)
		edge((2,i), (3,i), m, bend: 90deg)
		edge((4,i), (5,i), m, bend: -30deg)
		edge((6,i), (7,i + 0.5), m, corner: right)
	}
)



= Defocus adjustment

#let around = (
	(-1,+1), ( 0,+1), (+1,+1),
	(-1, 0),          (+1, 0),
	(-1,-1), ( 0,-1), (+1,-1),
)

#grid(
	columns: 2,
	..(-10, -1, -.25, 0, +.25, +1, +10).map(defocus => {
		((7em, 3em), (3em, 7em)).map(((w, h)) => {
			align(center + horizon, diagram(
				node-defocus: defocus,
				node-inset: 0pt,
			{
				node((0,0), rect(width: w, height: h, inset: 0pt, align(center + horizon)[#defocus]))
				for p in around {
					edge(p, (0,0))
				}
			}))
		})
	}).join()
)


= Label side

#diagram(spacing: 1.5cm, {
	for (i, a) in (left, center, right).enumerate() {
		for (j, θ) in (-30deg, 0deg, 50deg).enumerate() {
			edge((2*i, j), (2*i + 1, j), label: a, "->", label-side: a, bend: θ)
		}
	}
})


#diagram(spacing: (3cm, 1cm), {
	for (i, a) in (left, center, right).enumerate() {
		for (j, θ) in (-30deg, 0deg, 50deg).enumerate() {
			edge((j, 2*i), (j, 2*i - 1), label: a, "->", label-side: a, bend: θ)
		}
	}
})


= Automatic label placement
Default placement above the line.

#diagram(
	spacing: 2cm,
	debug: 3,
	axes: (ltr, ttb),
{
	for p in around {
		edge(p, (0,0), $f$)
	}
})

Reversed $y$-axis:

#diagram(
	spacing: 2cm,
	debug: 3,
	axes: (ltr, btt),
{
	for p in around {
		edge(p, (0,0), $f$)
	}
})



= Crossing connectors

#diagram({
	edge((0,1), (1,0))
	edge((0,0), (1,1), "crossing")
	edge((2,1), (3,0), "|-|", bend: -20deg)
	edge((2,0), (3,1), "<=>", crossing: true, bend: 20deg)
})


= `edge()` argument shorthands

#diagram(
	axes: (ltr, btt),
	edge((0,0), (1,1), "->", "double", bend: 45deg),
	edge((1,0), (0,1), "->>", "crossing"),
	edge((1,1), (2,1), $f$, "|->"),
	edge((0,0), (1,0), "-", "dashed"),
)

= `edge()` stroke


$

#block(diagram(
	edge-stroke: red,
	edge(stroke: 2pt),
))
&equiv
#line(stroke: (paint: red, thickness: 2pt, cap: "round"))
\
#block(diagram(
	edge-stroke: 2pt,
	edge(stroke: (cap: "butt"))
))
&equiv
#line(stroke: 2pt)
\
#block(diagram(
	edge-stroke: 1pt + green,
	edge(dash: "dashed")
))
&equiv
#line(stroke: (paint: green, dash: "dashed", cap: "round"))
\
#block(diagram(
	edge(stroke: none)
))
&equiv & "(none)"

$


= Diagram-level options

#diagram(
	node-stroke: gray.darken(50%) + 1pt,
	edge-stroke: green.darken(40%) + .6pt,
	node-fill: green.lighten(80%),
	node-outset: 2pt,
	label-sep: 0pt,
	node((0,1), $A$),
	node((1,0), $sin compose cos compose tan$, fill: none),
	node((2,1), $C$),
	edge("o-o", stroke: orange),
	node((3,1), $D$, shape: "rect"),
	edge((0,1), (1,0), $sigma$, "-}>", bend: -45deg),
	edge((2,1), (1,0), $f$, "<{-"),
)

= CeTZ integration

#diagram(
	node((0,1), $A$, stroke: 1pt),
	node((2,0), [Bézier], stroke: 1pt, shape: fletcher.shapes.diamond),
	render: (grid, nodes, edges, options) => {
		fletcher.cetz.canvas({
			fletcher.draw-diagram(grid, nodes, edges, debug: options.debug)

			let n1 = fletcher.find-node-at(nodes, (0,1))
			let n2 = fletcher.find-node-at(nodes, (2,0))

			let θ1 = 0deg
			let θ2 = -90deg

			fletcher.get-node-anchor(n1, θ1, p1 => {
				fletcher.get-node-anchor(n2, θ2, p2 => {
					let c1 = (rel: (θ1, 30pt), to: p1)
					let c2 = (rel: (θ2, 70pt), to: p2)
					fletcher.cetz.draw.bezier(p1, p2, c1, c2)
					fletcher.draw-arrow-cap(p1, 180deg, (thickness: 1pt, paint: black), "head")
				})
			})

		})
	}
)


= Corner edges

#let around = (
	(-1,+1), (+1,+1),
	(-1,-1), (+1,-1),
)

#for dir in (left, right) {
	pad(1mm, diagram(
		spacing: 1cm,
		node((0,0), [#dir]),
		{
			for c in around {
				node(c, $#c$)
				edge((0,0), c, $f$, marks: (
					(kind: "head", rev: false, pos: 0),
					(kind: "head", rev: false, pos: 0.33),
					(kind: "head", rev: false, pos: 0.66),
					(kind: "head", rev: false, pos: 1),
				), "double", corner: dir)
			}
		}
	))
}

#for dir in (left, right) {
	pad(1mm, diagram(
		// debug: 4,
		spacing: 1cm,
		axes: (ltr, btt),
		node((0,0), [#dir]),
		{
			for c in around {
				node(c, $#c$)
				edge((0,0), c, $f$, marks: (
					(kind: "head", rev: false, pos: 0),
					(kind: "head", rev: false, pos: 0.33),
					(kind: "head", rev: false, pos: 0.66),
					(kind: "head", rev: false, pos: 1),
				), "double", corner: dir)
			}
		}
	))
}


= Double node strokes

#diagram(
  node-outset: 4pt,
  spacing: (15mm, 8mm),
  node-stroke: black + 0.5pt,
  node((0, 0), $s_1$, ),
  node((1, 0), $s_2$, extrude: (-1.5, 1.5), fill: blue.lighten(70%)),
  edge((0, 0), (1, 0), "->", label: $a$, bend: 20deg),
  edge((0, 0), (0, 0), "->", label: $b$, bend: 120deg),
  edge((1, 0), (0, 0), "->", label: $b$, bend: 20deg),
  edge((1, 0), (1, 0), "->", label: $a$, bend: 120deg),
  edge((1,0), (2,0), "->>"),
  node((2,0), $s_3$, extrude: (+1, -1), stroke: 1pt, fill: red.lighten(70%)),
)

#diagram(
	node((0,0), `outer`, stroke: 1pt, extrude: (-1, +1), fill: green),
	node((1,0), `inner`, stroke: 1pt, extrude: (+1, -1), fill: green),
	node((2,0), `middle`, stroke: 1pt, extrude: (0, +2, -2), fill: green),
)

Relative and absolute extrusion lengths

#diagram(
	node((0,0), `outer`, stroke: 1pt, extrude: (-1mm, 0pt), fill: green),
	node((1,0), `inner`, stroke: 1pt, extrude: (0, +.5em, -2pt), fill: green),
)

= Custom node sizes

Make sure provided dimensions are exact, not affected by node `inset`.

#circle(radius: 1cm, align(center + horizon, `1cm`))

#diagram(
	node((0,0), `1cm`, stroke: 1pt, radius: 1cm, inset: 1cm, shape: "circle"),
	node((0,1), [width], stroke: 1pt, width: 2cm),
	node((1,1), [height], stroke: 1pt, height: 4em, inset: 0pt),
	node((2,1), [both], width: 1em, height: 1em, fill: blue),
)


= Node inset and outset

#let cm-square = box(width: 5mm, height: 5mm, fill: black)

What `5mm` inset should look like:

#rect(fill: green, inset: 5mm, cm-square)

A diagram node with `5mm` inset:

#diagram(node((0,0), cm-square, shape: rect, inset: 5mm, fill: green))

A diagram node with `5mm` outset:

#diagram(
	debug: 2,
	spacing: 1cm,
	node((0,0), cm-square, shape: rect, inset: 0pt, outset: 5mm, fill: blue),
	edge("->"),
)

Circular insets:

#diagram(
	node-stroke: 1pt,
	node((0,0), $A$, inset: 0pt, shape: rect),
	node((1,0), $A$, inset: 0pt),
	node((0,1), $A$, shape: rect),
	node((1,1), $A$),
	node((0,2), $A B C D E$, shape: rect),
	node((1,2), $A B C D E$, shape: circle),
)


= Example

#[
Make sure node or edge labels don't pick up equation numbers!
#set math.equation(numbering: "(1)")

$ a^2 $

#{
	set text(size: 0.65em)
	diagram(
	  node-stroke: .1em,
	  node-inset: .2em,
	  node-fill: gradient.radial(white, blue.lighten(40%), center: (30%, 20%), radius: 130%),
	  edge-stroke: .06em,
	  spacing: 5em,
	  mark-scale: 120%,
	  node((0,0), `reading`, radius: 2em, shape: "circle"),
	  node((1,0), `eof`, radius: 2em, shape: "circle"),
	  node((2,0), `closed`, radius: 2em, shape: "circle", extrude: (-2, 0)),
	  node((-.7,0), `open(path)`, stroke: none, fill: none),
	  edge((-.7,0), (0,0), "-|>"),
	  edge((0,0), (1,0), `read()`, "-|>"),
	  edge((0,0), (0,0), `read()`, "-|>", bend: 130deg),
	  edge((1,0), (2,0), `close()`, "-|>"),
	  edge((0,0), (2,0), `close()`, "-|>", bend: -40deg),
	)
}

$ b^2 $
]

= Axes configuration

#for axes in ((ltr, btt), (ltr, ttb), (rtl, btt), (rtl, ttb)) {	
	for axes in (axes, axes.rev()) {
		diagram(
			axes: axes,
			debug: 1,
			node((0,0), $(0,0)$),
			edge((0,0), (1,0), "hook->"),
			node((1,0), $(1,0)$),
			node((1,1), $(1,1)$),
			node((0.5,0.5), raw(repr(axes))),
		)
	}
}

= Implicit `from` and `to` points

#diagram(edge((0,0), (1,0), [label], "->"))
#diagram(edge((1,0), [label], "->"))
#diagram(edge([label], "->"))

#diagram(
	node((1,2), [prev]),
	edge("->", bend: 45deg),
	node((2,1), [next]),
	edge((1,2), ".."),
)


= Edge positional arguments

Explicit named arguments versus implicit positional arguments.

Each row should be the same thing repeated.

#let ab = node((0,0), $A$) + node((1,0), $B$)
#grid(
	columns: (1fr,)*3,

	diagram(ab, edge((0,0), (1,0), marks: "->")),
	diagram(ab, edge((0,0), (1,0), "->")),
	diagram($A edge(->) & B$),

	diagram(ab, edge((0,0), (1,0), label: $pi$)),
	diagram(ab, edge((0,0), (1,0), $pi$)),
	diagram($A edge(pi) & B$),

	diagram(ab, edge((0,0), (1,0), marks: "|->", label: $tau$)),
	diagram(ab, edge((0,0), (1,0), "|->", $tau$)),
	diagram($A edge(tau, |->) & B$),

	diagram(ab, edge((0,0), (1,0), marks: "->>", label: $+$)),
	diagram(ab, edge((0,0), (1,0), "->>", $+$)),
	diagram($A edge(->>, +) & B$),
)




= Math-mode diagrams

The following diagrams should be identical:

#diagram($
	G edge(f, ->) edge(#(0,1), pi, ->>) & im(f) \
	G slash ker(f) edge(#(1,0), tilde(f), "hook-->")
$)

#diagram(
	node((0,0), $G$),
	edge((0,0), (1,0), $f$, "->"),
	edge((0,0), (0,1), $pi$, "->>"),
	node((1,0), $im(f)$),
	node((0,1), $G slash ker(f)$),
	edge((0,1), (1,0), $tilde(f)$, "hook-->")
)

= Nodes in math-mode

#diagram(
	node-outset: 2pt,
	node-corner-radius: 2pt,
	$
		A edge(->) & node(sqrt(B), fill: #blue.lighten(70%), inset: #5pt) \
		node(C, stroke: #(red + .3pt), radius: #1em) edge("u", "=")
		edge(#(1,0), "..||..")
	$,
)

#diagram(
	node-stroke: 1pt,
	$ node(A B C, extrude: #(0,2)) edge(->) & pi r^2 $
)

= Relative node coordinates

#diagram($
	G edge(->, f) edge("d", ->>, pi) & im(f) \
	G slash ker(f) edge("ne", "hook-->", tilde(f))
$)

$
#block(diagram($
	(0,0) edge(#(0,1), #(rel: (0, -1)), ->) & // first non-relative coordinate becomes `from`...
	(1,0) edge(#(0,1), "=>") \ // ...unless it is the only coordinate, in which case it becomes `to`
	(0,1) edge(#(0,0), "dr", "..>") &
	(1,1) edge("u", "-->") // if a single relative coordinate is given, set `from: auto`
$))
equiv
#block(diagram(
	node((0,0), $(0,0)$),
	node((1,0), $(1,0)$),
	node((0,1), $(0,1)$),
	node((1,1), $(1,1)$),

	edge((0,1), (0,0), "->"),
	edge((1,0), (0,1), "=>"),
	edge((0,0), (1,1), "..>"),
	edge((1,1), (1,0), "-->"),
))
$

= Edge paths


#for radius in (none, 0pt, 10pt) {
	diagram(
		// debug: 4,
		mark-scale: 150%,
		node((0,0), $A$),
		edge(">->", vertices: (
			(0,0),
			(1.1,0),
			(1,1),
			(3,2),
			(4,1),
			(1.3,2),
			(2,0),
			(3,0),
			(2,1),
		), kind: "poly",
			corner-radius: radius,
			extrude: (4, 0, -4)
		),
		node((2,1), $B$),
	)
}

#diagram(debug: 4, spacing: (2cm, 1cm), $
	A edge("u,r,rdd,l,u", ->>) & B edge("dl,r,ul", "=")
$)


= Dashed edge paths

#for dash in ("dashed", "loosely-dashed", "dotted") {
	diagram(
		edge(
			"r,ddd,r,u,ll,u,rr",
			"<->",
			corner-radius: 5mm,
			stroke: (dash: dash)
		)
	)
}

= Custom node shapes

#diagram(
	debug: 3,
	node-stroke: 1pt,
	node-outset: 5pt,
	axes: (ltr, ttb),
	node((0,0), `a1`, radius: 5mm),
	edge("->"),
	node((1,1), [crowded], shape: fletcher.shapes.house, fill: blue.lighten(90%)),
	edge("..>", bend: 30deg),
	node((0,2), `a3`, shape: fletcher.shapes.diamond),
	edge((0,0), "d,ru,d", "=>"),

	edge((1,1), "rd", bend: -40deg),
	node((2,2), `cool`, shape: fletcher.shapes.pill),
	edge("->"),
	node((1,3), [_amazing_], shape: fletcher.shapes.parallelogram),

	node((2,0), [Ratio?], shape: fletcher.shapes.hexagon)




)


= Intersection finding

#fletcher.cetz.canvas({
	import fletcher.cetz.draw
	let target = (2cm,0cm)
	let obj = draw.circle((0cm,0cm))
	let line = draw.line((-1cm,1cm), target)
	line
	obj
	draw.content(target, `target`)

	fletcher.find-farthest-intersection(obj + line, target, pt => {
		draw.content(pt, text(red, `farthest`))
	})
})

= Off-center edges

#diagram(debug: 3, {
	node((0,0), $A$)
	node((1,0), $B$)
	for y in (.1, 0, -.1) {
		edge((0,y), "r", "->")
	}
	node((0,1), `a wide node`, stroke: .1pt)
	node((1,2), $C$)
	edge((0,1), (1,2), "->", bend: 35deg)
	edge((0.2,1), (1,2), "->>", corner: left)
	edge((0,1), "d", (rel: (-.4,0)), "u", "=>")

})



= Edge shift

#diagram(
	node((0,0), $A$),
	edge((0,0), (1,0), "->", shift: +3.4pt),
	edge((0,0), (1,0), "<-", shift: -3.4pt),
	node((1,0), $B$),
)

#diagram(
	node((0,0), $A$),
	edge((0,0), (1,0), "->", shift: +3.4pt, bend: 40deg),
	edge((0,0), (1,0), "<-", shift: -3.4pt, bend: 40deg),
	node((1,0), $B$),
)

#diagram(
	node-stroke: 1pt,
	node((0,0), $A$),
	edge((0,0), (1,0), (1,1), "->", shift: +4pt),
	edge((0,0), (1,0), (1,1), "->", shift: -4pt),
	edge((0,0), (1,1), "->", corner: left, shift: +4pt),
	edge((0,0), (1,1), "->", corner: left, shift: -4pt),
	node((1,1), $B C$),
)


= Label fill

#diagram(
	crossing-fill: luma(90%),
	edge((0,0), (1,1), "->", [hi], label-side: right),
	edge((1,0), (2,1), "->", [hi], label-side: center),
	edge((2,0), (3,1), "->", [hi], label-fill: true),
)
#diagram(
	crossing-fill: luma(90%),
	edge((0,0), (1,1), "->", [hi], label-side: right, label-fill: blue),
	edge((1,0), (2,1), "->", [hi], label-side: center, label-fill: false),
	edge((2,0), (3,1), "->", [hi]),
)

= Line decorations

#diagram(spacing: 4em, $
	A edge(<->, "wave") & B edge(<->, "zigzag") & C edge(<->, "coil")
$)

#diagram(spacing: (2em, 3em), $
	e^- edge("dr", "-<|-") & & & & & edge("dl", "-|>-") e^+ \
	& edge("wave") & edge(gamma, "wave", bend: #80deg) edge("wave", bend: #(-80deg)) & edge("wave") \
	e^+ edge("ur", "-|>-") & & & & & edge("ul", "-<|-") e^- \
$)


#diagram(spacing: (1cm, 0cm), $
	A edge(~>) & B \
	A edge(<~) & B \
	A edge("<~>") & B \
	A edge(">~<") & B \
$)