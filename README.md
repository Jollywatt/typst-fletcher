# Arrow diagrams

A [Typst]("https://typst.app/") package for drawing diagrams with arrows,
built on top of [CeTZ]("https://github.com/johannes-wolf/cetz").

![Commutative diagram for first isomorphism theorem](https://github.com/Jollywatt/arrow-diagrams/raw/master/docs/examples/example.svg)

```typ
#arrow-diagram(cell-size: 15mm, {
	let (src, img, quo) = ((0, 1), (1, 1), (0, 0))
	node(src, $G$)
	node(img, $im f$)
	node(quo, $G slash ker(f)$)
	conn(src, img, $f$, "->")
	conn(quo, img, $tilde(f)$, "hook-->", label-side: right)
	conn(src, quo, $pi$, "->>")
})
```