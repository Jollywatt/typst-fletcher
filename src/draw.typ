#import "utils.typ": *
#import "marks.typ": *


#let draw-edge-label(edge, label-pos, options) = {
	cetz.draw.content(
		label-pos,
		box(
			// cetz seems to sometimes squash the content, causing a line-
			// break, when padding is present...
			fill: edge.label-fill,
			stroke: if options.debug >= 2 { DEBUG_COLOR + 0.25pt },
			radius: .2em,
			pad(.2em)[#edge.label],
		),
		padding: .2em,
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
		let mark = edge.marks.find(mark => calc.abs(mark.pos - pos) < 1e-3)
		if mark == none { return 0pt }
		let x = cap-offset(mark, (2*pos - 1)*y/edge.stroke.thickness)

		let rev = mark.at("rev", default: false)
		if pos == int(rev) { x -= mark.at("inner-len", default: 0) }
		if rev { x = -x - mark.at("outer-len", default: 0) }
		if pos == 0 { x += mark.at("outer-len", default: 0) }

		x*edge.stroke.thickness
	})
}


#let draw-edge-line(edge, (from, to), options) = {

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

	// Draw marks
	let curve(t) = vector.lerp(from, to, t)
	for mark in edge.marks {
		place-arrow-cap(curve, edge.stroke, mark, debug: options.debug >= 4)
	}

	// Draw label
	if edge.label != none {

		// Choose label anchor based on edge direction,
		// preferring to place labels above the edge
		if edge.label-side == auto {
			edge.label-side = if calc.abs(θ) < 90deg { left } else { right }
		}

		let label-dir = if edge.label-side == left { +1 } else { -1 }

		if edge.label-anchor == auto {
			edge.label-anchor = angle-to-anchor(θ - label-dir*90deg)
		}
	
		let label-pos = vector.add(
			vector.lerp(from, to, edge.label-pos),
			vector-polar(edge.label-sep, θ + label-dir*90deg),
		)
		draw-edge-label(edge, label-pos, options)
	}


	
}

#let draw-edge-arc(edge, (from, to), options) = {


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
			anchor: "origin",
			stroke: edge.stroke,
		)
	}


	// Draw marks
	let curve(t) = vector.add(center, vector-polar(radius, lerp(start, stop, t)))
	for mark in edge.marks {
		place-arrow-cap(curve, edge.stroke, mark, debug: options.debug >= 4)
	}


	// Draw label
	if edge.label != none {

		if edge.label-side == auto {
			// Choose label side to be on outside of arc
			edge.label-side = if edge.bend > 0deg { left } else { right }
		}
		let label-dir = if edge.label-side == left { +1 } else { -1 }

		if edge.label-anchor == auto {
			// Choose label anchor based on edge direction
			let θ = vector-angle(vector.sub(to, from))
			edge.label-anchor = angle-to-anchor(θ - label-dir*90deg)
		}
		
		let label-pos = vector.add(
			center,
			vector-polar(
				radius + label-dir*bend-dir*edge.label-sep,
				lerp(start, stop, edge.label-pos),
			)
		)

		draw-edge-label(edge, label-pos, options)
	}

}


