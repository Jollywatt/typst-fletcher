#import "../common.typ": *
#show: style


= Edges <edges>

@edge[`edge(..vertices, marks, labels, ..)`]

Use the @edge function inside a @diagram, `cetz.canvas()` or @flexigrid to draw lines or paths with various _edge effects_, including:
- @edge.snap-to[automatic snapping] to nodes or CeTZ objects
- @edge.marks[marks and arrows]
- @edge-labels[label placement]
- @edge.corner-radius[corner rounding]
- @edge.extrude[multi-stroke effects]
- CeTZ path @edge.decorate[decorations]

You can specify an edge with a sequence of vertex coordinates, similar to `cetz.draw.line(..)`.
There are a few built-in @edge-kinds[edge kinds] which accept extra named arguments (such as `bend: 30deg` for arc edges or `corner: "|-"` for right-angled corners).

Edge effects can also be applied to any CeTZ path by @cetz-edge[wrapping] it in the @edge function.

== Specifying vertices

Vertices should be the first arguments, unless there are two vertices, in which case you may put the @edge.marks[marks argument] in between:
```typc
edge((0,0), (1,0), (2,1), "->")
edge(<from>, "->", <to>)
```
Alternatively, an array of vertices may be supplied to the @edge.vertices argument.

=== Automatic vertices <auto-vertices>

