#import "../common.typ": *
#show: style


= Integrating with CeTZ <cetz-interop>

Fletcher builds on top of CeTZ by defining:

- @flexigrid, which defines a $u v$ coordinate system for table-like layouts within a CeTZ canvas;

- @node for placing content which influences the layout of an enclosing @flexigrid;

- @edge for drawing paths with convenient styling options including outline snapping, arrow marks, multistroke effects, corner rounding, and label placement;

- @diagram, which is simply @flexigrid wrapped in a CeTZ canvas with styling shortcuts.


== Drawing in a CeTZ canvas <draw-in-cetz>

You can place nodes and edges directly inside a CeTZ canvas.
If you still want to use tabular layouts like in @diagram, you can wrap the objects in a @flexigrid.
For example, the following are equivalent:
#table(columns: (1fr, 1fr),
[Using @diagram], [Using `cetz.canvas()`],
```typ
#diagram(
  node-fill: teal,
  edge-stroke-thickness: 1pt,
  node((0,0), [Hello]),
  edge("->"),
  node((2,1), [There]),
)
```,
```typ
#cetz.canvas({
  import cetz.draw: *
  set-style(node: (fill: teal),
            edge: (stroke: 1pt))
  fletcher.flexigrid({
    node((0,0), [Hello])
    edge("->")
    node((2,1), [There])
  })
})
```)


Normal CeTZ objects may be placed in a @flexigrid, but must opt-in to use $u v$ coordinates with `(uv: coord)`, while nodes and edges use $u v$ coordinates by default (you can use `(xy: coord)` to opt-out).
Nodes and edges can be given names and participate in CeTZ's anchoring system.

== Applying edge effects to CeTZ paths

You can wrap a CeTZ path in @edge to apply edge effects to it.
This is useful if you are have a CeTZ-first drawing but want to use fletcher's arrows, edge snapping, stroke extrusion, corner rounding or convenient label placement.

For example, below we draw a composite CeTZ path from lines and a cubic Bézier segment and apply fletcher's marks, multistroke effects, label placement and snapping.
#example(```typ
#cetz.canvas({
  import cetz.draw: *
  let path = merge-path({
    line((0,0), (0,1))
    bezier((0,1), (2,0), (1,1), (1,0))
    line((2,0), (2,1))
  })
  scale(1.4)
  circle((0,0), radius: .4, name: "orb")
  edge(path, "<=>", snap-to: ("orb", none), label: (
    (body: $L$, pos: 0.5),
    (body: $R$, pos: 2.5, side: right),
    (body: `mid`, pos: 1.5, side: center, angle: auto),
  ), label-sep: 10pt)
})
```)