#let draw-edge-polyline(edge, (from, to), options) = {

	let verts = (
		from,
		..edge.vertices,
		to,
	)
	let n-segments = verts.len() - 1

	// angles of each segment
	let θs = range(1, verts.len()).map(i => {
		let (vert, vert-next) = (verts.at(i - 1), verts.at(i))
		vector-angle(vector.sub(vert-next, vert))
	})


	// round corners

	// i literally don't know how this works
	let calculate-rounded-corner(i) = {
		let pt = verts.at(i)
		let Δθ = wrap-angle-180(θs.at(i) - θs.at(i - 1))
		let dir = sign(Δθ) // +1 if ccw, -1 if cw

		let θ-normal = θs.at(i - 1) + Δθ/2 + 90deg  // direction to center of curvature

		let radius = edge.corner-radius
		radius *= calc.abs(90deg/Δθ) // visual adjustment so that tighter bends have smaller radii
		radius += if dir > 0 { calc.max(..edge.extrude) } else { -calc.min(..edge.extrude) }
		radius *= dir // ??? makes math easier or something

		let dist = radius/calc.cos(Δθ/2) // distance from vertex to center of curvature

		(
			arc-center: vector.add(pt, vector-polar(dist, θ-normal)),
			arc-radius: radius,
			start: θs.at(i - 1) - 90deg,
			delta: wrap-angle-180(Δθ),
			line-shift: radius*calc.tan(Δθ/2), // distance from vertex to beginning of arc
		)
	}

	let rounded-corners
	if edge.corner-radius != none {
		rounded-corners = range(1, θs.len()).map(calculate-rounded-corner)
	}
	
	let lerp-scale(t, i) = {
		let τ = t*n-segments - i
		if 0 < τ and τ <= 1 or i == 0 and τ <= 0 or i == n-segments - 1 and 1 < τ { τ }
	}

	let debug-stroke = edge.stroke.thickness/4 + green

	// phase keeps track of how to offset dash patterns
	// to ensure continuity between segments
	let phase = 0pt
	let stroke-with-phase(phase) = stroke-to-dict(edge.stroke) + (
		dash: if type(edge.stroke.dash) == dictionary {
			(array: edge.stroke.dash.array, phase: phase)
		}
	)

	// draw each segment
	for i in range(verts.len() - 1) {
		let (from, to) = (verts.at(i), verts.at(i + 1))
		let marks = ()

		let Δphase = 0pt

		if edge.corner-radius == none {

			// add phantom marks to ensure segment joins are clean
			if i > 0 {
				let Δθ = θs.at(i) - θs.at(i - 1) 
				marks.push((
					kind: "bar",
					pos: 0,
					angle: Δθ/2,
					hide: true,
				))
			}
			if i < θs.len() - 1 {
				let Δθ = θs.at(i + 1) - θs.at(i)
				marks.push((
					kind: "bar",
					pos: 1,
					angle: Δθ/2,
					hide: true,
				))
			}

			Δphase += vector-len(vector.sub(from, to))

		} else { // rounded corners

			if i > 0 {
				// offset start of segment to give space for previous arc
				let (line-shift,) = rounded-corners.at(i - 1)
				from = vector.add(from, vector-polar(line-shift, θs.at(i)))
			}

			if i < θs.len() - 1 {

				let (arc-center, arc-radius, start, delta, line-shift) = rounded-corners.at(i)
				to = vector.add(to, vector-polar(-line-shift, θs.at(i)))

				Δphase += vector-len(vector.sub(from, to))

				for d in edge.extrude {
					cetz.draw.arc(
						arc-center,
						radius: arc-radius - d,
						start: start,
						delta: delta,
						anchor: "origin",
						stroke: stroke-with-phase(phase + Δphase),
					)

					if options.debug >= 4 {
						cetz.draw.on-layer(1, cetz.draw.circle(
							arc-center,
							radius: arc-radius - d,
							stroke: debug-stroke,
						))

					}
				}

				Δphase += delta/1rad*arc-radius

			}


		}

		// distribute original marks across segments
		marks += edge.marks.map(mark => {
			mark.pos = lerp-scale(mark.pos, i)
			mark
		}).filter(mark => mark.pos != none)

		let label-pos = lerp-scale(edge.label-pos, i)
		let label-options = if label-pos == none { (label: none) }
		else { (label-pos: label-pos, label: edge.label) }


		draw-edge-line(
			edge + (
				kind: "line",
				marks: marks,
				stroke: stroke-with-phase(phase),
			) + label-options,
			(from, to),
			options,
		)

		phase += Δphase

	}


	if options.debug >= 4 {
		cetz.draw.line(
			..verts,
			stroke: debug-stroke,
		)
	}
}



/// Of all the intersection points within a set of CeTZ objects, find the one
/// which is farthest from a target point and pass it to a callback.
///
/// If no intersection points are found, use the target point itself.
///
/// - objects (cetz, none): Objects to search within for intersections. If
///  `none`, callback is immediately called with `target`.
/// - target (point): Target point to sort intersections by proximity with, and
///  to use as a fallback if no intersections are found.
#let find-farthest-intersection(objects, target, callback) = {

	if objects == none { return callback(target) }
	
	let node-name = "intersection-finder"
	cetz.draw.hide(cetz.draw.intersections(node-name, objects))

	cetz.draw.get-ctx(ctx => {

		let calculate-anchors = ctx.nodes.at(node-name).anchors
		let anchor-names = calculate-anchors(())
		let anchor-points = anchor-names.map(calculate-anchors)
			.map(point => {
				// funky disagreement between coordinate systems??
				point.at(1) *= -1
				vector-2d(vector.scale(point, 1cm))
			}).sorted(key: point => vector-len(vector.sub(point, target)))

		let anchor = anchor-points.at(-1, default: target)

		callback(anchor)

	})

}

