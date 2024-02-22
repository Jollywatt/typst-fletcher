# Fletcher

[![Manual](https://img.shields.io/badge/latest-manual.pdf-green)](https://github.com/Jollywatt/typst-fletcher/raw/latest/docs/manual.pdf)
![Version](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fgithub.com%2FJollywatt%2Farrow-diagrams%2Fraw%2Flatest%2Ftypst.toml&query=package.version&label=latest&color=green)
![Version](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fgithub.com%2FJollywatt%2Farrow-diagrams%2Fraw%2Fmaster%2Ftypst.toml&query=package.version&label=dev)
[![Repo](https://img.shields.io/badge/GitHub-repo-blue)](https://github.com/Jollywatt/typst-fletcher)

_**Fletcher** (noun) a maker of arrows_

A [Typst]("https://typst.app/") package for drawing diagrams with arrows,
built on top of [CeTZ]("https://github.com/johannes-wolf/cetz").



```typ
#import "@preview/fletcher:0.4.2" as fletcher: node, edge
```


<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/Jollywatt/typst-fletcher/raw/master/docs/example-gallery/first-isomorphism-theorem-dark.svg">
  <img src="https://github.com/Jollywatt/typst-fletcher/raw/master/docs/example-gallery/first-isomorphism-theorem-light.svg">
</picture>

```typ
#fletcher.diagram(cell-size: 15mm, $
  G edge(f, ->) edge("d", pi, ->>) & im(f) \
  G slash ker(f) edge("ur", tilde(f), "hook-->")
$)
```



<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/Jollywatt/typst-fletcher/raw/master/docs/example-gallery/flowchart-trap-dark.svg">
  <img src="https://github.com/Jollywatt/typst-fletcher/raw/master/docs/example-gallery/flowchart-trap-light.svg">
</picture>

```typ
// https://xkcd.com/1195/
#import fletcher.shapes: diamond
#set text(font: "Comic Neue", weight: 600)

#fletcher.diagram( 
  node-stroke: 1pt,
  edge-stroke: 1pt,
  node((0,0), [Start], corner-radius: 2pt, extrude: (0, 3)),
  edge("-|>"),
  node((0,1), align(center)[
    Hey, wait,\ this flowchart\ is a trap!
  ], shape: diamond),
  edge("d,r,u,l", "-|>", [Yes], label-pos: 0.1)
)
```



<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/Jollywatt/typst-fletcher/raw/master/docs/example-gallery/state-machine-dark.svg">
  <img src="https://github.com/Jollywatt/typst-fletcher/raw/master/docs/example-gallery/state-machine-light.svg">
</picture>

```typ
#fletcher.diagram(
  node-stroke: .1em,
  node-fill: gradient.radial(blue.lighten(80%), blue, center: (30%, 20%), radius: 80%),
  spacing: 4em,
  edge((-1,0), "r", "-|>", `open(path)`, label-pos: 0, label-side: center),
  node((0,0), `reading`, radius: 2em),
  edge(`read()`, "-|>"),
  node((1,0), `eof`, radius: 2em),
  edge(`close()`, "-|>"),
  node((2,0), `closed`, radius: 2em, extrude: (-2.5, 0)),
  edge((0,0), (0,0), `read()`, "--|>", bend: 130deg),
  edge((0,0), (2,0), `close()`, "-|>", bend: -40deg),
)
```



<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/Jollywatt/typst-fletcher/raw/master/docs/example-gallery/feynman-diagram-dark.svg">
  <img src="https://github.com/Jollywatt/typst-fletcher/raw/master/docs/example-gallery/feynman-diagram-light.svg">
</picture>

```typ
#fletcher.diagram($
  e^- edge("rd", "-<|-") & & & edge("ld", "-|>-") e^+ \
  & edge(gamma, "wave") \
  e^+ edge("ru", "-|>-") & & & edge("lu", "-<|-") e^- \
$)
```



<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/Jollywatt/typst-fletcher/raw/master/docs/example-gallery/ml-architecture-dark.svg">
  <img src="https://github.com/Jollywatt/typst-fletcher/raw/master/docs/example-gallery/ml-architecture-light.svg">
</picture>

```typ
#import fletcher.shapes: house, hexagon
#set text(font: "Fira Sans")

#let blob(pos, label, tint: white, ..args) = node(
  pos, align(center, label),
  width: 25mm,
  fill: tint.lighten(60%),
  stroke: 1pt + tint.darken(20%),
  corner-radius: 5pt,
  ..args,
)

#fletcher.diagram(
  spacing: 8pt,
  cell-size: (8mm, 10mm),
  edge-stroke: 1pt,
  edge-corner-radius: 5pt,
  mark-scale: 70%,

  blob((0,1), [Add & Norm], tint: yellow, shape: hexagon),
  edge(),
  blob((0,2), [Multi-Head\ Attention], tint: orange),
  blob((0,4), [Input], shape: house.with(angle: 30deg),
    width: auto, tint: red),

  for x in (-.3, -.1, +.1, +.3) {
    edge((0,2.8), (x,2.8), (x,2), "-|>")
  },
  edge((0,2.8), (0,4)),

  edge((0,3), "l,uu,r", "--|>"),
  edge((0,1), (0, 0.35), "r", (1,3), "r,u", "-|>"),
  edge((1,2), "d,rr,uu,l", "--|>"),

  blob((2,0), [Softmax], tint: green),
  edge("<|-"),
  blob((2,1), [Add & Norm], tint: yellow, shape: hexagon),
  edge(),
  blob((2,2), [Feed\ Forward], tint: blue),
)
```



## Todo/wishlist

- [x] Mathematical arrow styles
- [x] Also allow `&`-delimited equations for specifying nodes
- [ ] Support CeTZ arrowheads
- [x] Support arbitrary node shapes drawn with CeTZ
- [ ] Allow referring to node coordinates by their content?
- [ ] Support loops connecting a node to itself
- [x] More ergonomic syntax to avoid repeating coordinates?
- [x] Poly-edges with multiple segments
- [x] Add way to adjust edge connection points while still having them snap to node edges
- [x] Zig-zags and waves

## Change log

### 0.4.2

- Improve edge-to-node snapping. Edges can terminate anywhere near a node (not just at its center) and will automatically snap to the node outline. Added `snap-to` option to `edge()`.
- Fixed node `inset` being half the amount specified. If upgrading from previous version, you will need to divide node `inset` values by two to preserve diagram layout.
- Add `decorations` option to `edge()` for CeTZ path decorations (`"wave"`, `"zigzag"`, and `"coil"`, also accepted as positional string arguments).

### 0.4.1

- Support custom node shapes! Edges connect to node outlines automatically.
  - New `shapes` submodule, containing `diamond`, `pill`, `parallelogram`, `hexagon`, and other node shapes.
- Allow edges to have multiple segments.
  - Add `vertices` an `corner-radius` options to `edge()`.
  - Relative coordinate shorthands may be comma separated to signify multiple segments, e.g., `"r,u,ll"`.
- Add `dodge` option to `edge()` to adjust end points.
- Support `cetz:0.2.0`.

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