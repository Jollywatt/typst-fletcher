#import "arrow-diagrams.typ": *


#assert.eq(vector-unitless((4pt, 5pt)), (4, 5))


= Test arrow heads
Compare to symbols $#sym.arrow$, $#sym.arrow.twohead$, $#sym.arrow.hook$, $#sym.arrow.bar$

#arrow-diagram(
	pad: (10mm, 5mm),
	arrow((0, 0), (1, 0), marks: ("arrow", "arrow")),
	arrow((2, 0), (3, 0), marks: ("hook", "arrow")),
	arrow((0,-1), (1,-1), marks: ("tail", "tail")),
	arrow((0,-2), (1,-2), marks: ("double", "double")),
	arrow((2,-2), (3,-2), marks: ("hook", "double")),
	arrow((0,-3), (1,-3), marks: ("hook", "hook")),
	arrow((0,-4), (1,-4), marks: ("bar", "bar")),
	arrow((2,-4), (3,-4), marks: ("bar", "arrow")),
)

= Test connectors


#arrow-diagram(
	debug: 0,
	min-size: (10mm, 10mm),
	node((0,1), $X$),
	node((1,1), $Y$),
	node((0,0), "bro"),
	arrow((0,1), (1,1), marks: (none, "arrow")),
	arrow((0,0), (1,1), marks: ("hook", "arrow"), dash: "dashed"),
	arrow((0,1), (0,0), marks: (none, "double")),
)

= Test arc connectors

#for to in ((0,1), (1,0), (-1,-1)) {
	arrow-diagram({
		node((0,0), $A$)
		node(to, $B$)
		let N = 6
		range(N + 1).map(x => (x/N - 0.5)*2*120deg).map(θ => arrow((0,0), to, bend: θ, marks: ("tail", "arrow"))).join()
	})
}

#let s = 200%
#cetz.canvas({
	cetz.draw.line((0,0), (1,0), stroke: s*0.526pt)
	for i in (+1, -1) {
		cetz.draw.arc((1,0), radius: 8pt, start: i*106deg, delta: i*50deg, stroke: (cap: "round"))
	}
	cetz.draw.line((0,-1), (1,-1), stroke: s*0.526pt)
	cetz.draw.arc((0,-3), start: 0deg, delta: 135deg, anchor: "center")
})


= Test defocus

#arrow-diagram(
	defocus: 0,
	node-outset: 0pt,
{
	node((0,0), rect(fill: purple)[defocus #0])
	for p in (
		(-1,+1), ( 0,+1), (+1,+1),
		(-1, 0),          (+1, 0),
		(-1,-1), ( 0,-1), (+1,-1),
	) {
		arrow(p, (0,0))
	}
})