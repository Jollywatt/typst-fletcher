#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(spacing: (3cm, 1cm), {
	for (i, a) in (left, center, right).enumerate() {
		for (j, θ) in (-30deg, 0deg, 50deg).enumerate() {
			edge((j, 2*i), (j, 2*i - 1), label: a, "->", label-side: a, bend: θ)
		}
	}
})

#diagram(spacing: 1.5cm, {
	for (i, a) in (left, center, right).enumerate() {
		for (j, θ) in (-30deg, 0deg, 50deg).enumerate() {
			edge((2*i, j), (2*i + 1, j), label: a, "->", label-side: a, bend: θ)
		}
	}
})
