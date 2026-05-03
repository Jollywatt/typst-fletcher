#import "../common.typ": *
#show: style


= Edges <edges>

@edge[`edge(..vertices, marks, labels, ..)`]

Use the @edge function inside a @diagram, `cetz.canvas()` or @flexigrid to draw lines or paths with various _edge effects_ applied to them.

Fletcher's edge effects include:
- automatic @edge.snap-to[snapping] to nodes or CeTZ objects
- convenient placement of @edge.label[labels]
- the addition of @edge.marks[marks] at the ends or along the path
- multi-stroke effects with @edge.extrude[extrude]
- @edge.corner-radius[corner rounding]
- CeTZ path @edge.decorate[decorations]

You can specify an edge with a sequence of vertex coordinates, similar to `cetz.draw.line(..)`, or with named arguments (such as `bend: 30deg` or `corner: "|-"`) as shortcuts for some @edge-kinds[common edge kinds].
Instead of specifying coordinates, you can also @cetz-edge[wrap a CeTZ path] in @edge to apply fletcher's edge effects to a CeTZ object,

== Straight edges

By default, an edge is displayed as a straight polyline between its two or more vertices.
Straight edges support corner rounding with @edge.corner-radius, which is #fletcher.edges.DEFAULT_EDGE_STYLE.corner-radius by default (from `fletcher.edges.DEFAULT_EDGE_STYLE`).

#example(```typ
#diagram(
  node((0,0), $A$, <A>),
  node((3,0), $B$, <end>),
  edge(<A>, (1,0), (1,1), (2,0), <end>, "=>", $f(x)$),
  edge(<A>, "d,rrr,u", "--|>", stroke: blue),
)
```)

=== Specifying vertices

You can omit edge vertices or use `auto` to refer to adjacent nodes.
For example:
#example(```typ
#diagram({
  edge((-1,0), "~>") // edge going to next node
  node((0,0), [A])
  edge("<..>") // edge between adjacent nodes
  edge("->", (.5,1), bend: -30deg) // edge from previous node
  node((1,0), [B])
})
```)
This can be written more explicitly using `auto` as the first or last vertex of an edge, as in `node((-1,0), "~>", auto)` or `edge(auto, auto, "<..>")`.


== Common edge kinds <edge-kinds>

By default, edges are displayed as straight paths between two or more vertices.
To make it easy to achieve common edge shapes, like arcs, loops or right-angled corners, edges can have different _kinds_, depending on the combination of named arguments present.

#table(
  columns: 3,
  stroke: none,
  table.header([Kind], [Required arguments], [Optional]),
  table.hline(),
  ..fletcher
    .edges
    .EDGE_KINDS
    .pairs()
    .map(((k, v)) => {
      (raw(k), v.required.map(raw).join(", "), v.optional.keys().map(raw).join(", "))
    })
    .flatten(),
)

#let edge-kind-examples(examples, ..extra-args) = {
  frame-row(..examples.map(args => align(horizon, {
    diagram(
      node((0,0), radius: 1pt, fill: black),
      edge("->", ..extra-args, ..args, [#raw(repr(args))]),
    )
  })))
}

=== Arc edges <edge-kind-arc>

`edge(.., bend: angle | length)`

A perfect arc can be made with the `bend` option, which can be an angle (measuring the initial angle of the arc relative to a straight edge) or a length, specifying the height of the arc.


#edge-kind-examples((
  (bend: 30deg),
  (bend: 3pt),
  (bend: -90deg),
  (bend: 120deg),
))


=== Bézier edges

`edge(.., from: angle | (angle, length), to: angle | (angle, length))`

Quadratic or cubic Bézier curves can be specified by giving an angle or polar coordinate such as `(90deg, 5mm)` to one of `from`, `to` or both.

#edge-kind-examples((
  (from: 90deg),
  (to: -90deg),
  (to: (45deg, 80pt)),
  (from: 90deg, to: -90deg),
  // (through: (0.5,0.5)),
))

You can also specify a Bézier curve through another point with `edge(.., through: <coord>)`.

=== Loop edges

A perfectly circular loop can be specified by giving either the loop's radius as `loop` or its direction `loop-angle` (which can be an angle or a direction like `"north"` or `right`.)

#edge-kind-examples((
  (loop: 10pt),
  (loop-angle: 90deg),
  (loop-angle: bottom),
  (loop: -5pt, loop-angle: "south"),
))

=== Corner edges

Edges with one or two right-angled corners can be specified with `corner`, which is a string of `"-"` and `"|"` specifying the order of horizontal or vertical segments.

#edge-kind-examples(
  (
    (corner: "|-"),
    (corner: "-|"),
    (corner: "|-|"),
    (corner: "-|-"),
  ),
  (2, 1.5),
  label-fill: white,
)


== CeTZ edges <cetz-edge>

For more control, you can wrap any CeTZ path in @edge to apply any of fletcher's edge effects to it.
When used in this mode, edges may have no vertices.

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
