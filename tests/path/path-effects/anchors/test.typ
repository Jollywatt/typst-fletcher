#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: cetz, paths


#let speck(pt) = cetz.draw.circle(pt, radius: 2pt, stroke: red, fill: white)

#let obj = cetz.draw.merge-path({
  cetz.draw.line((0,0), (1,0), (1,1), (2,0))
  cetz.draw.arc((2,0), start: 180deg, stop: 90deg)
}, stroke: 2pt, name: "a")

Points on path by segment index
#cetz.canvas(length: 2cm, {
  paths.path-effect(obj)
  for i in range(6) { speck("a." + str(i)) }
  
  cetz.draw.translate(y: -1.5)

  paths.path-effect(obj, join: "round", corner-radius: 5mm)
  for i in range(6) { speck("a." + str(i)) }

})


#pagebreak()

#let obj = cetz.draw.merge-path({
  cetz.draw.line((0,0), (0,1))
  cetz.draw.bezier((0,1), (2,0), (1,1), (1,0))
  cetz.draw.line((2,0), (2,1))
}, stroke: 2pt, name: "a")

#cetz.canvas(length: 2cm, {
  paths.path-effect(obj)
  for i in range(5) { speck("a." + str(i)) }
  
  cetz.draw.translate(y: -1.5)

  paths.path-effect(obj, join: "round", corner-radius: 5mm)
  for i in range(4) { speck("a." + str(i)) }

})