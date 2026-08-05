#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#let aligned-nodes(..args) = {
for (i, a) in (
    top,
    top + right,
    right,
    bottom + right,
    bottom,
    bottom + left,
    left,
    top + left,
    center
  ).enumerate() {
    let c = oklch(70%, 70%, i*40deg)
    node(align: a, fill: c, ..args)
  }
}

#diagram(
  debug: "grid.cells",
  spacing: 1mm,
  node((0,1), width: 2)[X],
  node((1,0), height: 1)[Y],
  aligned-nodes((0,0), radius: 0.075)
)

#diagram(
  debug: "grid.cells",
  spacing: 1mm,
  axes: (btt, rtl),
  node((0,1), width: 2)[X],
  node((1,0), height: 1)[Y],
  aligned-nodes((0,0), radius: 0.075)
)

#diagram(
  debug: "grid.cells",
  spacing: 1mm,
  node((0,1), width: 2)[X],
  node((1,0), height: 1)[Y],
  aligned-nodes((0,0), radius: 0.075)
)


#diagram(
  debug: "grid.cells",
  spacing: 1mm,
  node((0,1), width: 2)[X],
  node((-1,0), height: 1)[Y],
  node((1,-1), width: 2)[Z],
  aligned-nodes((0,0), colspan: 2, radius: 0.075)
)