#let find-anchor-pair(intersection-objects, targets, callback) = {
	let (from-group, to-group) = intersection-objects
	let (from-point, to-point) = targets
	find-farthest-intersection(from-group, from-point, from-anchor => {
		find-farthest-intersection(to-group, to-point, to-anchor => {
			callback((from-anchor, to-anchor))
		})
	})
	
}

#let draw-anchored-line(edge, nodes, options) = {
	let (from, to) = (edge.from, edge.to).map(options.get-coord)

	// edge shift
	let (δ-from, δ-to) = edge.shift
	let θ = vector-angle(vector.sub(to, from)) + 90deg
	from = vector.add(from, vector-polar(δ-from, θ))
	to = vector.add(to, vector-polar(δ-to, θ))


	if options.debug >= 3 {
		cetz.draw.line(
			from,
			to,
			stroke: DEBUG_COLOR + edge.stroke.thickness/4,
		)
	}

	let dummy-line = cetz.draw.line(
		from,
		to,
	)

	let intersection-objects = nodes.map(node => {
		if node == none { return }
		cetz.draw.group({
			cetz.draw.translate(node.real-pos)
			(node.shape)(node, node.outset)
		})
		dummy-line
	})


	find-anchor-pair(intersection-objects, (from, to), anchors => {
		draw-edge-line(edge, anchors, options)
	})

}

#let draw-anchored-arc(edge, nodes, options) = {
	let (from, to) = (edge.from, edge.to).map(options.get-coord)
	let θ = vector-angle(vector.sub(to, from))
	let θs = (θ + edge.bend, θ - edge.bend + 180deg)

	let (δ-from, δ-to) = edge.shift
	from = vector.add(from, vector-polar(δ-from, θs.at(0) + 90deg))
	to = vector.add(to, vector-polar(δ-to, θs.at(1) - 90deg))

	let dummy-lines = (from, to).zip(θs)
		.map(((point, φ)) => cetz.draw.line(
			point,
			vector.add(point, vector-polar(10cm, φ)),
		))

	let intersection-objects = nodes.zip(dummy-lines).map(((node, dummy-line)) => {
		if node == none { return }
		cetz.draw.group({
			cetz.draw.translate(node.real-pos)
			(node.shape)(node, node.outset)
		})
		dummy-line
	})

	find-anchor-pair(intersection-objects, (from, to), anchors => {
		draw-edge-arc(edge, anchors, options)
	})
}

#let draw-anchored-polyline(edge, nodes, options) = {
	let (from, to) = (edge.from, edge.to).map(options.get-coord)
	
	let end-segments = (
		(from, edge.vertices.at(0)),
		(edge.vertices.at(-1), to),
	)

	let θs = (
		vector-angle(vector.sub(..end-segments.at(0))),
		vector-angle(vector.sub(..end-segments.at(1))),
	)

	let δs = edge.shift.zip(θs).map(((d, θ)) => vector-polar(d, θ + 90deg))

	end-segments = end-segments.zip(δs).map(((segment, δ)) => {
		segment.map(point => vector.add(point, δ))
	})


	let dummy-lines = end-segments.map(points => cetz.draw.line(..points))

	let intersection-objects = nodes.zip(dummy-lines).map(((node, dummy-line)) => {
		if node == none { return }
		cetz.draw.group({
			cetz.draw.translate(node.real-pos)
			(node.shape)(node, node.outset)
		})
		dummy-line
	})

	find-anchor-pair(intersection-objects, (from, to), anchors => {
		draw-edge-polyline(edge, anchors, options)
	})

	// get-node-anchors(nodes, θs, anchors => {
	// 	draw-edge-polyline(edge, anchors, options)
	// }, shifts: δs)
}

