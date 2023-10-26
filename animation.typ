#import "arrow-diagrams.typ": *
#set page(width: 10cm, height: 7cm, margin: 0pt)

#for t in range(-25, 25).map(x => x/25) {
	arrow-diagram(
		pad: 0mm,
		debug: true,
		node((0,0), box(fill: rgb("6663"), width: 10mm, height: 10mm)),
		node((t,0), box(fill: rgb("f003"), width: 20mm, height: 5mm)),
		node((-1,1), box(fill: rgb("0f03"), width: 15mm, height: 10mm)),
		node((1,1), box(fill: rgb("00f3"), width: 5mm, height: 5mm)),
	)

	pagebreak()

}
