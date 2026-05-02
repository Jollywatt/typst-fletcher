#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#let star-fig-4(radius: 2, ..args) = {
	cetz.canvas({
		for i in range(4) {
			let a =  360deg/4*i
			edge((0,0), (a, radius), "->", ..args)
			edge((2*radius,0), (rel: (a + 45deg, radius)), "->", ..args)
		}
	})
}

Label body shows the value of `label-side`.


#star-fig-4(label: (
	(body: `true`, side: true),
	(body: `false`, side: false),
), label-pos: 80%)

#star-fig-4(label: (
	(body: `top`, side: top),
	(body: `bottom`, side: bottom),
), label-pos: 80%)

#star-fig-4(label: (
	(body: `left`, side: left),
	(body: `right`, side: right),
), label-pos: 80%)

#star-fig-4(label: (
	(body: `center`, side: center),
))

#pagebreak()

#diagram(spacing: (3cm, 1cm), {
	for (i, a) in (right, center, left).enumerate() {
		for (j, θ) in (-30deg, 0deg, 50deg).enumerate() {
			edge((j, 2*i), (j, 2*i + 1), label: [#a], "->", label-side: a, bend: θ)
		}
	}
})

#diagram(spacing: 1.5cm, {
	for (i, a) in (top, center, bottom).enumerate() {
		for (j, θ) in (50deg, 0deg, -30deg).enumerate() {
			edge((2*i, j), (2*i + 1, j), label: [#a], "->", label-side: a, bend: θ)
		}
	}
})

#pagebreak()

Default to north of line
#cetz.canvas({
  for i in range(12) {
    edge((0,0), "->", (360deg/12*i, 3), $f$)
  }
})

#pagebreak()

Default to outer side of curve

#diagram(spacing: 4, {
  edge((0,0), (1,0), bend: +40deg, `above`)
  edge((0,0), (1,0), bend: -40deg, `below`)
})

#cetz.canvas({
  for i in range(8) {
    edge((0,0), "->", (360deg/8*i, 2), bend: 60deg, $f$)
  }
})

#pagebreak()

#diagram(edge((0,0), ">->", (1,0), label: (
	(body: `start`, pos: 0%, side: start),
	(body: `end`, pos: 100%, side: end),
)))

#diagram(edge((1,1), ">->", (0,0), label: (
	(body: `start`, pos: 0, side: start),
	(body: `end`, pos: 1, side: end),
)))

