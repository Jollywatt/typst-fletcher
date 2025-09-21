#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ": paths, cetz


#let test-all-angles(effect, n: 8) = {
  let angles = range(n).map(a => a*360deg/n)
  grid(
    columns: angles.len(),
    ..angles.map(o => {
      angles.map(i-angle => {
        let o-angle = i-angle + o
        cetz.canvas({
          import cetz.draw: *
          scale(0.5)
          rect((-1,-1), (+1,+1), stroke: gray)
          scale(0.8)

          effect(line((i-angle, -1), (0,0), (o-angle, 1)))

          circle((i-angle, -1), radius: 3pt, fill: green, stroke: white)
          circle((o-angle, +1), radius: 3pt, fill: red, stroke: white)
        })
      })
    }).join()
  )
}

#test-all-angles(obj => paths.path-effect(obj, corner: "round", corner-radius: 0.1))

#pagebreak()

#test-all-angles(obj => paths.path-effect(obj, corner: "miter", extrude: (+2, 0, -2)))

#pagebreak()

#test-all-angles(obj => paths.path-effect(obj, corner: "round", corner-radius: 0.1, extrude: (+2, 0, -2)))

#pagebreak()

#test-all-angles(obj => paths.path-effect(obj, miter-limit: 1.4, extrude: (+2, 0, -2)))

#pagebreak()

#cetz.canvas({
  import cetz.draw: *

  let obj = line(
    (0,0),
    (1,0),
    (1,1),
    (2,0),
    (3,0),
    (3,1),
    (2.5,0.5),
    stroke: 0.5pt + black.transparentize(50%),
  )

  (
    arguments(corner: "round", corner-radius: 0.1),
    arguments(extrude: (+2, 0, -2)),
    arguments(corner: "round", corner-radius: 0.0, extrude: (+2, 0)),
    arguments(corner: "round", corner-radius: 0.0, extrude: (-2, 0)),
    arguments(corner: "round", corner-radius: .1, extrude: (2, 0, -2)),
    arguments(corner: "round", corner-radius: -.15, extrude: (2, 0, -2)),
    arguments(corner: "miter", extrude: (2, 0)),
    arguments(corner: "miter", extrude: (0, -2), miter-limit: 2),
  ).map(args => {
    paths.path-effect(obj, stroke: teal + 2pt, ..args)
    // obj
    translate(y: -2)
  }).join()  
})
