#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz


#let star-fig(radius: 2, ..args) = {
	cetz.canvas({
		for i in range(8) {
			let a = 360deg/8*i
			edge((0,0), (a, radius), "->", ..args)
		}
	})
}

#let star-fig-4(radius: 2, ..args) = {
	cetz.canvas({
		for i in range(4) {
			let a =  360deg/4*i
			edge((0,0), (a, radius), "->", ..args)
			edge((2*radius,0), (rel: (a + 45deg, radius)), "->", ..args)
		}
	})
}


```
label-angle: auto
```

Label body shows the value of `label-side`.

#star-fig-4(label-angle: auto, label: (
	(body: `true`, angle: auto, side: true),
	(body: `false`, angle: auto, side: false),
))

#star-fig-4(label-angle: auto, label: (
	(body: `top`, angle: auto, side: top),
	(body: `bottom`, angle: auto, side: bottom),
))

#pagebreak()

`label-angle`

#grid(
	columns: 2,
	align: center,
	gutter: 5mm,
	..(top, bottom, left, right, auto).map(dir => {
		raw(repr(dir))
		star-fig(
			label-angle: dir,
			label: $pi r^2$,
			label-side: center,
			label-pos: 60%,
		)
	})
)