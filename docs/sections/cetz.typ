#import "../common.typ": *
#show: style


= CeTZ Integration <cetz-interop>

Fletcher aims to be compatible with CeTZ, in the sense that you can use as little or as much of fletcher's features with CeTZ and vice versa.
Under the hood, fletcher builds upon CeTZ by defining:

- @flexigrid, which defines a $u v$ coordinate system for table-like layouts within a CeTZ canvas;

- @node for placing content which influences the layout of an enclosing @flexigrid;

- @edge for drawing paths with convenient styling options including outline snapping, arrow marks, multistroke effects, corner rounding, and label placement;

- @diagram, which is simply @flexigrid wrapped in a CeTZ canvas with styling shortcuts.


== Drawing in a CeTZ canvas <draw-in-cetz>

Instead of using @diagram, you can place nodes and edges directly inside a CeTZ canvas.
If you still want to use tabular layouts like in @diagram, you can wrap the objects in a @flexigrid.
For example, the following are equivalent:
#table(
  columns: (1fr, 1fr),
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
  ```,
)
Drawing inside a CeTZ canvas is encouraged when your diagram does not have a natural table-like structure or is very complex.
However, some features only work inside @diagram or @flexigrid (for example, in a `cetz.canvas()` edges cannot snap to nodes declared later).

Normal CeTZ objects may be placed in a @flexigrid, but must opt-in to use $u v$ coordinates with `(uv: coord)`, while nodes and edges use $u v$ coordinates by default (you can use `(xy: coord)` to opt-out).
Nodes and edges can be given names and participate in CeTZ's anchoring system.

== Applying edge effects to CeTZ paths

You can wrap a CeTZ path in @edge to apply edge effects to it (see @cetz-edge).
Using @edge in this way is a convenient wrapper to the path modification functions offered by fletcher, which includes @path-effect for applying corner rounding (for @edge.corner-radius) and offsetting (for @edge.extrude) to CeTZ paths, and @apply-edge-effects for placing marks and labels.
