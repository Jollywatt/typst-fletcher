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
/// - edge (dictionary): The connector whose end points should be determined.
/// - nodes (pair of dictionaries): The start and end nodes of the connector.
/// -> pair of points
#let get-edge-anchors(edge, nodes) = {
	assert(nodes.len() == 2)
	let center-center-line = nodes.map(node => node.real-pos)

	let v = vector.sub(..center-center-line)
	let θ = vector-angle(v) // approximate angle of connector

	if edge.kind in ("line", "arc") {
		let δ = edge.bend
		let incident-angles = (θ + δ + 180deg, θ - δ)

		let points = zip(nodes, incident-angles).map(((node, θ)) => {
			get-node-anchor(node, θ)
		})

		return points
	} else if edge.kind == "corner" {
		
		zip(nodes, (θ + 180deg, θ)).map(((node, θ)) => {
			get-node-anchor(node, θ)
		})
	}

}

#let draw-edge-label(edge, label-pos, options) = {

	cetz.draw.content(
		label-pos,
		box(
			fill: edge.crossing-fill,
			inset: .2em,
			radius: .2em,
			stroke: if options.debug >= 2 { DEBUG_COLOR + 0.25pt },
			$ #edge.label $,
		),
		anchor: if edge.label-anchor != auto { edge.label-anchor },
	)

	if options.debug >= 2 {
		cetz.draw.circle(
			label-pos,
			radius: 0.75pt,
			stroke: none,
			fill: DEBUG_COLOR,
		)
	}


}

// Get the arrow head adjustment for a given extrusion distance
#let cap-offsets(edge, y) = {
	(0, 1).map(pos => {
		let mark = edge.marks.find(mark => mark.pos == pos)
		if mark == none { return 0pt }
		let x = cap-offset(mark, y/edge.stroke.thickness)
		if pos == 0 and "tail-hang" in mark { x += mark.tail-hang }
		x*edge.stroke.thickness
	})
}


#let draw-edge-line(edge, nodes, options) = {

	// Stroke end points, before adjusting for the arrow heads
	let (from, to) = get-edge-anchors(edge, nodes)

	let θ = vector-angle(vector.sub(to, from))

	// Draw line(s), one for each extrusion shift
	for shift in edge.extrude {
		let shifted-line-points = (from, to).zip(cap-offsets(edge, shift))
			.map(((point, offset)) => vector.add(
				point,
				vector.add(
					// Shift end points lengthways depending on markers
					vector-polar(offset, θ),
					// Shift line sideways (for double line effects, etc) 
					vector-polar(shift, θ + 90deg),
				)
			))

		cetz.draw.line(
			..shifted-line-points,
			stroke: edge.stroke,
		)
	}

	// get the origin/anchor point for a mark at a given position along the line
	let mark-origin(mark) = {
		let tail = edge.stroke.thickness*mark.at("tail-hang", default: 0)
		let from = vector.add(from, vector-polar(tail, θ))
		let origin = vector.lerp(from, to, mark.pos)
		origin
	}


	// Draw marks
	for mark in edge.marks {
		let pt = mark-origin(mark)
		draw-arrow-cap(pt, θ, edge.stroke, mark, debug: options.debug >= 4)
	}

	// Draw label
	if edge.label != none {

		// Choose label anchor based on connector direction
		if edge.label-side == auto {
			edge.label-side = if calc.abs(θ) > 90deg { left } else { right }
		}
		let label-dir = if edge.label-side == right { +1 } else { -1 }

		if edge.label-anchor == auto {
			edge.label-anchor = angle-to-anchor(θ - label-dir*90deg)
		}
	
		edge.label-sep = to-abs-length(edge.label-sep, options.em-size)
		let label-pos = vector.add(
			vector.lerp(from, to, edge.label-pos),
			vector-polar(edge.label-sep, θ + label-dir*90deg),
		)
		draw-edge-label(edge, label-pos, options)
	}


	
}

#let draw-edge-arc(edge, nodes, options) = {

	// Stroke end points, before adjusting for the arrow heads
	let (from, to) = get-edge-anchors(edge, nodes)
	let θ = vector-angle(vector.sub(to, from))

	// Determine the arc from the stroke end points and bend angle
	let (center, radius, start, stop) = get-arc-connecting-points(from, to, edge.bend)

	let bend-dir = if edge.bend > 0deg { +1 } else { -1 }

	// Draw arc(s), one for each extrusion shift
	for shift in edge.extrude {

		// Adjust arc angles to accomodate for cap offsets
		let (δ-start, δ-stop) = cap-offsets(edge, shift)
			.map(arclen => -bend-dir*arclen/radius*1rad)

		cetz.draw.arc(
			center,
			radius: radius + shift,
			start: start + δ-start,
			stop: stop + δ-stop,
			anchor: "center",
			stroke: edge.stroke,
		)
	}



	// Draw marks
	for mark in edge.marks {

		let tail = edge.stroke.thickness*mark.at("tail-hang", default: 0)
		let δθ = bend-dir*tail/radius*1rad
		let θ = lerp(start - δθ, stop, mark.pos)
		let φ = θ - bend-dir*90deg

		// Tail hang correction
		// Rotate caps with tail-hang so that they to not hang off the arc
		φ += bend-dir*calc.asin(tail/radius/2)

		let pt = vector.add(center, vector-polar(radius, θ))

		draw-arrow-cap(pt, φ, edge.stroke, mark, debug: options.debug >= 4)
	}




	// Draw label
	if edge.label != none {

		if edge.label-side == auto {
			edge.label-side = if edge.bend > 0deg { left } else { right }
		}
		let label-dir = if edge.label-side == left { +1 } else { -1 }

		if edge.label-anchor == auto {
			// Choose label anchor based on connector direction
			edge.label-anchor = angle-to-anchor(θ + label-dir*90deg)
		}
		
		edge.label-sep = to-abs-length(edge.label-sep, options.em-size)
		let label-pos = vector.add(
			center,
			vector-polar(
				radius + label-dir*bend-dir*edge.label-sep,
				lerp(start, stop, edge.label-pos),
			)
		)

		draw-edge-label(edge, label-pos, options)
	}


	// Draw debug stuff
	if options.debug >= 3 {
		for (cell, point) in zip(nodes, (from, to)) {
			cetz.draw.line(
				cell.real-pos,
				point,
				stroke: DEBUG_COLOR + 0.1pt,
			)
		}

		cetz.draw.arc(
			center,
			radius: radius,
			start: start,
			stop: stop,
			anchor: "center",
			stroke: DEBUG_COLOR + edge.stroke.thickness/4,
		)

	}


}


