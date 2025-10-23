#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#diagram(debug: "edge.label", {
  edge((0,0), (1,1), label: (
    (body: "NE", anchor: "north-east"),
    (body: "NW", anchor: "north-west"),
    (body: "SW", anchor: "south-west"),
    (body: "SE", anchor: "south-east"),
  ))
})

// should error when label-side and label-anchor are used together