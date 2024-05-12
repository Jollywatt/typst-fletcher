#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#let label = table(
  columns: (12mm, 4mm, 4mm, 4mm),
  `Node`, none, `4`, none,
  stroke: (x, y) => if 0 < x and x < 3 { (x: 1pt) },
)

Allow `snap-to` to be `none`.

#diagram(
  node-stroke: 1pt,
  edge-stroke: 1pt,
  mark-scale: 50%,
  node((0,0), label, inset: 0pt, corner-radius: 3pt),
  edge((0.09,0), (0,1), "*-straight", snap-to: (none, auto)),
  edge((0.41,0), (1,1), "*-straight", snap-to: none),
  node((0,1), `Subnode`),
)