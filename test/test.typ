#import "arrow-diagrams.typ": *
#import "@local/cetz:0.1.2"


// #assert.eq(vector-unitless((4pt, 5pt)), (4, 5))


= Test arrow heads
Compare to symbols $#sym.arrow$, $#sym.arrow.twohead$, $#sym.arrow.hook$, $#sym.arrow.bar$

#arrow-diagram(
	debug: 0,
	pad: (10mm, 5mm),
{
	for i in (0, 1, 2) {
		let x = 2*i
		let bend = 40deg*i
		(
			(marks: ("harpoon-l", "harpoon-r")),
			(marks: ("arrow", "arrow")),
			(marks: ("tail", "tail")),
			(marks: ("double", "double")),
			(marks: ("hook", "arrow")),
			(marks: ("hook", "hook")),
			(marks: ("bar", "bar")),
			(marks: ("arrow", "arrow"), parallels: (1.5,-1.5)),
			(marks: ("tail", "tail"), parallels: (1.5,-1.5)),
			(marks: ("bar", "arrow"), parallels: (2,0,-2)),
			(marks: (none, none), parallels: (2.5,0,-2.5)),
		).enumerate().map(((i, args)) => {
			arrow((x, -i), (x + 1, -i), ..args, bend: bend)
		}).join()

	}

})

= Test connectors


#arrow-diagram(
	debug: 0,
	min-size: (10mm, 10mm),
	node((0,1), $X$),
	node((1,1), $Y$),
	node((0,0), $Z$),
	arrow((0,1), (1,1), marks: (none, "arrow")),
	arrow((0,0), (1,1), $f$, marks: ("hook", "arrow"), dash: "dashed"),
	arrow((0,1), (0,0), marks: (none, "double")),
	arrow((0,1), (0,1), marks: (none, "arrow"), bend: -120deg),
)

= Test arc connectors

#arrow-diagram(
	min-size: 3cm,
{
	node((0,0), "from")
	node((1,0), "to")
	for θ in (0deg, 20deg, -50deg) {
		arrow((0,0), (1,0), $#θ$, label-trans: 0pt, bend: θ, marks: (none, "arrow"))
	}
})

#arrow-diagram(
	debug: 3,
	node((0,0), $X$),
	node((1,0), $Y$),
	arrow((0,0), (1,0), bend: 45deg, marks: ("arrow", "arrow")),
)

#for (i, to) in ((0,1), (1,0), (calc.sqrt(1/2),-calc.sqrt(1/2))).enumerate() {
	arrow-diagram(debug: 0, {
		node((0,0), $A$)
		node(to, $B$)
		let N = 6
		range(N + 1).map(x => (x/N - 0.5)*2*120deg).map(θ => arrow((0,0), to, bend: θ, marks: ("tail", "arrow"))).join()
	})
}

= Test defocus

#let around = (
	(-1,+1), ( 0,+1), (+1,+1),
	(-1, 0),          (+1, 0),
	(-1,-1), ( 0,-1), (+1,-1),
)

#grid(
	columns: (1fr, 1fr, 1fr),
	..((6em, 2em), (2em, 6em)).map(((w, h)) => {
		(-10, 0, +10).map(defocus => {
			align(center, arrow-diagram(
				defocus: defocus,
				node-outset: 0pt,
			{
				node((0,0), rect(width: w, height: h, inset: 0pt, align(center + horizon)[#defocus]))
				for p in around {
					arrow(p, (0,0))
				}
			}))
		})
	}).join()
)

= Test label latitude placement

#arrow-diagram(
	min-size: (2.2cm, 2cm),
{
	for p in around {
		arrow(p, (0,0), $f$)
	}
})


= Test crossing connectors

#arrow-diagram(
	
{
	arrow((0,1), (1,0))
	arrow((0,0), (1,1), crossing: true)
})