#let v-add((x1, y1), (x2, y2)) = (x1 + x2, y1 + y2)
#let v-mul(s, (x, y)) = (s*x, s*y)
#let v-sub(a, b) = v-add(a, v-mul(-1, b))
#let v-polar(r, θ) = (r*calc.cos(θ), r*calc.sin(θ))

#let min-max(array) = (calc.min(..array), calc.max(..array))

#let cumsum(array) = {
	let sum = array.at(0)
	for i in range(1, array.len()) {
		sum += array.at(i)
		array.at(i) = sum
	}
	array
}

#let lerp(a, b, t) = a*(1 - t) + b*t
#let lerp-at(array, t) = lerp(
	array.at(calc.floor(t)),
	array.at(calc.ceil(t)),
	calc.fract(t),
)

#let zip(a, ..others) = if others.pos().len() == 0 {
	a.map(i => (i,))
} else {
	a.zip(..others)
}

#let expand-fractional-nodes(nodes) = {
	let i = 0
	while i < nodes.len() {
		let (x, y) = nodes.at(i).pos
		let (width, height) = nodes.at(i).size

		if calc.fract(x) != 0 {
			let _ = nodes.remove(i)
			nodes.push((
				pos: (calc.ceil(x), y),
				size: (width*calc.fract(x), height),
			))
			nodes.push((
				pos: (calc.floor(x), y),
				size: (width*(1 - calc.fract(x)), height),
			))
		} else if calc.fract(y) != 0 {
			let _ = nodes.remove(i)
			nodes.push((
				pos: (x, calc.ceil(y)),
				size: (width, height*calc.fract(y)),
			))
			nodes.push((
				pos: (x, calc.floor(y)),
				size: (width, height*(1 - calc.fract(y))),
			))
		} else {
			i += 1
		}
	}
	nodes
}

#let ensure-zero-based-positions(nodes) = {
	let origin = zip(..nodes.map(n => n.pos))
		.map(locs => calc.min(..locs.map(calc.floor)))

	nodes.map(node => {
		node.pos = v-sub(node.pos, origin)
		node
	})
}

#let compute-grid(nodes, pad) = {

	// (x: (x-min, x-max), y: ...)
	let rect = zip(..nodes.map(n => n.pos)).map(min-max)

	// (x: n-cols, y: n-rows)
	let dims = rect.map(((min, max)) => max - min + 1)

	// (x: (0pt, 0pt, ...), y: ...)
	let cell-sizes = dims.map(n => range(n).map(_ => 0pt))

	for node in nodes {
		let (col, row) = node.pos
		let (width, height) = node.size
		cell-sizes.at(0).at(col) = calc.max(cell-sizes.at(0).at(col), width)
		cell-sizes.at(1).at(row) = calc.max(cell-sizes.at(1).at(row), height)
	}

	// (x: (c1x, c2x, ...), y: ...)
	let cell-centers = cell-sizes.zip(pad).map(((sizes, gap)) => {
		cumsum(sizes).zip(sizes, range(sizes.len())).map(((end, size, i)) => end - size/2 + gap*i)
	})

	let total-size = cell-centers.zip(cell-sizes).map(((centers, sizes)) => {
		centers.at(-1) + sizes.at(-1)/2
	})

	(cell-centers, total-size)
}	



#let node(pos, label) = (
	kind: "node",
	pos: pos,
	label: label,
)

#let arrow(from, to, label: none) = (
	kind: "arrow",
	from: from,
	to: to,
)

#let arrow-diagram(
	pad: 0pt,
	debug: false,
	..entities,
) = {

	if type(pad) != array { pad = (pad, pad) }
	// entities
	let nodes = entities.pos().filter(e => e.kind == "node")
	let arrows = entities.pos().filter(e => e.kind == "arrow")
	
	style(styles => {

		let nodes = ensure-zero-based-positions(nodes)

		let rects = nodes.map(node => {
			let (width, height) = measure(node.label, styles)
			(pos: node.pos, size: (width, height))
		})

		rects = expand-fractional-nodes(rects)
		let (cell-centers, total-size) = compute-grid(rects, pad)

		let diagram = for node in nodes {

			let place-item(item) = place(
				center + horizon,
				item,
				dx: lerp-at(cell-centers.at(0), node.pos.at(0)),
				dy: lerp-at(cell-centers.at(1), node.pos.at(1)),
			)

			place-item(node.label)

			if debug {
				place-item(circle(radius: 1pt, fill: red, stroke: white + 0.5pt))
			}

		}

		diagram += for arrow in arrows {
			place(
				line(
					start: cell-centers.zip(arrow.from).map(((centers, coord)) => lerp-at(centers, coord)),
					end: cell-centers.zip(arrow.to).map(((centers, coord)) => lerp-at(centers, coord)),
				),
			)
		}

		block(
			stroke: if debug { red + .25pt },
			width: total-size.at(0),
			height: total-size.at(1),
			block(diagram)
		)

	})
}
