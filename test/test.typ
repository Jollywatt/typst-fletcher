#import "@preview/cetz:0.1.2"
#import "/src/exports.typ": *
#import "/src/marks.typ": *


#set page(width: 10cm, height: auto)
#show heading.where(level: 1): it => pagebreak(weak: true) + it

= Arrow heads
Compare to symbols $#sym.arrow$, $#sym.arrow.twohead$, $#sym.arrow.hook$, $#sym.arrow.bar$

#arrow-diagram(
	debug: 0,
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
			(marks: ("hook", "head")),
			(marks: ("hook", "hook'")),
			(marks: ("bar", "bar")),
			(marks: (none, none), extrude: (2.5,0,-2.5)),
			(marks: ("head", "head"), extrude: (1.5,-1.5)),
			(marks: ("tail", "tail"), extrude: (1.5,-1.5)),
			(marks: ("bar", "head"), extrude: (2,0,-2)),
			(marks: ("twotail", "twohead"), extrude: (1.5,-1.5)),
		).enumerate().map(((i, args)) => {
			conn((x, -i), (x + 1, -i), ..args, bend: bend)
		}).join()

	}

})

= Arrow head shorthands

$
#for i in (
	"->",
	"<-",
	"<->",
	"<=>",
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
) {
	$ #block(inset: 2pt, fill: white.darken(5%), raw(i))
	&= #arrow-diagram(conn((0,0), (1,0), ..parse-arrow-shorthand(i))) \ $
}
$

= Connectors


#arrow-diagram(
	debug: 0,
	cell-size: (10mm, 10mm),
	node((0,1), $X$),
	node((1,1), $Y$),
	node((0,0), $Z$),
	conn((0,1), (1,1), marks: (none, "head")),
	conn((0,0), (1,1), $f$, marks: ("hook", "head"), dash: "dashed"),
	conn((0,1), (0,0), marks: (none, "twohead")),
	conn((0,1), (0,1), marks: (none, "head"), bend: -120deg),
)

= Arc connectors

#arrow-diagram(
	cell-size: 3cm,
{
	node((0,0), "from")
	node((1,0), "to")
	for θ in (0deg, 20deg, -50deg) {
		conn((0,0), (1,0), $#θ$, bend: θ, marks: (none, "head"))
	}
})

#arrow-diagram(
	debug: 3,
	node((0,0), $X$),
	node((1,0), $Y$),
	conn((0,0), (1,0), bend: 45deg, marks: ("head", "head")),
)

#for (i, to) in ((0,1), (1,0), (calc.sqrt(1/2),-calc.sqrt(1/2))).enumerate() {
	arrow-diagram(debug: 0, {
		node((0,0), $A$)
		node(to, $B$)
		let N = 6
		range(N + 1).map(x => (x/N - 0.5)*2*120deg).map(θ => conn((0,0), to, bend: θ, marks: ("tail", "head"))).join()
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
			align(center + horizon, arrow-diagram(
				node-defocus: defocus,
				node-pad: 0pt,
			{
				node((0,0), rect(width: w, height: h, inset: 0pt, align(center + horizon)[#defocus]))
				for p in around {
					conn(p, (0,0))
				}
			}))
		})
	}).join()
)

= Label placement
Default placement above the line.

#arrow-diagram(
	// cell-size: (2.2cm, 2cm),
	spacing: 2cm,
	debug: 3,
{
	for p in around {
		conn(p, (0,0), $f$)
	}
})

#arrow-diagram(spacing: 1.5cm, {
	for (i, a) in (left, center, right).enumerate() {
		for (j, θ) in (-30deg, 0deg, 50deg).enumerate() {
			conn((2*i, j), (2*i + 1, j), label: a, "->", label-side: a, bend: θ)
		}
	}
})


= Crossing connectors

#arrow-diagram({
	conn((0,1), (1,0))
	conn((0,0), (1,1), crossing: true)
	conn((2,1), (3,0), "|-|", bend: -20deg)
	conn((2,0), (3,1), "<=>", crossing: true, bend: 20deg)
})

= Coord callback

// #arrow-diagram({
// 	node((1,1), "hi")
// 	conn((1,1), (1,2))
// 	resolve-coords((1, 2), (1,1), callback: (p1, p2) => {
// 		cetz.draw.circle(p1, radius: 5pt, stroke: red)
// 	})
// })

= `conn()` argument shorthands

#arrow-diagram(
	conn((0,0), (1,1), "->", "double", bend: 45deg),
	conn((1,0), (0,1), "->>", "crossing"),
	conn((1,1), (2,1), $f$, "|->"),
	conn((0,0), (1,0), "-", "dashed"),
)


= Diagram-level options

#arrow-diagram(
	node-stroke: black,
	node-fill: green.lighten(80%),
	node((0,0), $A$),
	node((1,1), $sin compose cos compose tan$, fill: none),
	node((2,0), $C$),
	node((3,0), $D$, shape: "rect"),
	conn((0,0), (1,1), "->", bend: -45deg),
	conn((2,0), (1,1), "<-"),
)

= CeTZ integration

#arrow-diagram(
	node((0,0), $A$, stroke: 1pt),
	node((2,1), [Bézier], stroke: 1pt),
	render: (grid, nodes, conns, options) => {
		cetz.canvas({
			arrow-diagrams.draw-diagram(grid, nodes, conns, options)

			let n1 = arrow-diagrams.find-node-at(nodes, (0,0))
			let p1 = arrow-diagrams.get-node-anchor(n1, 0deg)

			let n2 = arrow-diagrams.find-node-at(nodes, (2,1))
			let p2 = arrow-diagrams.get-node-anchor(n2, -90deg)

			let c1 = cetz.vector.add(p1, vector-polar(20pt, 0deg))
			let c2 = cetz.vector.add(p2, vector-polar(70pt, -90deg))

			arrow-diagrams.draw-arrow-cap(p1, 180deg, (thickness: 1pt, paint: black), "head")

			cetz.draw.bezier(p1, p2, c1, c2)
		})
	}
)

= Node bounds

#arrow-diagram(
	debug: 2,
	node-outset: 5pt,
	node-pad: 5pt,
	node((0,0), `hello`, stroke: 1pt),
	node((1,0), `there`, stroke: 1pt),
	conn((0,0), (1,0), "<=>"),
)
