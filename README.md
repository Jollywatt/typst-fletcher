# fletcher

[![Manual](https://img.shields.io/badge/latest-manual.pdf-green)](docs/manual.pdf?raw=true)
![Version](https://img.shields.io/badge/latest-0.4.4-green)
![Version](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fgithub.com%2FJollywatt%2Farrow-diagrams%2Fraw%2Fmaster%2Ftypst.toml&query=package.version&label=dev)
[![Repo](https://img.shields.io/badge/GitHub-repo-blue)](https://github.com/Jollywatt/typst-fletcher)

_**fletcher** (noun) a maker of arrows_

A [Typst](https://typst.app/) package for drawing diagrams with arrows,
built on top of [CeTZ](https://github.com/johannes-wolf/cetz).
See the [manual](docs/manual.pdf?raw=true) for documentation.


```typ
#import "@preview/fletcher:0.4.4" as fletcher: diagram, node, edge
```



<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/example-gallery/first-isomorphism-theorem-dark.svg">
  <img src="docs/example-gallery/first-isomorphism-theorem-light.svg">
</picture>

```typ
#diagram(cell-size: 15mm, $
  G edge(f, ->) edge("d", pi, ->>) & im(f) \
  G slash ker(f) edge("ur", tilde(f), "hook-->")
$)
```


<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/example-gallery/flowchart-trap-dark.svg">
  <img src="docs/example-gallery/flowchart-trap-light.svg">
</picture>

```typ
// https://xkcd.com/1195/
#import fletcher.shapes: diamond
#set text(font: "Comic Neue", weight: 600)

#diagram(
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
  <source media="(prefers-color-scheme: dark)" srcset="docs/example-gallery/state-machine-dark.svg">
  <img src="docs/example-gallery/state-machine-light.svg">
</picture>

```typ
#set text(10pt)
#diagram(
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
  <source media="(prefers-color-scheme: dark)" srcset="docs/example-gallery/feynman-diagram-dark.svg">
  <img src="docs/example-gallery/feynman-diagram-light.svg">
</picture>

```typ
#diagram($
  e^- edge("rd", "-<|-") & & & edge("ld", "-|>-") e^+ \
  & edge(gamma, "wave") \
  e^+ edge("ru", "-|>-") & & & edge("lu", "-<|-") e^- \
$)
```


# More examples
Pull requests are most welcome!

<table>
  <tr>
    <td style="background: white;">
      <a href="docs/gallery/commutative.typ">
        <center>
          <img src="docs/gallery/commutative.svg" width="100%"/>
        </center>
      </a>
    </td>
    <td style="background: white;">
      <a href="docs/gallery/algebra-cube.typ">
        <center>
          <img src="docs/gallery/algebra-cube.svg" width="100%"/>
        </center>
      </a>
    </td>
  </tr>
  <tr>
    <td style="background: white;">
      <a href="docs/gallery/ml-architecture.typ">
        <center>
          <img src="docs/gallery/ml-architecture.svg" width="100%"/>
        </center>
      </a>
    </td>
    <td style="background: white;">
      <a href="docs/gallery/io-flowchart.typ">
        <center>
          <img src="docs/gallery/io-flowchart.svg" width="100%"/>
        </center>
      </a>
    </td>
  </tr>
  <tr>
    <td style="background: white;">
      <a href="docs/gallery/node-groups.typ">
        <center>
          <img src="docs/gallery/node-groups.svg" width="100%"/>
        </center>
      </a>
    </td>
  </tr>
</table>



## Change log

### 0.4.4

- Support fully customisable marks/arrowheads!
  - Added new mark styles and tweaked some existing defaults. **Note.** This may change the micro-typography of diagrams from previous versions.
- Add node groups via the `enclose` option of `node()`.
- Node labels can be aligned inside the node with `align()`.
- Node labels wrap naturally when label text is wider than the node. **Note:** This may change diagram layout from previous versions.
- Add a `layer` option to nodes and edges to control drawing order.
- Add node shapes: `ellipse`, `octagon`.

### 0.4.3

- Fixed edge crossing backgrounds being drawn above nodes (#14).
- Added `fletcher.hide()` to hide elements with/without affecting layout, useful for incremental diagrams in slides (#15).
- Support `shift`ing edges by coordinate deltas as well as absolute lengths (#13).
- Support node names (#8).

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

## Star History

<a href="https://star-history.com/#jollywatt/typst-fletcher&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=jollywatt/typst-fletcher&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=jollywatt/typst-fletcher&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=jollywatt/typst-fletcher&type=Date" />
 </picture>
</a>