#let draw-anchored-corner(edge, nodes, options) = {

	let (from, to) = (edge.from, edge.to).map(options.get-coord)
	let θ = vector-angle(vector.sub(to, from))

	let bend-dir = (
		if edge.corner == right { true }
		else if edge.corner == left { false }
		else { panic("Edge corner option must be left or right.") }
	)

	let θ-floor = calc.floor(θ/90deg)*90deg
	let θ-ceil = calc.ceil(θ/90deg)*90deg
	let θs = if bend-dir {
		(θ-ceil, θ-floor + 180deg)
	} else {
		(θ-floor, θ-ceil + 180deg)
	}

	let corner-point = if calc.even(calc.floor(θ/90deg) + int(bend-dir)) {
		(to.at(0), from.at(1))
	} else {
		(from.at(0), to.at(1))
	}

	let edge-options = (
		vertices: (corner-point,),
		label-side: if bend-dir { left } else { right },
	)

	draw-anchored-polyline(edge + edge-options, nodes, options)
	// get-node-anchors(nodes, θs, anchors => {
	// 	draw-edge-polyline(edge + edge-options, anchors, options)
	// })
}

#let draw-edge(edge, nodes, options) = {
	edge.marks = interpret-marks(edge.marks)
	if edge.kind == "line" { draw-anchored-line(edge, nodes, options) }
	else if edge.kind == "arc" { draw-anchored-arc(edge, nodes, options) }
	else if edge.kind == "corner" { draw-anchored-corner(edge, nodes, options) }
	else if edge.kind == "poly" { draw-anchored-polyline(edge, nodes, options) }
	else { panic(edge.kind) }
}



#let draw-node(node, options) = {

	if node.stroke != none or node.fill != none {

		cetz.draw.group({
			cetz.draw.translate(node.real-pos)
			for (i, extrude) in node.extrude.enumerate() {
				cetz.draw.set-style(
					fill: if i == 0 { node.fill },
					stroke: node.stroke,
				)
				(node.shape)(node, extrude)
			}

		})
	}

	if node.label != none {
		cetz.draw.content(node.real-pos, node.label, anchor: "center")
	}

	// Draw debug stuff
	if options.debug >= 1 {
		// dot at node anchor
		cetz.draw.circle(
			node.real-pos,
			radius: 0.5pt,
			fill: DEBUG_COLOR,
			stroke: none,
		)
	}

	// Show anchor outline
	if options.debug >= 2 and node.radius != 0pt {
		cetz.draw.group({
			cetz.draw.translate(node.real-pos)
			cetz.draw.set-style(
				stroke: DEBUG_COLOR + .1pt,
				fill: none,
			)
			(node.shape)(node, node.outset)
		})

		cetz.draw.rect(
			..rect-at(node.real-pos, node.size),
			stroke: DEBUG_COLOR + .1pt,
		)
	}
}


#let draw-debug-axes(grid) = {

	cetz.draw.scale(
		x: grid.scale.at(0),
		y: grid.scale.at(1),
	)
	// cetz panics if rect is zero area
	if grid.bounding-size.all(x => x != 0pt) {
		cetz.draw.rect(
			(0,0),
			grid.bounding-size,
			stroke: DEBUG_COLOR + 0.25pt
		)
	}

	for (axis, coord) in ((0, (x,y) => (x,y)), (1, (y,x) => (x,y))) {

		for (i, x) in grid.centers.at(axis).enumerate() {
			let size = grid.sizes.at(axis).at(i)

			// coordinate label
			cetz.draw.content(
				coord(x, -.5em),
				text(fill: DEBUG_COLOR, size: .7em)[#(grid.origin.at(axis) + i)]
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

#let find-node-at(nodes, pos) = {
	nodes.filter(node => {
		// node must be within a one-unit block around pos
		vector.sub(node.pos, pos).all(Δ => calc.abs(Δ) < 0.5)
	})
		.sorted(key: node => vector.len(vector.sub(node.pos, pos)))
		.at(0, default: none)
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
		// find notes to snap to (can be none!)
		let nodes = (edge.from, edge.to).map(find-node-at.with(nodes))
		draw-edge(edge, nodes, options)
	}

	if options.debug >= 1 {
		draw-debug-axes(grid)
	}

}


