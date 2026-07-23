#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: cetz, paths


#let test-anchor(it, target) = {
  let result = fletcher.parsing.interpret-path-anchor(it)
  assert.eq(result, target)
}

#test-anchor(0, (segment: 0, t: 0, rev: false))
#test-anchor(1, (segment: 1, t: 0, rev: false))
#test-anchor(1.5, (segment: 1, t: .5, rev: false))
#test-anchor("-0", (segment: 0, t: 0, rev: true))
#test-anchor("-.3", (segment: 0, t: .3, rev: true))
#test-anchor("+2.75", (segment: 2, t: .75, rev: false))
#test-anchor(10mm, (length: 10mm, rev: false))
#test-anchor(-5pt, (length: 5pt, rev: true))
#test-anchor(50%, (length: 50%, rev: false))
#test-anchor(0%, (length: 0%, rev: false))
#test-anchor(100%, (length: 100%, rev: false))
#test-anchor("start", (length: 0%, rev: false))
#test-anchor("mid", (length: 50%, rev: false))
#test-anchor("end", (length: 100%, rev: false))
#test-anchor("3pt", (length: 3pt, rev: false))
#test-anchor("50%", (length: 50%, rev: false))




#let speck(pt) = cetz.draw.circle(pt, radius: 2pt, stroke: red, fill: white)

#let obj = cetz.draw.merge-path({
  cetz.draw.line((0,0), (1,0), (1,1), (2,0))
  cetz.draw.arc((2,0), start: 180deg, stop: 90deg)
}, stroke: 2pt, name: "a")

Points on path by segment index
#cetz.canvas(length: 2cm, {
  paths.path-effect(obj)
  speck("a.2.5")
  for i in range(6) { speck("a." + str(i)) }
  
  cetz.draw.translate(y: -1.5)

  paths.path-effect(obj, join: "round", corner-radius: 5mm)
  for i in range(6) { speck("a." + str(i)) }

})


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



#pagebreak()

#let obj = paths.path-effect(cetz.draw.line(
  (0,0),
  (1,1),
  (2,0),
  (1,0),
  (1,-0.7),
  (2,-0.7),
  name: "a",
), join: "round", corner-radius: 5pt)

Points on path by ratio

#cetz.canvas(length: 2cm, {
  obj
  for i in range(5) { speck("a." + repr(25%*i)) }
})

Points on path by length

#cetz.canvas(length: 2cm, {
  obj
  for i in range(9) { speck("a." + repr(1cm*i)) }
})

From path end

#cetz.canvas(length: 2cm, {
  obj
  for i in range(21) { speck("a.-" + repr(i*4/20)) }
})

#cetz.canvas(length: 2cm, {
  obj
  for i in range(11) { speck("a.-" + repr(5%*i)) }
})
