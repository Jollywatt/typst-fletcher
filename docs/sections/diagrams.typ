#import "../common.typ": *
#show: style


= Diagrams and Layout

Fletcher encourages the use of an "elastic, tabular layout" called a _flexigrid_.

Diagrams use a flexigrid layout by default, but you can also draw in a CeTZ canvas instead (see @draw-in-cetz).
To draw a diagram, fletcher first collects the row/column positions (or $u v$ coordinates) of all nodes in the diagram and calculates the row and column sizes for the flexigrid.
After this is determined, all nodes, edges and other objects are drawn in a context where both $u v$ coordinates and normal $x y$ coordinates can be used.

If nodes have fractional $u v$ coordinates, an iterative algorithm is used to calculate the minimum row and column sizes which accommodate the nodes.
This usually requires only a few steps (see the @flexigrid.max-layout-iterations option).

== Flexigrids <flexigrid-layouts>

== Nodes are placed within _cells_

#example(```typ
#diagram(
  debug: "node.cell",
  node-stroke: 1pt,
  node((0,0), radius: 5mm),
  node((0,1))[This is a wide node],
  node((1,0))[Small node],
)
```)