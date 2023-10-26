#set page(width: 10cm, height: auto)
#import "arrow-diagrams.typ": *

= `arrow-diagrams` examples

// #set text(size: 30pt)
#arrow-diagram(
	debug: true,
	pad: 15mm,
	node((-1,0), $A$),
	node((0,0), $A times B$),
	node((+1,0), $B$),
	node((0,1), $X$),
	node((1,.5), $<-->$),
	// arrow((-1,0), (0,1))
)

// #calc.abs(calc.fract(5.2))


#arrow-diagram(
	pad: 1mm,
	debug: true,
	node((0,0), box(fill: rgb("6663"), width: 10mm, height: 10mm)),
	node((-1 + -1e-2, 0), box(fill: rgb("f003"), width: 50pt, height: 10pt)),
	node((-1,1), box(fill: rgb("0f03"), width: 10mm, height: 10mm)),
	node((1,1), box(fill: rgb("00f3"), width: 5mm, height: 5mm)),
)
