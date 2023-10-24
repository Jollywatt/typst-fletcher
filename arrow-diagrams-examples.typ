#set page(width: 15cm, height: auto)
#import "arrow-diagrams.typ": *

= `arrow-diagrams` examples

#arrow-diagram(
	pad: 3mm,
	debug: true,
	node((0,0), box(fill: rgb("6663"), width: 1*30pt, height: 1*30pt)),
	node((1,0), box(fill: rgb("f003"), width: 1*30pt, height: 1*30pt)),
	node((0,1), box(fill: rgb("0f03"), width: 2*30pt, height: 1*30pt)),
	node((1,1), box(fill: rgb("00f3"), width: 2*30pt, height: 2*30pt)),
)


#arrow-diagram(
	debug: true,
	pad: 1cm,
	node((0,0), $A$),
	node((1,0), $B$),
	node((0,1), $C$),
	arrow((0,1), (1,0))
)

