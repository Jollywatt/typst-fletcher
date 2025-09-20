#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ": paths, cetz

#let angles = range(8).map(a => a*360deg/8)
#grid(
  columns: angles.len(),
  ..angles.map(i-angle => {
    angles.map(o => {
      let o-angle = i-angle + o
      cetz.canvas({
        import cetz.draw: *
        scale(0.5)
        let r = 1.2
        rect((-r,-r), (+r,+r), stroke: gray)
        let obj = line((i-angle, -1), (0,0), (o-angle, 1))
        paths.path-effect(obj, extrude: (-1,+1), corner-radius: 0.05)  
        circle((i-angle, -1), radius: 3pt, fill: blue, stroke: none)
      })
    })
  }).join()
)

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
    stroke: gray,
  )

  obj
  paths.path-effect(obj, stroke: red, corner-radius: 0, extrude: (+3, 0, -3))
})