#let draw-edge-corner(edge, nodes, options) = {

	let θ = vector-angle(vector.sub(..edge.points))
	let θ-floor = calc.floor(θ/90deg)*90deg
	let θ-ceil = calc.ceil(θ/90deg)*90deg

	// Angles at which arrow heads point
	let cap-angles = if edge.corner == left {
		(θ-ceil + 180deg, θ-floor + 180deg)
	} else if edge.corner == right {
		(θ-floor + 180deg, θ-ceil + 180deg)
	}

	let cap-points = zip(nodes, cap-angles, (0, 1)).map(((node, φ, dir)) => {
		// todo: defocus?
		get-node-anchor(node, φ + dir*180deg)
	})


	let i = if edge.corner == left { 1 } else { 0 }
	let corner-point = if calc.even(calc.floor(θ/90deg) + i) {
		(cap-points.at(1).at(0), cap-points.at(0).at(1))
	} else {
		(cap-points.at(0).at(0), cap-points.at(1).at(1))
	}

	let verts = (
		cap-points.at(0),
		corner-point,
		cap-points.at(1),
	)

	// Compute the three points of the right angle,
	// taking into account extrusions and mark offsets
	let get-vertices(shift) = {
		// normal vectors to the (first, second) segment
		let (a, b) = cap-angles.map(θ => vector-polar(shift, θ + 90deg))
		
		// apply extrusions
		let verts = verts.zip((a, vector.add(a, b), b))
			.map(((v, o)) => vector.add(v, o))

		// apply mark offsets
		let offsets = cap-offsets(edge, shift).zip(cap-angles, (180deg, 0deg))
			.map(((offset, θ, dir)) => vector-polar(offset, θ+dir))

		(
			vector.sub(verts.at(0), offsets.at(0)),
			verts.at(1),
			vector.add(verts.at(2), offsets.at(1)),
		)

	}

	// Draw right-angled line(s), one for each extrusion shift
	for shift in edge.extrude {
		cetz.draw.line(
			..get-vertices(shift),
			stroke: edge.stroke,
		)
	}

	// Draw marks
	let verts = get-vertices(0pt)

	for mark in edge.marks {
		let i = int(mark.pos >= 0.5)
		let pt = vector.lerp(verts.at(i), verts.at(i + 1), 2*mark.pos - i)
		draw-arrow-cap(pt, cap-angles.at(i), edge.stroke, mark, debug: options.debug >= 4)
	}

	// Draw label
	if edge.label != none {

		if edge.label-side == auto { edge.label-side = edge.corner }
		let label-dir = if edge.label-side == left { +1 } else { -1 }

		if edge.label-anchor == auto {
			// Choose label anchor based on connector direction
			edge.label-anchor = angle-to-anchor(θ + label-dir*90deg)
		}

		let v = get-vertices(label-dir*edge.label-sep)
		let label-pos = zip(..v).map(coords => {
			lerp-at(coords, 2*edge.label-pos)
		})

		draw-edge-label(edge, label-pos, options)

	}

}

#let draw-edge(edge, nodes, options) = {
	edge.marks = interpret-marks(edge.marks)
	if edge.kind == "line" { draw-edge-line(edge, nodes, options) }
	else if edge.kind == "arc" { draw-edge-arc(edge, nodes, options) }
	else if edge.kind == "corner" { draw-edge-corner(edge, nodes, options) }
	else { panic(edge.kind) }
}


#let draw-node(node, options) = {
	if node.label == none { return }

	if node.stroke != none or node.fill != none {

		for (i, offset) in node.extrude.enumerate() {
			let fill = if i == 0 { node.fill } else { none }

			if node.shape == "rect" {
				let radii = vector.scale(node.size, 0.5).map(x => x + offset)
				cetz.draw.rect(
					..rect-at(node.real-pos, radii),
					stroke: node.stroke,
					fill: fill,
				)
			}
			if node.shape == "circle" {
				cetz.draw.circle(
					node.real-pos,
					radius: node.radius + offset,
					stroke: node.stroke,
					fill: fill,
				)
			}
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



#let find-node-at(nodes, pos) = {
	nodes.filter(node => node.pos == pos)
		.sorted(key: node => node.radius).last()
}

#let draw-diagram(
	grid,
	nodes,
	edges,
	options,
) = {

	for node in nodes {
		draw-node(node, options)
	}

	for edge in edges {
		let nodes = edge.points.map(find-node-at.with(nodes))

		let intersection-stroke = if options.debug >= 2 {
			(paint: DEBUG_COLOR, thickness: 0.25pt)
		}

		// assert(edge.marks.all(mark => type(mark) == dictionary), message: repr(edge))
		draw-edge(edge, nodes, options)
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


