#import "@preview/cetz:0.1.2"
#import "/src/exports.typ" as fletcher: node, edge


#set page(width: 10cm, height: auto)
#show heading.where(level: 1): it => pagebreak(weak: true) + it




= Connectors


#fletcher.diagram(
	debug: 0,
	cell-size: (10mm, 10mm),
	node((0,1), $X$),
	node((1,1), $Y$),
	node((0,0), $Z$),
	edge((0,1), (1,1), marks: (none, "head")),
	edge((0,0), (1,1), $f$, marks: ("hook", "head"), dash: "dashed"),
	edge((0,1), (0,0), marks: (none, ">>")),
	edge((0,1), (0,1), marks: (none, "head"), bend: -120deg),
)

= Arc connectors

#fletcher.diagram(
	cell-size: 3cm,
{
	node((0,0), "from")
	node((1,0), "to")
	for θ in (0deg, 20deg, -50deg) {
		edge((0,0), (1,0), $#θ$, bend: θ, marks: (none, "head"))
	}
})

#fletcher.diagram(
	debug: 3,
	node((0,0), $X$),
	node((1,0), $Y$),
	edge((0,0), (1,0), bend: 45deg, marks: ">->"),
)

#for (i, to) in ((0,1), (1,0), (calc.sqrt(1/2),-calc.sqrt(1/2))).enumerate() {
	fletcher.diagram(debug: 0, {
		node((0,0), $A$)
		node(to, $B$)
		let N = 6
		range(N + 1).map(x => (x/N - 0.5)*2*120deg).map(θ => edge((0,0), to, bend: θ, marks: ">->")).join()
	})
}



= Matching math arrows

Compare to $->$, $=>$ $arrow.triple$ $arrow.twohead$, $arrow.hook$, $|->$.

Red is our output; cyan is reference symbol in default math font.
#{
	set text(10em)

	fletcher.diagram(
		spacing: 0.815em,
		crossing-fill: none,
		edge(
			(0,0), (1,0),
			text(rgb("0ff5"), $->$),
			"->",
			stroke: rgb("f006"),
			label-anchor: "center",
			label-sep: 0.0915em,
		),
	)
	fletcher.diagram(
		spacing: 0.8em,
		crossing-fill: none,
		edge(
			(0,0), (1,0),
			text(rgb("0ff5"), $=>$),
			"=>",
			stroke: rgb("f006"),
			label-anchor: "center",
			label-sep: 0.0915em,
		),
	)
	fletcher.diagram(
		spacing: 0.83em,
		crossing-fill: none,
		edge(
			(0,0), (1,0),
			text(rgb("0ff5"), $arrow.triple$),
			"==>",
			stroke: rgb("f006"),
			label-anchor: "center",
			label-sep: 0.0915em,
		),
	)
	fletcher.diagram(
		spacing: 0.835em,
		crossing-fill: none,
		edge(
			(0,0), (1,0),
			text(rgb("0ff5"), $->>$),
			"->>",
			stroke: rgb("f006"),
			label-anchor: "center",
			label-sep: 0.0915em,
		),
	)
	fletcher.diagram(
		spacing: 0.83em,
		crossing-fill: none,
		edge(
			(0,0), (1,0),
			text(rgb("0ff5"), $arrow.hook$),
			"hook->",
			stroke: rgb("f006"),
			label-side: right,
			label-anchor: "center",
			label-sep: 0.0915em,
			label-pos: 0.51,
		),
	)
	fletcher.diagram(
		spacing: 0.807em,
		crossing-fill: none,
		edge(
			(0,0), (1,0),
			text(rgb("0ff5"), $|->$),
			"|->",
			stroke: rgb("f006"),
			label-anchor: "center",
			label-sep: 0.0915em,
			label-pos: 0.506,
		),
	)

}



= Double and triple lines

#for (i, a) in ("->", "=>", "==>").enumerate() [
	Diagram #fletcher.diagram(
		// node-inset: 5pt,
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
	">>>-stealth",
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
	"stealth-stealth",
) {
	$ #block(inset: 2pt, fill: white.darken(5%), raw(repr(i)))
	&= #align(center, box(width: 15mm, fletcher.diagram(edge((0,0), (1,0), marks: i), debug: 0))) \ $
}
$

= Bending arrows

#fletcher.diagram(
	debug: 4,
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
			(marks: ((kind: "solidhead", rev: true), "solidhead")),
		).enumerate().map(((i, args)) => {
			edge((x, -i), (x + 1, -i), ..args, bend: bend)
		}).join()

	}
)


= Fine mark angle corrections
#fletcher.diagram(
	debug: 4,
	spacing: 10mm,
	edge-thickness: 0.8pt,
	for (i, m) in ("<=>", ">==<", ">>->>", "<<-<<", "|>-|>", "<|-<|", "O-|-O", "hook-hook'").enumerate() {
		edge((0,-i), (1,-i), m)
		edge((2,-i), (3,-i), m, bend: 90deg)
		edge((4,-i), (5,-i), m, bend: -30deg)
		edge((6,-i), (7,-i - 0.5), m, corner: left)
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
			align(center + horizon, fletcher.diagram(
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

= Label placement
Default placement above the line.

#fletcher.diagram(
	// cell-size: (2.2cm, 2cm),
	spacing: 2cm,
	debug: 3,
{
	for p in around {
		edge(p, (0,0), $f$)
	}
})

#fletcher.diagram(spacing: 1.5cm, {
	for (i, a) in (left, center, right).enumerate() {
		for (j, θ) in (-30deg, 0deg, 50deg).enumerate() {
			edge((2*i, j), (2*i + 1, j), label: a, "->", label-side: a, bend: θ)
		}
	}
})


= Crossing connectors

