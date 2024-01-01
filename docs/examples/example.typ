#import "/src/exports.typ" as fletcher: node, edge

#for dark in (false, true) [

#let c = if dark { white } else { black }
#set page(width: 22cm, height: 9cm, margin: 1cm)

#set text(fill: white) if dark


#show: scale.with(200%, origin: top + left)

#let edge = edge.with(paint: c)

#stack(
	dir: ltr,
	spacing: 1cm,

fletcher.diagram(cell-size: 15mm, crossing-fill: none, {
	let (src, img, quo) = ((0, 1), (1, 1), (0, 0))
	node(src, $G$)
	node(img, $im f$)
	node(quo, $G slash ker(f)$)
	edge(src, img, $f$, "->")
	edge(quo, img, $tilde(f)$, "hook-->", label-side: right)
	edge(src, quo, $pi$, "->>")
}),

fletcher.diagram(
	node-stroke: c,
	node-fill: rgb("aafa"),
	node-outset: 2pt,
	node((0,0), `typst`),
	node((1,0), "A"),
	node((2,0), "B", stroke: c + 2pt),
	node((2,1), "C", extrude: (+1, -1)),

	edge((0,0), (1,0), "->", bend: 20deg),
	edge((0,0), (1,0), "<-", bend: -20deg),
	edge((1,0), (2,1), "=>", corner: left),
	edge((1,0), (2,0), "..>", bend: -0deg),
),

)

]