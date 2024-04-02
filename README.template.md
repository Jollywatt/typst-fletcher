# fletcher

[![Manual](https://img.shields.io/badge/latest-manual.pdf-green)](https://github.com/Jollywatt/typst-fletcher/raw/latest/docs/manual.pdf)
![Version](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fgithub.com%2FJollywatt%2Farrow-diagrams%2Fraw%2Flatest%2Ftypst.toml&query=package.version&label=latest&color=green)
![Version](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fgithub.com%2FJollywatt%2Farrow-diagrams%2Fraw%2Fmaster%2Ftypst.toml&query=package.version&label=dev)
[![Repo](https://img.shields.io/badge/GitHub-repo-blue)](https://github.com/Jollywatt/typst-fletcher)

_**fletcher** (noun) a maker of arrows_

A [Typst](https://typst.app/) package for drawing diagrams with arrows,
built on top of [CeTZ](https://github.com/johannes-wolf/cetz).
See the [manual](https://github.com/Jollywatt/typst-fletcher/raw/latest/docs/manual.pdf) for documentation.

````python
f"""
```typ
#import "@preview/fletcher:{get_version()}" as fletcher: diagram, node, edge
```
"""
````

```python
# These are examples in `docs/example-gallery/*.typ`
'\n'.join(insert_example_block(name) for name in [
  "first-isomorphism-theorem",
  "flowchart-trap",
  "state-machine",
  "feynman-diagram",
])
```

# More examples
Pull requests are most welcome!

```python
# These are examples in `docs/gallery/*.typ`
insert_example_table([
  "commutative",
  "algebra-cube",
  "ml-architecture",
  "io-flowchart",
])
```


## Change log

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
