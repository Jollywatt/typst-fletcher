#import "../common.typ": *
#show: style


= Nodes

Nodes are content centered at a coordinate.
Nodes automatically fit to their content (with an @node.inset[inset]), but can also be given a specific size and shape, and can have a @node.stroke[stroke] and @node.fill[fill].

#example(```typ
#diagram(
	spacing: (5pt, 2em), // small columns, large rows
	node((0,0), $A$),
	node((1,0), $f$, stroke: 1pt),
	node((2,0), $g$, stroke: 2pt + blue, shape: rect),
	node((3,0), $X$, stroke: blue, extrude: (0, 3)),
	{
		let b = blue.lighten(70%)
		node((0,1), `xyz`, fill: b, )
		let dash = (paint: blue, dash: "dashed")
		node((1,1), `xyz`, stroke: dash, inset: 1em)
		node((2,1), `xyz`, stroke: b, extrude: (0, -2))
		node((3,1), `xyz`, fill: b, height: 5em,
		                   corner-radius: 5pt)
	}
)
```)

== Node styles <node-styles>

Node styles can be set with named arguments to @node.
Default node styles can be set by passing options to the enclosing @diagram with the `node-` prefix, or by using `cetz.draw.set-style(node: ..)`.

#example(```typ
#diagram(
  node-stroke: 2pt, // default stroke style for nodes
  node((0,0), fill: yellow, [A]),
  edge("<->"),
  {
    import cetz.draw: *
    set-style(node: (extrude: (2,0)))
    node((1,0), stroke: yellow, [B], outset: 4pt) // stroke becomes 2pt + yellow
  }
)
```)

Like CeTZ styles, `cetz.draw.set-style()` is scoped to the current `cetz.draw.group()`.

Available node styles:

- @node.fill
- @node.stroke
- @node.extrude
- @node.inset
- @node.outset



== Node shapes <node-shapes>

By default, nodes are circular if their content is small and square, and rectangular if it is tall or wide.
The @node.shape[shape] option can be set to any of the following built-in shapes.

// #context if is-html() {
//   html.div(class: "flex", style: "flex-wrap: wrap; align-items: center;", {
//     fletcher
//       .shapes
//       .NODE_SHAPES
//       .keys()
//       .filter(name => name != "none")
//       .enumerate()
//       .map(((i, name)) => {
//         let c = color.oklch(80%, 70%, 20deg * i)
//         let body = text(c.mix(black), pad(-1em, link(label(name), pad(1em, raw(name)))))
//         frame(fletcher.diagram(fletcher.node((0, 0), body, shape: name, stroke: c)))
//       })
//       .join()
//   })
// } else {
//   fletcher
//     .shapes
//     .NODE_SHAPES
//     .pairs()
//     .map(((name, attrs)) => [
//       - #raw(name)
//         #for attr in attrs.keys() {
//           if attr == "draw" { continue }
//           [- #attr]
//         }
//     ])
//     .join()
// }
#frame-row(
  ..fletcher
    .shapes
    .NODE_SHAPES
    .keys()
    .filter(name => name != "none")
    .enumerate()
    .map(((i, name)) => {
      let c = color.oklch(80%, 70%, 20deg * i)
      let body = text(c.mix(black), pad(-1em, link(label(name), pad(1em, raw(name)))))
      frame(fletcher.diagram(fletcher.node((0, 0), body, shape: name, stroke: c)))
    })

)

Some shapes have style options like `width` or `radius`, and sometimes the shape can be inferred from the options given.
For example, `node(.., radius: 3cm)` is implicitly `node(.., shape: "circle", radius: 3cm)`.
