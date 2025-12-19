#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#cetz.canvas({
  import cetz.draw: *
  for s in (0, (5pt, 0), (0, 5pt), 5pt) {
    set-style(circle: (radius: 0.2))
    circle((0,0), fill: green, name: "a")
    circle((1,1), fill: red, name: "b")
    edge(<a>, <b>, shorten: s)
    translate(x: 1)
  }
})
#cetz.canvas({
  import cetz.draw: *
  for s in (0, (0.2, .5em), (-1, 0.2), .6em) {
    set-style(circle: (radius: 0.2))
    circle((0,0), fill: green, name: "a")
    circle((1,1), fill: red, name: "b")
    edge(<a>, <b>, shorten: s, from: 90deg, to: -90deg)
    translate(x: 1)
  }
})