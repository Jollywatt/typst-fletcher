#import "@preview/cetz:0.1.2" as cetz: vector
#import "utils.typ": *
#import "marks.typ": *

/// Get the point at which a connector should attach to a node from a given
/// angle, taking into account the node's size and shape.
///
/// - node (dictionary): The node to connect to.
/// - θ (angle): The desired angle from the node's center to the connection
///  point.
/// -> point
#let get-node-anchor(node, θ) = {

	if node.radius < 1e-3pt { return node.real-pos }

	if node.shape == "circle" {
		vector.add(
			node.real-pos,
			vector-polar(node.radius + node.outset, θ),
		)

	} else if node.shape == "rect" {
		let origin = node.real-pos
		let μ = calc.pow(node.aspect, node.defocus)
		let origin-δ = (
			calc.max(0pt, node.size.at(0)/2*(1 - 1/μ))*calc.cos(θ),
			calc.max(0pt, node.size.at(1)/2*(1 - μ/1))*calc.sin(θ),
		)
		let crossing-line = (
			vector.add(origin, origin-δ),
			vector.add(origin, vector-polar(1e3*node.radius, θ)),
		)

		intersect-rect-with-crossing-line(node.outer-rect, crossing-line)

	} else { panic(node.shape) }
}

/// Get the points where a connector between two nodes should be drawn between,
/// taking into account the nodes' sizes and relative positions.
///
/// - conn (dictionary): The connector whose end points should be determined.
/// - nodes (pair of dictionaries): The start and end nodes of the connector.
/// -> pair of points
#let get-conn-anchors(conn, nodes) = {
	let center-center-line = nodes.map(node => node.real-pos)

	let v = vector.sub(..center-center-line)
	let θ = vector-angle(v) // approximate angle of connector

	let δ = if conn.mode == "arc" { conn.bend } else { 0deg }
	let incident-angles = (θ + δ + 180deg, θ - δ)

	let points = zip(nodes, incident-angles).map(((node, θ)) => {
		get-node-anchor(node, θ)
	})

	points
}

#let draw-connector(conn, nodes, options) = {

	// Stroke end points, before adjusting for the arrow heads
	let cap-points = get-conn-anchors(conn, nodes)
	let θ = vector-angle(vector.sub(..cap-points))

	// Get the arrow head adjustment for a given extrusion distance
	let cap-offsets(y) = zip(conn.marks, (+1, -1))
		.map(((mark, dir)) => {
			if mark == none or mark not in CAP_OFFSETS {
				0pt
			} else {
				dir*CAP_OFFSETS.at(mark)(y)*conn.stroke.thickness
			}
		})

	let cap-angles
	let label-pos

	if conn.mode == "line" {

		cap-angles = (θ, θ + 180deg)

		for shift in conn.extrude {
			let d = shift*conn.stroke.thickness
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
				stroke: conn.stroke,
			)
		}


		// Choose label anchor based on connector direction
		if conn.label-side == auto {
			conn.label-side = if calc.abs(θ) > 90deg { left } else { right }
		}
		let label-dir = if conn.label-side == right { +1 } else { -1 }

		if conn.label-anchor == auto {
			conn.label-anchor = angle-to-anchor(θ - label-dir*90deg)
		}
		
		conn.label-sep = to-abs-length(conn.label-sep, options.em-size)
		label-pos = vector.add(
			vector.lerp(..cap-points, conn.label-pos),
			vector-polar(conn.label-sep, θ + label-dir*90deg),
		)

	} else if conn.mode == "arc" {

		let (center, radius, start, stop) = get-arc-connecting-points(..cap-points, conn.bend)

		let bend-dir = if conn.bend > 0deg { +1 } else { -1 }
		let δ = bend-dir*90deg
		cap-angles = (start + δ, stop - δ)


		for shift in conn.extrude {
			let (start, stop) = (start, stop)
				.zip(cap-offsets(shift))
				.map(((θ, arclen)) => θ + bend-dir*arclen/radius*1rad)

			cetz.draw.arc(
				center,
				radius: radius + shift*conn.stroke.thickness,
				start: start,
				stop: stop,
				anchor: "center",
				stroke: conn.stroke,
			)
		}



		if conn.label-side == auto {
			conn.label-side =  if conn.bend > 0deg { left } else { right }
		}
		let label-dir = if conn.label-side == left { +1 } else { -1 }

		if conn.label-anchor == auto {
			// Choose label anchor based on connector direction
			conn.label-anchor = angle-to-anchor(θ + label-dir*90deg)
		}
		
		conn.label-sep = to-abs-length(conn.label-sep, options.em-size)
		label-pos = vector.add(
			center,
			vector-polar(
				radius + label-dir*bend-dir*conn.label-sep,
				lerp(start, stop, conn.label-pos),
			)
		)

	} else { panic(conn.mode) }


	for (mark, pt, θ) in zip(conn.marks, cap-points, cap-angles) {
		if mark == none { continue }
		draw-arrow-cap(pt, θ, conn.stroke, mark)
	}

	if conn.label != none {

		cetz.draw.content(
			label-pos,
			box(
				fill: options.crossing-fill,
				inset: .2em,
				radius: .2em,
				stroke: if options.debug >= 2 { DEBUG_COLOR + 0.25pt },
				$ #conn.label $,
			),
			anchor: conn.label-anchor,
		)

		if options.debug >= 2 {
			cetz.draw.circle(
				label-pos,
				radius: conn.stroke.thickness,
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


#let find-node-at(nodes, pos) = {
	nodes.filter(node => node.pos == pos)
		.sorted(key: node => node.radius).last()
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

	for arrow in arrows {
		let nodes = arrow.points.map(find-node-at.with(nodes))

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