#fletcher.diagram({
	edge((0,1), (1,0))
	edge((0,0), (1,1), "crossing")
	edge((2,1), (3,0), "|-|", bend: -20deg)
	edge((2,0), (3,1), "<=>", crossing: true, bend: 20deg)
})


= `edge()` argument shorthands

#fletcher.diagram(
	edge((0,0), (1,1), "->", "double", bend: 45deg),
	edge((1,0), (0,1), "->>", "crossing"),
	edge((1,1), (2,1), $f$, "|->"),
	edge((0,0), (1,0), "-", "dashed"),
)


= Diagram-level options

#fletcher.diagram(
	node-stroke: black,
	node-fill: green.lighten(80%),
	label-sep: 0pt,
	node((0,0), $A$),
	node((1,1), $sin compose cos compose tan$, fill: none),
	node((2,0), $C$),
	node((3,0), $D$, shape: "rect"),
	edge((0,0), (1,1), $sigma$, "-|>", bend: -45deg),
	edge((2,0), (1,1), $f$, "<|-"),
)

= CeTZ integration

#import "/src/utils.typ": vector-polar
#fletcher.diagram(
	node((0,0), $A$, stroke: 1pt),
	node((2,1), [Bézier], stroke: 1pt),
	render: (grid, nodes, edges, options) => {
		cetz.canvas({
			fletcher.draw-diagram(grid, nodes, edges, options)

			let n1 = fletcher.find-node-at(nodes, (0,0))
			let p1 = fletcher.get-node-anchor(n1, 0deg)

			let n2 = fletcher.find-node-at(nodes, (2,1))
			let p2 = fletcher.get-node-anchor(n2, -90deg)

			let c1 = cetz.vector.add(p1, vector-polar(20pt, 0deg))
			let c2 = cetz.vector.add(p2, vector-polar(70pt, -90deg))

			fletcher.draw-arrow-cap(p1, 180deg, (thickness: 1pt, paint: black), "head")

			cetz.draw.bezier(p1, p2, c1, c2)
		})
	}
)

= Node bounds

#fletcher.diagram(
	debug: 2,
	node-outset: 5pt,
	node-inset: 5pt,
	node((0,0), `hello`, stroke: 1pt),
	node((1,0), `there`, stroke: 1pt),
	edge((0,0), (1,0), "<=>"),
)


= Corner edges

#let around = (
	(-1,+1), (+1,+1),
	(-1,-1), (+1,-1),
)

#for dir in (left, right) {
	pad(1mm, fletcher.diagram(
		// debug: 4,
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

= Double node strokes

#fletcher.diagram(
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

#fletcher.diagram(
	node((0,0), `outer`, stroke: 1pt, extrude: (-1, +1), fill: green),
	node((1,0), `inner`, stroke: 1pt, extrude: (+1, -1), fill: green),
	node((2,0), `middle`, stroke: 1pt, extrude: (0, +2, -2), fill: green),
)

Relative and absolute extrusion lengths

#fletcher.diagram(
	node((0,0), `outer`, stroke: 1pt, extrude: (-1mm, 0pt), fill: green),
	node((1,0), `inner`, stroke: 1pt, extrude: (0, +.5em, -2pt), fill: green),
)

= Custom node sizes

Make sure provided dimensions are exact, not affected by node `inset`.

#circle(radius: 1cm, align(center + horizon, `1cm`))

#fletcher.diagram(
	node((0,1), `1cm`, stroke: 1pt, radius: 1cm, inset: 1cm, shape: "circle"),
	node((0,0), [width], stroke: 1pt, width: 2cm),
	node((1,0), [height], stroke: 1pt, height: 4em, inset: 0pt),
	node((2,0), [both], width: 1em, height: 1em, fill: blue),
)


= Example

#[
Make sure node or edge labels don't pick up equation numbers!
#set math.equation(numbering: "(1)")

$ a^2 $

#{
	set text(size: 0.65em)
	fletcher.diagram(
	  node-stroke: .1em,
	  node-inset: .2em,
	  node-fill: gradient.radial(white, blue.lighten(40%), center: (30%, 20%), radius: 130%),
	  edge-thickness: .06em,
	  spacing: 7em,
	  mark-scale: 120%,
	  node((0,0), `reading`, radius: 2em, shape: "circle"),
	  node((1,0), `eof`, radius: 2em, shape: "circle"),
	  node((2,0), `closed`, radius: 2em, shape: "circle", extrude: (-2, 0)),
	  node((-.7,0), `open(path)`, stroke: none, fill: none),
	  edge((-.7,0), (0,0), "-|>"),
	  edge((0,0), (1,0), `read()`, "-|>"),
	  edge((0,0), (0,0), `read()`, "<|-", bend: -130deg),
	  edge((1,0), (2,0), `close()`, "-|>"),
	  edge((0,0), (2,0), `close()`, "-|>", bend: -40deg),
	)
}

$ b^2 $
]

= Funky axes

#for axes in ((ltr, btt), (ltr, ttb), (rtl, btt), (rtl, ttb)) {	
	for axes in (axes, axes.rev()) {
		fletcher.diagram(
			axes: axes,
			debug: 1,
			node((0,0), $(0,0)$),
			edge((0,0), (1,0), "->", bend: 20deg),
			node((1,0), $(1,0)$),
			node((1,1), $(1,1)$),
			node((0.5,0.5), repr(axes)),
		)
	}
}


= ?

#fletcher.interpret-mark("*")

#fletcher.diagram(edge((0,0), (1,0), marks: "-*-*"))

#let edge(..options) = metadata((kind: "edge", options: options))

#let eq = $
G edge("r", ->, f) edge("d", ->>, pi) & im(f) \
G slash ker(f) edge("ur", ->, tilde(f))
$

#eq.body.children