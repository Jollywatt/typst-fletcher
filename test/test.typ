#import "@preview/cetz:0.1.2"
#import "/src/exports.typ" as fletcher: node, edge


#set page(width: 10cm, height: auto)
#show heading.where(level: 1): it => pagebreak(weak: true) + it

= Arrow heads
Compare to symbols $#sym.arrow$, $#sym.arrow.twohead$, $#sym.arrow.hook$, $#sym.arrow.bar$

#fletcher.diagram(
	// debug: 1,
	spacing: (10mm, 5mm),
{
	for i in (0, 1, 2) {
		let x = 2*i
		let bend = 40deg*i
		(
			(marks: ("harpoon", "harpoon'")),
			(marks: ("head", "head")),
			(marks: ("tail", "tail")),
			(marks: ("twotail", "twohead")),
			(marks: ("twohead", "twotail")),
			(marks: ("hook", "head")),
			(marks: ("hook", "hook'")),
			(marks: ("bar", "bar")),
			(marks: ("twobar", "twobar")),
			(marks: (none, none), extrude: (2.5,0,-2.5)),
			(marks: ("head", "head"), extrude: (1.5,-1.5)),
			(marks: ("tail", "tail"), extrude: (1.5,-1.5)),
			(marks: ("bar", "head"), extrude: (2,0,-2)),
			(marks: ("twotail", "twohead"), extrude: (1.5,-1.5)),
			(marks: ("circle", "bigcircle")),
			(marks: ("circle", "bigcircle"), extrude: (1.5, -1.5)),
			(marks: ("solidtail", "solidhead")),
		).enumerate().map(((i, args)) => {
			edge((x, -i), (x + 1, -i), ..args, bend: bend)
		}).join()

	}

})

= Symbol matching

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
			paint: rgb("f006"),
			label-side: center,
		),
	)
	fletcher.diagram(
		spacing: 0.835em,
		crossing-fill: none,
		edge(
			(0,0), (1,0),
			text(rgb("0ff5"), $->>$),
			"->>",
			paint: rgb("f006"),
			label-side: center,
		),
	)
	fletcher.diagram(
		spacing: 0.815em,
		crossing-fill: none,
		edge(
			(0,0), (1,0),
			text(rgb("0ff5"), $arrow.hook$),
			"hook->",
			paint: rgb("f006"),
			label-side: right,
			label-sep: -0.0195em,
			label-anchor: "center",
		),
	)

	fletcher.diagram(
		spacing: 0.8em,
		crossing-fill: none,
		edge(
			(0,0), (1,0),
			text(rgb("0ff5"), $=>$),
			"=>",
			paint: rgb("f006"),
			label-side: center,
		),
	)

	fletcher.diagram(
		spacing: 0.83em,
		crossing-fill: none,
		edge(
			(0,0), (1,0),
			text(rgb("0ff5"), $arrow.triple$),
			"==>",
			paint: rgb("f006"),
			label-side: center,
		),
	)
}

$A -> B$, 
#fletcher.diagram(
	edge-thickness: 0.53pt,
	node-inset: 5pt,
	label-sep: 1pt,
	// spacing: 25pt,
	node((0,0), $A$), edge((0,0), (1,0), "->"), node((1,0), $B$)
)

$A => B$, 
#fletcher.diagram(
	edge-thickness: 0.53pt,
	node-inset: 5pt,
	label-sep: 2pt,
	// spacing: 25pt,
	node((0,0), $A$), edge((0,0), (1,0), "=>"), node((1,0), $B$)
)

$A arrow.triple B$, 
#fletcher.diagram(
	edge-thickness: 0.53pt,
	node-inset: 5pt,
	label-sep: 3pt,
	// spacing: 25pt,
	node((0,0), $A$), edge((0,0), (1,0), "==>"), node((1,0), $B$)
)


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

#import "/src/main.typ": parse-arrow-shorthand

$
#for i in (
	"->",
	"<-",
	"<->",
	"<=>",
	"<==>",
	"|->",
	"|=>",
	">->",
	"->>",
	"hook->",
	"hook'--hook",
	"|=|",
	">>-<<",
	"harpoon-harpoon'",
	"harpoon'-<<",
	"<--hook'",
	"|..|",
	"hooks--hooks",
	"o-O",
	"o==O",
	"||->>",
	"<|-|>",
	"|>-<|",
) {
	$ #block(inset: 2pt, fill: white.darken(5%), raw(i))
	&= #fletcher.diagram(edge((0,0), (1,0), i)) \ $
}
$

= Connectors


#fletcher.diagram(
	debug: 0,
	cell-size: (10mm, 10mm),
	node((0,1), $X$),
	node((1,1), $Y$),
	node((0,0), $Z$),
	edge((0,1), (1,1), marks: (none, "head")),
	edge((0,0), (1,1), $f$, marks: ("hook", "head"), dash: "dashed"),
	edge((0,1), (0,0), marks: (none, "twohead")),
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
	edge((0,0), (1,0), bend: 45deg, marks: ("head", "head")),
)

#for (i, to) in ((0,1), (1,0), (calc.sqrt(1/2),-calc.sqrt(1/2))).enumerate() {
	fletcher.diagram(debug: 0, {
		node((0,0), $A$)
		node(to, $B$)
		let N = 6
		range(N + 1).map(x => (x/N - 0.5)*2*120deg).map(θ => edge((0,0), to, bend: θ, marks: ("tail", "head"))).join()
	})
}

= Defocus

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
	edge((0,0), (1,1), crossing: true)
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
		// debug: 2,
		spacing: 1cm,
		node((0,0), [#dir]),
		{
			for c in around {
				node(c, $#c$)
				edge((0,0), c, $f$, "O=>", corner: dir, label-pos: 0.4)
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