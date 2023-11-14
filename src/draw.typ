#import "@preview/cetz:0.1.2" as cetz: vector
#import "utils.typ": *
#import "marks.typ": *


#let get-node-connector(node, incident-angle, options) = {

	if node.radius < 1e-3pt { return node.real-pos }

	if node.shape == "circle" {
		// use bounding circle
		vector.sub(
			node.real-pos,
			vector-polar(node.radius, incident-angle),
		)

	} else {
		// use bounding rect
		let origin = node.real-pos
		let μ = calc.pow(node.aspect, options.defocus)
		let origin-δ = (
			-calc.max(0pt, node.size.at(0)/2*(1 - 1/μ))*calc.cos(incident-angle),
			-calc.max(0pt, node.size.at(1)/2*(1 - μ/1))*calc.sin(incident-angle),
		)
		let crossing-line = (
			vector.add(origin, origin-δ),
			vector.sub(origin, vector-polar(1e3*node.radius, incident-angle)),
		)

		intersect-rect-with-crossing-line(node.rect, crossing-line)
	}
}

#let get-node-connectors(arrow, nodes, options) = {
	let center-center-line = nodes.map(node => node.real-pos)

	let v = vector.sub(..center-center-line)
	let θ = vector-angle(v) // approximate angle of connector

	let δ = if arrow.mode == "arc" { arrow.bend } else { 0deg }
	let incident-angles = (θ + δ, θ - δ + 180deg)

	let points = zip(nodes, incident-angles).map(((node, θ)) => {
		get-node-connector(node, θ, options)
	})

	points
}

#let draw-connector(arrow, nodes, options) = {

	// Stroke end points, before adjusting for the arrow heads
	let cap-points = get-node-connectors(arrow, nodes, options)
	let θ = vector-angle(vector.sub(..cap-points))

	// Get the arrow head adjustment for a given extrusion distance
	let cap-offsets(y) = zip(arrow.marks, (+1, -1))
		.map(((mark, dir)) => {
			if mark == none or mark not in CAP_OFFSETS { 0pt }
			else {
				let o = CAP_OFFSETS.at(mark)(y)
				dir*o*arrow.stroke.thickness
			}
		})

	let cap-angles
	let label-pos

	if arrow.mode == "line" {

		cap-angles = (θ, θ + 180deg)

		for shift in arrow.extrude {
			let d = shift*arrow.stroke.thickness
			let shifted-line-points = cap-points
				.zip(cap-offsets(shift))
				.map(((point, offset)) => vector.add(
					point,
					vector.add(
						// Shift end points lengthways depending on markers
						vector-polar(offset, θ),
						// Shift line sideways (for double line effects, etc) 
						vector-polar(d, θ + 90deg),
					)
				))

			cetz.draw.line(
				..shifted-line-points,
				stroke: arrow.stroke,
			)
		}


		// Choose label anchor based on connector direction
		if arrow.label-side == auto {
			arrow.label-side = if calc.abs(θ) > 90deg { left } else { right }
		}
		let label-dir = if arrow.label-side == right { +1 } else { -1 }

		if arrow.label-anchor == auto {
			arrow.label-anchor = angle-to-anchor(θ - label-dir*90deg)
		}
		
		arrow.label-sep = to-abs-length(arrow.label-sep, options.em-size)
		label-pos = vector.add(
			vector.lerp(..cap-points, arrow.label-pos),
			vector-polar(arrow.label-sep, θ + label-dir*90deg),
		)

	} else if arrow.mode == "arc" {

		let (center, radius, start, stop) = get-arc-connecting-points(..cap-points, arrow.bend)

		let bend-dir = if arrow.bend > 0deg { +1 } else { -1 }
		let δ = bend-dir*90deg
		cap-angles = (start + δ, stop - δ)


		for shift in arrow.extrude {
			let (start, stop) = (start, stop)
				.zip(cap-offsets(shift))
				.map(((θ, arclen)) => θ + bend-dir*arclen/radius*1rad)

			cetz.draw.arc(
				center,
				radius: radius + shift*arrow.stroke.thickness,
				start: start,
				stop: stop,
				anchor: "center",
				stroke: arrow.stroke,
			)
		}



		if arrow.label-side == auto {
			arrow.label-side =  if arrow.bend > 0deg { left } else { right }
		}
		let label-dir = if arrow.label-side == left { +1 } else { -1 }

		if arrow.label-anchor == auto {
			// Choose label anchor based on connector direction
			arrow.label-anchor = angle-to-anchor(θ + label-dir*90deg)
		}
		
		arrow.label-sep = to-abs-length(arrow.label-sep, options.em-size)
		label-pos = vector.add(
			center,
			vector-polar(
				radius + label-dir*bend-dir*arrow.label-sep,
				lerp(start, stop, arrow.label-pos),
			)
		)

	} else { panic(arrow) }


	for (mark, pt, θ) in zip(arrow.marks, cap-points, cap-angles) {
		if mark == none { continue }
		draw-arrow-cap(pt, θ, arrow.stroke, mark)
	}

	if arrow.label != none {

		cetz.draw.content(
			label-pos,
			box(
				fill: white,
				inset: .2em,
				radius: .2em,
				stroke: if options.debug >= 2 { DEBUG_COLOR + 0.25pt },
				$ #arrow.label $,
			),
			anchor: arrow.label-anchor,
		)

		if options.debug >= 2 {
			cetz.draw.circle(
				label-pos,
				radius: arrow.stroke.thickness,
				stroke: none,
				fill: DEBUG_COLOR,
			)
		}
	}

	if options.debug >= 3 {
		for (cell, point) in zip(nodes, cap-points) {
			cetz.draw.line(
				cell.real-pos,
				point,
				stroke: DEBUG_COLOR + 0.1pt,
			)
		}
	}


}


