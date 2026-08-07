#import "../common.typ": *
#show: style

= Debugging <debug-options>

Fletcher has a range of _debug options_ which cause extra visual feedback to be drawn in diagrams.
For example, `diagram(debug: "grid")` shows a coordinate grid, and `node(debug: 4)` shows various parts of a node's anatomy.

Debug arguments accept the following options:
- `true`, `false`: enable or disable all debug annotations
- `1`, `2`, ..., #raw(str(calc.max(..DEBUG_LEVELS.values()))): enable the most common annotations up to this level of detail
- `"grid"`: enable default annotations for a category
- `"grid.cells"`: enable a specific annotation
- `("grid", "node.outset")`: multiple annotations
- `"grid node.outset"`: space-separated shorthand for multiple annotations

#let dummy-diagram(debug) = {
	show: frame
	show: scale.with(150%, reflow: true)
	// show: pad.with(1em)
	diagram(
		spacing: 0.5,
		debug: debug,
		node-fill: luma(90%),
		node((0,0), [A], shape: "triangle"),
		edge("->", $f$, bend: 30deg),
		node((1,0), [B], outset: 3pt, align: bottom),
		node((0,1), colspan: 2)[XYZ]
	)
}

#let debug-docs = (
  grid: [
    Grid annotations apply to @diagram and @flexigrid.
  ],

	"grid.coords": [
		Show column and row or $(u, v)$ diagram coordinates.
	],
	"grid.xy": [
		Show CeTZ or $(x, y)$ canvas coordinates.
	],
  "grid.lines": [
    Draw coordinate lines and indicate the sizes of rows and columns with tabs around the border.
	],
  "grid.cells": [
		Show all cells in a flexigrid as red boxes.
	],
  "grid.iters": [
		Report the number of iterations the flexigrid layout took to converge.
	],

	node: [
	  These can be set on individual nodes
		```typc
		node(.., debug: "node.body")
		```
		or set at the diagram level:
		```typc
		diagram(debug: "node.body", ..)
		```
	],

  "node.origin": [
		Show the center coordinate of a node as a small red dot.

		This point is used as the default anchor for the node.
	],
  "node.inset": [
		Show bounding box around the node's body content _before_ @node.inset is applied.
	],
	"node.body": [
	  Show bounding box around a node's body, including any @node.inset.
	],
  "node.outset": [
		Show the snapping target for edges connecting to this node.

    The snapping target is the node's outline extruded by the distance @node.outset.
	],
	"node.bounds": [
		Show bounding boxes of node shapes.
	],
  "node.cell": [
    Show the flexigrid cell inhabited by the node.

    Unlike @debug.grid.cells, this makes the node's @node.colspan[column] and @node.rowspan[row spans] visible.
    This node's cell is the region in which @node.align has effect.
	],

	edge: [
    These can be set on individual edges
    ```typc
    edge(.., debug: "edge.label")
    ```
    or set at the diagram level:
    ```typc
    diagram(debug: "edge.label", ..)
    ```

	],

	"edge.label": [
		Show anchor points and bounding boxes of edge labels
	],
  "edge.snap": [
		Show the path of an edge _before_ node snapping is applied
	],
  "edge.snap.from": [
		Identify the node which the _start_ of an edge snapped to by shading it green
	],
  "edge.snap.to": [
		Identify the node which the _end_ of an edge snapped to by shading it red

	],
)

#html.style(```css
.debug-row {
  display: flex;
  gap: 1em;

  :first-child {
    flex-grow: 1;
  }
}
```.text)
#for (key, desc) in debug-docs {
  let id = label("debug." + key)

  if "." not in key {
    // make this a heading
    let titlecase = upper(key.first()) + key.slice(1)
    [#heading(level: 2)[#titlecase debug options] #id]
    desc
    continue
  }

  html.div(class: "fn-arg")[
    #heading(raw(repr(key)), level: 3) #id
    #html.div(class: "debug-row", {
      html.div[
        #desc

        (Level $>= #DEBUG_LEVELS.at(key)$)
      ]
      dummy-diagram(key)
    })
  ]

}

== Debugging arrow marks

To make properly implementing custom marks easier, the @test is provided which shows more detailed debug annotations on marks.

#example(```typ
#show: scale.with(150%, reflow: true)
#fletcher.marks.test((
	size: 2,
	tip-origin: mark => mark.size + 0.5,
	tail-origin: -0.5,
	draw: mark => cetz.draw.arc((0,0),
		start: -90deg, stop: +90deg,
		radius: mark.size,
		fill: none,
	)
))
```)
