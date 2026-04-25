#import "../common.typ": *
#show: style


= Edges <edges>



== Straight edges

#example(```typ
#diagram({
  node((-1,-1), $ bullet $)
  node((0,0), $G$, <G>)
  edge("l,d", "..>")
  node((0,-1), $G slash ker(f)$, <ker>)
  // edge(<G>, "->", name: <e>, bend: 5pt)
  node((1,0), $im(f)$, <im>)
  // edge(<im>, "==>", <ker>, from: (-90deg, 1.5), to: (45deg, 2))
  edge(<G>, "->>", <ker>)
  edge(<im>, (rel: (1,0)), (rel: (0,-1)), (rel: (-2,0)), "=>")

})
```)


== Common edge kinds

By default, edges are displayed as straight paths between two or more vertices.
To make it easy to achieve common edge shapes, like arcs, loops or right-angled corners, edges can have different _kinds_, depending on the combination of named arguments present.w

#table(
  columns: 3,
  stroke: none,
  table.header([Kind], [Required arguments], [Optional]),
  table.hline(),
  ..fletcher.edges.EDGE_KINDS.pairs().map(((k, v)) => {
    (raw(k), v.required.map(raw).join(", "), v.optional.keys().map(raw).join(", "))
  }).flatten()
)

#let edge-kind-examples(examples, ..extra-args) = {
  show: box // prevent breaking
  stack(
    dir: ltr,
    spacing: 1fr,
    ..examples.map(args => align(horizon, {
      diagram(
        node(radius: 1pt, fill: black),
        edge("->", ..extra-args, ..args, [#raw(repr(args))])
      )
    }))
  )
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

#edge-kind-examples((
  (corner: "|-"),
  (corner: "-|"),
  (corner: "|-|"),
  (corner: "-|-"),
), (2,1.5), label-fill: white)


== CeTZ edges

For more control, you can wrap any CeTZ path in @edge to apply any of fletcher's edge effects to it.
When used in this mode, edges have no vertices, but can be given:
- @edge.marks[marks]
- @edge.label[labels]
- @edge.extrude[extrusion effects]
- @edge.snap-to[snapping targets]
- @edge.decorate[decorations]