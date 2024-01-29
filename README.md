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
#import "@preview/fletcher:0.4.0" as fletcher: node, edge


#fletcher.diagram(cell-size: 15mm, $
	G edge(f, ->) edge("d", pi, ->>) & im(f) \
	G slash ker(f) edge("ur", tilde(f), "hook-->")
$)


#fletcher.diagram(
	node-fill: rgb("aafa"),
	node-outset: 2pt,
	axes: (ltr, btt),

	node((0,0), `typst`),
	node((1,0), "A"),
	node((2.5,0), "B", stroke: c + 2pt),
	node((2,1), "C", extrude: (+1, -1)),

	for i in range(3) {
		edge((0,0), (1,0), bend: (i - 1)*25deg)
	},
	edge((1,0), (2,1), "..}>", corner: right),
	edge((1,0), (2.5,0), "-||-|>", bend: -0deg),
),
```

## Todo

- [x] Mathematical arrow styles
- [x] Also allow `&`-delimited equations for specifying nodes
- [ ] Support CeTZ arrowheads
- [ ] Support arbitrary node shapes drawn with CeTZ
- [ ] Allow referring to node coordinates by their content?
- [ ] Support loops connecting a node to itself
- [x] More ergonomic syntax to avoid repeating coordinates?

## Change log

### 0.4.0

- Add ability to specify diagrams in math-mode, using `&` to separate nodes.
- Allow implicit and relative edge coordinates, e.g., `edge("d")` becomes `edge(prev-node, (0, 1))`.
- Add ability to place marks anywhere along an edge. Shorthands now accept an optional middle mark, for example `|->-|` and `hook-/->>`.
- Add “hanging tail” correction to marks on curved edges. Marks now rotate a bit to fit more comfortably along tightly curving arcs.
- Add more arrowheads for the sake of it: `}>`, `<{`, `/`, `\`, `x`, `X`, `*` (solid dot), `@` (solid circle).
- Add `axes` option to `diagram()` to control the direction of each axis in the diagram's coordinate system.
- Add `width`, `height` and `radius` options to `node()` for explicit control over size.
- Add `corner-radius` option to `node()`.
- Add `stroke` option to `edge()` replacing `thickness` and `paint` options.
- Add `edge-stroke` option to `diagram()` replacing `edge-thickness`.

### 0.3.0

- Make round-style arrow heads better approximate the default math font.
- Add solid arrow heads with shorthand `<|-`, `-|>` and double-bar `||-`, `-||`.
- Add an `extrude` option to `node()` which duplicates and extrudes the node's stroke, enabling double stroke effects.

### 0.2.0

- Experimental support for customising arrowheads.
- Add right-angled edges with `edge(..., corner: left/right)`.