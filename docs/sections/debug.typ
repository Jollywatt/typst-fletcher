#import "../common.typ": *
#show: style

= Debugging

Fletcher has a range of _debug options_ which cause extra visual feedback to be drawn in diagrams.
For example, `diagram(debug: "grid")` shows a coordinate grid.

You can set the debug level for an entire diagram, or for individual nodes or edges using the `debug` named argument.

Debug arguments accept the following options:
- `true`, `false`: enable or disable all debug annotations
- `1`, `2`, ..., #raw(str(calc.max(..DEBUG_LEVELS.values()))): enable common annotations up to this level of detail
- `"grid"`: enable specific annotations
- `"grid.cells"`: a more specific annotation
- `("grid", "node.outset")`: multiple annotations
- `"grid node.outset"`: space-separated string of multiple annotations

== Debug options <debug-options>

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
	"grid.coords": [
		Show $u v$ or column/row diagram coordinates
	],
  "grid.lines": [
		Show coordinate lines through row/column centers with dotted lines and indicate row/column sizes with solid lines
	],
  "grid.cells": [
		Show boundaries of flexigrid cells as red boxes
	],
  "grid.iters": [
		Report the number of iterations the flexigrid layout took to converge
	],
	"grid.xy": [
		Show $x y$ coordinate axes and grid in gray
	],

  "node.origin": [
		Show the center coordinate of a node as a small red dot
	],
  "node.inset": [
		Show bounding boxes around node bodies, before @node.inset is applied
	],
	"node.body": [
	  Show bounding box around a node's body, after applying @node.inset.
	],
  "node.outset": [
		Show a node's snapping target for connecting edges, which is the node's outline extruded by the distance @node.outset
	],
	"node.bounds": [
		Show the rectangular bounding boxes of nodes
	],
  "node.cell": [
		Show a node's occupied flexigrid cell, respecting @node.colspan and @node.rowspan, and determining the region in which the node can be aligned with @node.align
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

#table(
	columns: 3,
	..debug-docs.pairs().map(((k, v)) => {
		(
			[#raw(k)\ (level #DEBUG_LEVELS.at(k))],
			v,
			dummy-diagram(k),
		)
	}).flatten(),

	raw("mark.dots"),
	[
		Show the four key points of each marks on an edge
	],
	frame(scale(300%, reflow: true, diagram(edge(">>->", stroke: 1pt, bend: 90deg), debug: "mark.dots")))
)

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
