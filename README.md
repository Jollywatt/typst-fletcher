# Fletcher

[![Manual](https://img.shields.io/badge/docs-manual.pdf-green)](https://github.com/Jollywatt/typst-fletcher/raw/master/docs/manual.pdf)
![Version](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fgithub.com%2FJollywatt%2Farrow-diagrams%2Fraw%2Fmaster%2Ftypst.toml&query=package.version&label=version)
[![Repo](https://img.shields.io/badge/GitHub-repo-blue)](https://github.com/Jollywatt/typst-fletcher)

_**Fletcher** (noun) a maker of arrows_

A [Typst]("https://typst.app/") package for drawing diagrams with arrows,
built on top of [CeTZ]("https://github.com/johannes-wolf/cetz").

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/Jollywatt/typst-fletcher/raw/master/docs/examples/example-2.svg">
  <img alt="logo" width="600" src="https://github.com/Jollywatt/typst-fletcher/raw/master/docs/examples/example-1.svg">
</picture>

```typ
#fletcher.diagram(cell-size: 15mm, crossing-fill: none, {
	let (src, img, quo) = ((0, 1), (1, 1), (0, 0))
	node(src, $G$)
	node(img, $im f$)
	node(quo, $G slash ker(f)$)
	edge(src, img, $f$, "->")
	edge(quo, img, $tilde(f)$, "hook-->", label-side: right)
	edge(src, quo, $pi$, "->>")
}),

#fletcher.diagram(
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

```

## Todo

- [x] Mathematical arrow styles
- [ ] Support CeTZ arrowheads
- [ ] Allow referring to node coordinates by their content
- [ ] Support loops connecting a node to itself
- [ ] More ergonomic syntax to avoid repeating coordinates?