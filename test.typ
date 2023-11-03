#import "arrow-diagrams.typ": *
#import "@local/cetz:0.1.2"


// #assert.eq(vector-unitless((4pt, 5pt)), (4, 5))


= Test arrow heads
Compare to symbols $#sym.arrow$, $#sym.arrow.twohead$, $#sym.arrow.hook$, $#sym.arrow.bar$

#arrow-diagram(
	debug: 1,
	pad: (10mm, 5mm),
{
	for i in (0, 1) {
		let x = 2*i
		let bend = 60deg*i
		arrow((x, 1), (x+1, 1), marks: ("harpoon-l", "harpoon-r"), bend: bend)
		arrow((x, 0), (x+1, 0), marks: ("arrow", "arrow"), bend: bend)
		arrow((x,-1), (x+1,-1), marks: ("tail", "tail"), bend: bend)
		arrow((x,-2), (x+1,-2), marks: ("double", "double"), bend: bend)
		arrow((x,-3), (x+1,-3), marks: ("hook", "hook"), bend: bend)
		arrow((x,-4), (x+1,-4), marks: ("bar", "bar"), bend: bend)
		arrow((x,-5), (x+1,-5), marks: ("tail", "arrow"), parallels: (1.5,-1.5), bend: bend)
		arrow((x,-6), (x+1,-6), marks: ("bar", "arrow"), parallels: (2,0,-2), bend: bend)

		// arrow((2, 0), (3, 0), marks: ("hook", "arrow"), bend: bend)
		// arrow((2,-2), (3,-2), marks: ("hook", "double"), bend: bend)
		// arrow((2,-4), (3,-4), marks: ("bar", "arrow"))
	}

})

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

#for (i, to) in ((0,1), (1,0), (calc.sqrt(1/2),-calc.sqrt(1/2))).enumerate() {
	arrow-diagram(debug: 0, {
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

#let around = (
	(-1,+1), ( 0,+1), (+1,+1),
	(-1, 0),          (+1, 0),
	(-1,-1), ( 0,-1), (+1,-1),
)

#arrow-diagram(
	defocus: 0,
	node-outset: 0pt,
{
	node((0,0), rect(fill: purple)[defocus #0])
	for p in around {
		arrow(p, (0,0))
	}
})

= Test label latitude placement

#arrow-diagram(
	min-size: (2.2cm, 2cm),
{
	for p in around {
		arrow(p, (0,0), $f$)
	}
})


#arrow-diagram(
	debug: 3,
	node((0,0), $X$),
	node((1,0), $Y$),
	arrow((0,0), (1,0), bend: 45deg, marks: ("arrow", "arrow")),
)