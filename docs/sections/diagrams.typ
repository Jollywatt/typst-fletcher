#import "../common.typ": *
#show: style


= Diagrams and Layout

Fletcher encourages the use of an "elastic, tabular layout" called a _flexigrid_.

Diagrams use a flexigrid layout by default, but you can also draw in a CeTZ canvas instead (see @draw-in-cetz).
To render a diagram, fletcher first collects the row/column positions (or $u v$ coordinates) of all nodes in the diagram and calculates the row and column sizes for the flexigrid layout.
After the final flexigrid is determined, all nodes, edges and other objects are drawn in a context where both $u v$ coordinates and normal $x y$ coordinates can be used.

If nodes have fractional $u v$ coordinates, an iterative algorithm is used to calculate the minimum row and column sizes which accommodate the nodes.
This usually requires only a few steps (see the @flexigrid.max-layout-iterations option for details).

== Nodes are placed within _cells_ <node-cells>

A node inside a flexigrid lives within a _cell_, which is visible when the @debug.node.cell debug option is turned on for the node or diagram.

#example(```typ
#diagram(
  debug: "grid.coords",
  node-stroke: 1pt,
  node((0,0), radius: 5mm, debug: "node.cell"),
  node((0,1))[This is a wide node],
)
```)

Nodes placed at fractional coordinates still live in their own cell, defined by a linear interpolation.
For example, below the circle's cell is shown as it moves along $(0, 0) -> (1, 1)$.

#frame-row(..(0, 1/3, 2/3, 1).map(x => {
  diagram(
    debug: "grid.coords",
    node-fill: teal.lighten(50%),
    node-stroke: 0.5pt,
    spacing: 2mm,
    node((x,x), radius: 2mm, debug: "node.cell"),
    node((0,1))[Wide],
    node((1,0), rotate(90deg, reflow: true)[Tall]),
  )
}))

This behaviour guarantees that a small nudge in a node's position only results in a small change to the diagram's final appearance.

== Node alignment within cells

A node's cell is defined by the flexigrid's rows and columns, and grows with the size of the node.
However, the cell can be larger than the node's bounding box (visible with the @debug.node.bounds debug option).
By default, nodes are placed in the center of their cell, but they can also be *aligned within cells* with @node.align.

#example(```typ
#diagram(
  node-stroke: 1pt,
  node((0,0), radius: 5mm, debug: "node.cell",
    align: right),
  node((0,1))[This is a wide node],
)
```)


== Node row and column span

A node's cell can be made to span multiple columns or rows in a flexigrid.
When this happens, the node's size is automatically set to the full size of the cell.

#example(```typ
#diagram(
  debug: "grid",
  node-fill: teal.lighten(50%),
  node-stroke: 0.5pt,
  node-shape: rect,
  node((0,0), $X$),
  node((0,1), $Y$),
  node((1,0), rowspan: 2)[Two Rows],
  node((0,2), colspan: 2)[Two Columns],
)
```)