To refer to the previous or next node in a diagram, you can use `auto`, as in:
```typc
edge(<from>, <to>)
edge(<from>, auto)  // to next node
edge(auto, <to>)    // from previous node
edge(auto, auto)    // connects surrounding nodes
```
In unambiguous situations, `auto` vertices can be omitted altogether:
```typc
edge(<coord>) == edge(<coord>, auto)
edge("->", <coord>) == edge(auto, "->", <coord>)
```
For example, this diagram uses _implicit_ automatic coordinates:
#example(```typ
#diagram({
  edge((-1,0), "~>")               // to next node (A)
  node((0,0), [A])
  edge("<..>")                     // connects A to B
  edge("->", (.5,1), bend: -30deg) // from previous node (A)
  node((1,0), [B])
})
```)

=== Relative coordinates

You may use strings such as `"u"` (up) or `"sw"` (south west) as shorthands for relative vertex coordinates `(rel: (du, dv))`.
The first letters of
#strong[t]op/#strong[u]p/#strong[n]orth,
#strong[b]ottom/#strong[d]own/#strong[s]outh,
#strong[l]eft/#strong[w]est, and
#strong[r]ight/#strong[e]ast
are allowed.

Commas can be used to separate multiple coordinates, so `"r,d"` is understood as `"r", "d"` which is `(rel: (1, 0)), (rel: (0, 1))`, assuming @flexigrid.axes is set so $(u, v)$ goes $(arrow.r, arrow.b)$.

#example(```typ
#diagram(
  node((0,0), $A$),
  edge("r,u,dr,r", "=>"),
  node((3,0), $B$),
)
```)
In example above, the edge @auto-vertices[implicitly] begins from the previous node (relative coordinates cannot be used as the first coordinate).

== Edge labels <edge-labels>

Edges can have any number of labels attached to them at specific positions.
Any markup or math content passed to @edge after vertices is interpreted a label.
#example(```typ
#diagram(
  debug: "edge.label",
  node((0,0), [A]),
  edge("->", [Label], bend: 60deg),
  edge("->", label: $f$, bend: -60deg),
  node((1,0), [B]),
)
```)
The following edge options set properties of the edge's label(s):
- @edge.label[`label`]: the body content
- @edge.label-pos[`label-pos`]: a @path-anchor[path anchor] specifying the label's position
- @edge.label-side[`label-side`]: which side of the edge to place the body
- @edge.label-angle[`label-angle`]: rotation/orientation of the body
- @edge.label-sep[`label-sep`]: separation between edge and body
- @edge.label-anchor[`label-anchor`]: the CeTZ anchor to use for label body 

To specify multiple labels, pass an array of dictionaries to @edge.label, where each contains properties without the `label-` prefix:
```typc
label: (
  (body: [First label], pos: .., side: ..),
  (body: [Second label], angle: .., sep: ..),
)
```

In the example below, the vertical edges have two labels each:

#example(```typ
#diagram(
  spacing: 15mm,
  node((0,0), $V$),   edge("->", $f$),        node((1,0), $W$),
  node((0,1), $K^n$), edge("->", $tilde(f)$), node((1,1), $K^m$),

  edge((0,0), (0,1), "->", label: (
    (body: $ tilde $, angle: auto),
    (body: $kappa_X$, side: right),
  ), label-sep: 3pt),

  edge((1,0), (1,1), "->", label: (
    (body: $ tilde $, angle: auto),
    (body: $kappa_Y$, side: right),
  ), label-sep: 3pt),
)
```)

== Kinds of edges <edge-kinds>

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


=== Polyline

By default, edges are displayed as straight paths between two or more vertices.
As with all edge kinds, they can have @edge.corner-radius[rounded corners].


=== Arc <edge-kind-arc>

`edge(.., bend: angle | length)`

A perfect arc can be made with the `bend` option, which can be an angle (measuring the initial angle of the arc relative to a straight edge) or a length, specifying the height of the arc.


#edge-kind-examples((
  (bend: 30deg),
  (bend: 3pt),
  (bend: -90deg),
  (bend: 120deg),
))


=== Bézier

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

=== Loop

A perfectly circular loop can be specified by giving either the loop's radius as `loop` or its direction `loop-angle` (which can be an angle or a direction like `"north"` or `right`.)

#edge-kind-examples((
  (loop: 10pt),
  (loop-angle: 90deg),
  (loop-angle: bottom),
  (loop: -5pt, loop-angle: "south"),
))

=== Corner

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


=== CeTZ <cetz-edge>

When @cetz-interop[integrating with CeTZ], you can wrap a CeTZ element in @edge to apply any of fletcher's edge effects to it.
When used in this mode, edges may have no vertices.

For example, below we draw a composite CeTZ path using lines and a cubic Bézier segment and apply fletcher's marks, multistroke effects, label placement and snapping.
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



== Path anchors <path-anchor>


Edges support _path anchors_, like most CeTZ elements.
This allows you to refer to points along an edge.
// In addition to CeTZ path anchors like `50%` or `1cm`, fletcher defines _segment indices_, which refer to the vertices of an edge 
In particular, the @edge.label-pos[label position] is a path anchor, and if the edge has a @edge.name, you can place other elements using the coordinates `<name.anchor>`, `"name.anchor"` or `(name: "name", anchor: "anchor")`.

#table(
  columns: 2, 
  [Path anchor], [Description],
  `25%`, [Fraction of total length along path],
  `"start", "mid", "end"`, [Aliases for `0%`, `50%` and `100%`],
  `10pt, -2em`, [Certain length from start or end of path],
  `0.5, 2.5, -1`, [Segment indices referring to or between vertices of the path]

)

The default path anchor is the midpoint, so in the example below `<f>` refers to `(name: "f", anchor: 50%)`.
#example(```typ
#diagram(
  spacing: 15mm,
  node((0,0), $X$),
  edge("->", bend: +60deg, $f$, name: <f>),
  edge("->", bend: -60deg, $g$, name: <g>),
  node((1,0), $Y$),

  edge(<f>, "=>", <g>, $alpha$, shorten: 3pt),
)
```)

Fletcher defines _segment indices_ in addition to CeTZ's usual path anchors, to make it easier to place labels along complex paths.
A segment index is a number which interpolates between the edge's vertices.
For example, `0` is the start, `1` is the first vertex, and `2.5` is halfway along the third segment of the edge.
Negative indices refer to vertices in reverse order.

#example(```typ
#diagram(
  spacing: 15mm,
  import cetz.draw: *,
  set-style(circle: (radius: 4pt)),
  edge("r,t,rd,r", ">>->", name: "foo", stroke: 1pt,
    [3#super[rd]], label-pos: 2),     // label at 3rd vertex
  circle("foo.0.5", stroke: red),     // 50% along first segment
  circle("foo.1", stroke: green),     // second vertex
  circle("foo.-0", stroke: blue),     // last vertex
  circle("foo.2.5", stroke: fuchsia), // 50% along third segment
)
```)


Importantly, *node positions cannot depend on edge anchors*. This is because nodes are processed before edges.
To place annotations on edges, you can draw directly with CeTZ, like in the example above.

