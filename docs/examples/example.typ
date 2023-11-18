#import "/src/exports.typ": *

#for dark in (false, true) [

#let c = if dark { white } else { black }
#set page(width: 22cm, height: 9cm, margin: 1cm)

#set text(fill: white) if dark


#show: scale.with(200%, origin: top + left)

#let conn = conn.with(paint: c)

#stack(
	dir: ltr,
	spacing: 1cm,

arrow-diagram(cell-size: 15mm, crossing-fill: none, {
	let (src, img, quo) = ((0, 1), (1, 1), (0, 0))
	node(src, $G$)
	node(img, $im f$)
	node(quo, $G slash ker(f)$)
	conn(src, img, $f$, "->")
	conn(quo, img, $tilde(f)$, "hook-->", label-side: right)
	conn(src, quo, $pi$, "->>")
}),

arrow-diagram(
	node-stroke: c,
	node-fill: rgb("aafa"),
	node((0,0), `typst`),
	node((1,0), "A"),
	node((2,0), "B", stroke: c + 2pt),
	node((2,1), "C"),

	conn((0,0), (1,0), "->", bend: 15deg),
	conn((0,0), (1,0), "<-", bend: -15deg),
	conn((1,0), (2,1), "=>", bend: 20deg),
	conn((1,0), (2,0), "..>", bend: -0deg),
),

)

]