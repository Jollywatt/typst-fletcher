#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#diagram(spacing: (3cm, 1cm), {
	for (i, a) in (left, center, right).enumerate() {
		for (j, θ) in (-30deg, 0deg, 50deg).enumerate() {
			edge((j, 2*i), (j, 2*i - 1), label: [#a], "->", label-side: a, bend: θ)
		}
	}
})

#diagram(spacing: 1.5cm, {
	for (i, a) in (top, center, bottom).enumerate() {
		for (j, θ) in (-30deg, 0deg, 50deg).enumerate() {
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