#let draw-diagram(
	grid,
	nodes,
	arrows,
	options,
) = {

	for (i, node) in nodes.enumerate() {

		if node.label == none { continue }

		if node.stroke != none or node.fill != none {
			if node.shape == "rect" {
				cetz.draw.rect(
					..node.rect,
					stroke: node.stroke,
					fill: node.fill,
				)
			}
			if node.shape == "circle" {
				cetz.draw.circle(
					node.real-pos,
					radius: node.radius,
					stroke: node.stroke,
					fill: node.fill,
				)
			}
		}

		cetz.draw.content(node.real-pos, node.label, anchor: "center")

		if options.debug >= 1 {
			cetz.draw.circle(
				node.real-pos,
				radius: 1pt,
				fill: DEBUG_COLOR,
				stroke: none,
			)
		}

		if options.debug >= 2 {
			if options.debug >= 3 or node.shape == "rect" {
				cetz.draw.rect(
					..node.rect,
					stroke: DEBUG_COLOR + 0.25pt,
				)
			}
			if options.debug >= 3 or node.shape == "circle" {
				cetz.draw.circle(
					node.real-pos,
					radius: node.radius,
					stroke: DEBUG_COLOR + 0.25pt,
				)
			}
		}
	}

	let find-node-at-pos(pos) = {
		nodes.filter(node => node.pos == pos)
			.sorted(key: node => node.radius).last()
	}

	for arrow in arrows {
		// let nodes = arrow.points.map(pos => cells.at(repr(pos)))
		let nodes = arrow.points.map(find-node-at-pos)

		let intersection-stroke = if options.debug >= 2 {
			(paint: DEBUG_COLOR, thickness: 0.25pt)
		}

		draw-connector(arrow, nodes, options)

	}

	// draw axes
	if options.debug >= 1 {

		cetz.draw.rect(
			(0,0),
			grid.bounding-size,
			stroke: DEBUG_COLOR + 0.25pt
		)

		for (axis, coord) in ((0, (x,y) => (x,y)), (1, (y,x) => (x,y))) {

			for (i, x) in grid.centers.at(axis).enumerate() {
				let size = grid.sizes.at(axis).at(i)

				// coordinate label
				cetz.draw.content(
					coord(x, -.4em),
					text(fill: DEBUG_COLOR, size: .75em)[#(grid.origin.at(axis) + i)],
					anchor: if axis == 0 { "top" } else { "right" }
				)

				// size bracket
				cetz.draw.line(
					..(+1, -1).map(dir => coord(x + dir*max(size, 1e-6pt)/2, 0)),
					stroke: DEBUG_COLOR + .75pt,
					mark: (start: "|", end: "|")
				)

				// gridline
				cetz.draw.line(
					coord(x, 0),
					coord(x, grid.bounding-size.at(1 - axis)),
					stroke: (
						paint: DEBUG_COLOR,
						thickness: .3pt,
						dash: "densely-dotted",
					),
				)
			}
		}
	}
}


