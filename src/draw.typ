#import "utils.typ": *
#import "marks.typ": *

#let DEBUG_COLOR = rgb("f008")

#let draw-edge-label(edge, label-pos, debug: 0) = {
	cetz.draw.content(
		label-pos,
		box(
			// cetz seems to sometimes squash the content, causing a line-
			// break, when padding is present...
			fill: edge.label-fill,
			stroke: if debug >= 2 { DEBUG_COLOR + 0.25pt },
			radius: .2em,
			pad(.2em)[#edge.label],
		),
		padding: .2em,
		anchor: if edge.label-anchor != auto { edge.label-anchor },
	)

	if debug >= 2 {
		cetz.draw.circle(
			label-pos,
			radius: 0.75pt,
			stroke: none,
			fill: DEBUG_COLOR,
		)
	}


}

// Get the arrow head adjustment for a given extrusion distance.
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

#let with-decorations(edge, path) = {
	if edge.decorations == none { return path }

	let has-mark-at(t) = edge.marks.find(mark => calc.abs(mark.pos - t) < 1e-3 ) != none

	let decor = edge.decorations.with(stroke: edge.stroke)

	// TODO: should this be an absolute offset, not 10% the path length?
	let ε = 1e-3 // cetz assertions sometimes fail from floating point errors
	decor = decor.with(
		start: if has-mark-at(0) { 0.1 } else { ε } * 100%,
		stop: if has-mark-at(1) { 0.9 } else { 1 - ε } * 100%,
	)

	decor(path)
}

/// Draw a straight edge.
///
/// - edge (dictionary): The edge object, a dictionary, containing:
///   - `vertices`: an array of two points, the line's start and end points.
///   - `extrude`: An array of extrusion lengths to apply a multi-stroke effect
///    with.
///   - `stroke`: The stroke style.
///   - `marks`: An array of marks to draw along the edge.
///   - `label`: Content for label.
///   - `label-side`, `label-pos`, `label-sep`, and `label-anchor`.
/// - debug (int): Level of debug details to draw.
#let draw-edge-line(edge, debug: 0) = {
	let (from, to) = edge.final-vertices
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


		with-decorations(edge, cetz.draw.line(
			..shifted-line-points,
			stroke: edge.stroke,
		))


	}

	// Draw marks
	let curve(t) = vector.lerp(from, to, t)
	for mark in edge.marks {
		place-arrow-cap(curve, edge.stroke, mark, debug: debug >= 4)
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
		draw-edge-label(edge, label-pos, debug: debug)
	}

}


/// Draw a bent edge.
///
/// - edge (dictionary): The edge object, a dictionary, containing:
///   - `vertices`: an array of two points, the arc's start and end points.
///   - `bend`: The angle of the arc.
///   - `extrude`: An array of extrusion lengths to apply a multi-stroke effect
///    with.
///   - `stroke`: The stroke style.
///   - `marks`: An array of marks to draw along the edge.
///   - `label`: Content for label.
///   - `label-side`, `label-pos`, `label-sep`, and `label-anchor`.
/// - debug (int): Level of debug details to draw.
#let draw-edge-arc(edge, debug: 0) = {
	let (from, to) = edge.final-vertices

	// Determine the arc from the stroke end points and bend angle
	let (center, radius, start, stop) = get-arc-connecting-points(from, to, edge.bend)

	let bend-dir = if edge.bend > 0deg { +1 } else { -1 }

	// Draw arc(s), one for each extrusion shift
	for shift in edge.extrude {

		// Adjust arc angles to accomodate for cap offsets
		let (δ-start, δ-stop) = cap-offsets(edge, shift)
			.map(arclen => -bend-dir*arclen/radius*1rad)

		let obj = cetz.draw.arc(
			center,
			radius: radius + shift,
			start: start + δ-start,
			stop: stop + δ-stop,
			anchor: "origin",
			stroke: edge.stroke,
		)

		if edge.decorations == none { obj }
		else {
			let decor = edge.decorations.with(stroke: edge.stroke)
			decor(obj)
		}
	}


	// Draw marks
	let curve(t) = vector.add(center, vector-polar(radius, lerp(start, stop, t)))
	for mark in edge.marks {
		place-arrow-cap(curve, edge.stroke, mark, debug: debug >= 4)
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

		draw-edge-label(edge, label-pos, debug: debug)
	}

}



/// Draw a multi-segment edge
///
/// - edge (dictionary): The edge object, a dictionary, containing:
///   - `vertices`: an array of at least two points to draw segments between.
///   - `corner-radius`: Radius of curvature between segments.
///   - `extrude`: An array of extrusion lengths to apply a multi-stroke effect
///    with.
///   - `stroke`: The stroke style.
///   - `marks`: An array of marks to draw along the edge.
///   - `label`: Content for label.
///   - `label-side`, `label-pos`, `label-sep`, and `label-anchor`.
/// - debug (int): Level of debug details to draw.
#let draw-edge-polyline(edge, debug: 0) = {

	let verts = edge.final-vertices
	let n-segments = verts.len() - 1

	// angles of each segment
	let θs = range(n-segments).map(i => {
		let (vert, vert-next) = (verts.at(i), verts.at(i + 1))
		assert(vert != vert-next, message: "Adjacent vertices must be distinct.")
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
	for i in range(n-segments) {
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

					if debug >= 4 {
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
				final-vertices: (from, to),
				marks: marks,
				stroke: stroke-with-phase(phase),
			) + label-options,
			debug: debug,
		)

		phase += Δphase

	}


	if debug >= 4 {
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
/// - objects (cetz array, none): Objects to search within for intersections. If
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

#let find-anchor-pair((from-group, to-group), (from-point, to-point), callback) = {
	find-farthest-intersection(from-group, from-point, from-anchor => {
		find-farthest-intersection(to-group, to-point, to-anchor => {
			callback((from-anchor, to-anchor))
		})
	})

}

/// Get the anchor point around a node outline at a certain angle.
#let get-node-anchor(node, θ, callback) = {
	let outline = cetz.draw.group({
		cetz.draw.translate(node.final-pos)
		(node.shape)(node, node.outset)
	})
	let dummy-line = cetz.draw.line(
		node.final-pos,
		(rel: (θ, 10*node.radius))
	)

	find-farthest-intersection(outline + dummy-line, node.final-pos, callback)
}

/// Return the anchor point for an edge connecting to a node with the "defocus"
/// adjustment.
///
/// Basically, for very long/wide nodes, don't make edges coming in from all
/// angles go to the exact node center, but "spread them out" a bit.
///
/// See https://www.desmos.com/calculator/irt0mvixky.
#let defocus-adjustment(node, θ) = {
	if node == none { return (0pt, 0pt) }
	let μ = calc.pow(node.aspect, node.defocus)
	(
		calc.max(0pt, node.size.at(0)/2*(1 - 1/μ))*calc.cos(θ),
		calc.max(0pt, node.size.at(1)/2*(1 - μ/1))*calc.sin(θ),
	)

}


#let draw-anchored-line(edge, nodes, debug: 0) = {
	let (from, to) = edge.final-vertices

	// // apply edge shift
	// let (δ-from, δ-to) = edge.shift
	let θ = vector-angle(vector.sub(to, from)) + 90deg
	// from = vector.add(from, vector-polar(δ-from, θ))
	// to = vector.add(to, vector-polar(δ-to, θ))

	// TODO: do defocus adjustment sensibly
	from = vector.add(from, defocus-adjustment(nodes.at(0), θ - 90deg))
	to = vector.add(to, defocus-adjustment(nodes.at(1), θ + 90deg))


	let dummy-line = cetz.draw.line(
		from,
		to,
	)

	let intersection-objects = nodes.map(node => {
		if node == none { return }
		cetz.draw.group({
			cetz.draw.translate(node.final-pos)
			(node.shape)(node, node.outset)
		})
		dummy-line
	})


	find-anchor-pair(intersection-objects, (from, to), anchors => {
		let obj = draw-edge-line(edge + (
			final-vertices: anchors,
		), debug: debug)
		(edge.post)(obj) // post-process (e.g., hide)
	})

}


#let draw-anchored-arc(edge, nodes, debug: 0) = {
	let (from, to) = edge.final-vertices

	let θ = vector-angle(vector.sub(to, from))
	let θs = (θ + edge.bend, θ - edge.bend + 180deg)

	// let (δ-from, δ-to) = edge.shift
	// from = vector.add(from, vector-polar(δ-from, θs.at(0) + 90deg))
	// to = vector.add(to, vector-polar(δ-to, θs.at(1) - 90deg))

	let dummy-lines = (from, to).zip(θs)
		.map(((point, φ)) => cetz.draw.line(
			point,
			vector.add(point, vector-polar(10cm, φ)), // ray emanating from node
		))

	let intersection-objects = nodes.zip(dummy-lines).map(((node, dummy-line)) => {
		if node == none { return }
		cetz.draw.group({
			cetz.draw.translate(node.final-pos)
			(node.shape)(node, node.outset)
		})
		dummy-line
	})

	find-anchor-pair(intersection-objects, (from, to), anchors => {
		let obj = draw-edge-arc(edge + (final-vertices: anchors), debug: debug)
		(edge.post)(obj) // post-process (e.g., hide)
	})
}


#let draw-anchored-polyline(edge, nodes, debug: 0) = {
	assert(edge.vertices.len() >= 2, message: "Polyline requires at least two vertices")
	let verts = edge.final-vertices
	let (from, to) = (edge.final-vertices.at(0), edge.final-vertices.at(-1))

	let end-segments = (
		edge.final-vertices.slice(0, 2), // first two vertices
		edge.final-vertices.slice(-2), // last two vertices
	)

	// let θs = (
	// 	vector-angle(vector.sub(..end-segments.at(0))),
	// 	vector-angle(vector.sub(..end-segments.at(1))),
	// )

	// let δs = edge.shift.zip(θs).map(((d, θ)) => vector-polar(d, θ + 90deg))

	// end-segments = end-segments.zip(δs).map(((segment, δ)) => {
	// 	segment.map(point => vector.add(point, δ))
	// })

	// // the `shift` option is nicer if it shifts the entire segment, not just the first vertex
	// // first segment
	// edge.final-vertices.at(0) = vector.add(edge.final-vertices.at(0), δs.at(0))
	// edge.final-vertices.at(1) = vector.add(edge.final-vertices.at(1), δs.at(0))
	// // last segment
	// edge.final-vertices.at(-2) = vector.add(edge.final-vertices.at(-2), δs.at(1))
	// edge.final-vertices.at(-1) = vector.add(edge.final-vertices.at(-1), δs.at(1))


	let dummy-lines = end-segments.map(points => cetz.draw.line(..points))

	let intersection-objects = nodes.zip(dummy-lines).map(((node, dummy-line)) => {
		if node == none { return }
		cetz.draw.group({
			cetz.draw.translate(node.final-pos)
			(node.shape)(node, node.outset)
		})
		dummy-line
	})

	find-anchor-pair(intersection-objects, (from, to), anchors => {
		let edge = edge
		edge.final-vertices.at(0) = anchors.at(0)
		edge.final-vertices.at(-1) = anchors.at(1)
		let obj = draw-edge-polyline(edge, debug: debug)
		(edge.post)(obj) // post-process (e.g., hide)
	})

}


#let convert-edge-corner-to-poly(edge) = {

	let (from, to) = edge.final-vertices
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

	edge + (
		kind: "poly",
		final-vertices: (from, corner-point, to),
		label-side: if bend-dir { left } else { right },
	)
}

#let draw-edge(edge, nodes, ..args) = {
	if edge.extrude.len() == 0 { return } // no line to draw
	edge.marks = interpret-marks(edge.marks)
	if edge.kind == "line" { draw-anchored-line(edge, nodes, ..args) }
	else if edge.kind == "arc" { draw-anchored-arc(edge, nodes, ..args) }
	else if edge.kind == "poly" { draw-anchored-polyline(edge, nodes, ..args) }
	else { panic("Invalid edge kind " + repr(edge.kind)) }
}



#let draw-node(node, debug: 0) = {

	let result = {
		if node.stroke != none or node.fill != none {

			cetz.draw.group({
				cetz.draw.translate(node.final-pos)
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
			cetz.draw.content(node.final-pos, node.label, anchor: "center")
		}

	}
	(node.post)(result) // post-process (e.g., hide)

	// Draw debug stuff
	if debug >= 1 {
		// dot at node anchor
		cetz.draw.circle(
			node.final-pos,
			radius: 0.5pt,
			fill: DEBUG_COLOR,
			stroke: none,
		)
	}

	// Show anchor outline
	if debug >= 2 and node.radius != 0pt {
		cetz.draw.group({
			cetz.draw.translate(node.final-pos)
			cetz.draw.set-style(
				stroke: DEBUG_COLOR + .1pt,
				fill: none,
			)
			(node.shape)(node, node.outset)
		})

		cetz.draw.rect(
			..rect-at(node.final-pos, node.size),
			stroke: DEBUG_COLOR + .1pt,
		)
	}
}


#let draw-debug-axes(grid) = {

	// cetz panics if rect is zero area
	if grid.bounding-size.all(x => x != 0pt) {
		cetz.draw.rect(
			(0,0),
			element-wise-mul(grid.bounding-size, grid.scale),
			stroke: DEBUG_COLOR + 0.25pt
		)
	}



	let (σx, σy) = grid.scale
	for (axis, coord) in ((0, (x,y) => (σx*x,σy*y)), (1, (y,x) => (σx*x,σy*y))) {

		for (i, x) in grid.centers.at(axis).enumerate() {
			let size = grid.cell-sizes.at(axis).at(i)

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

/// Draw diagram coordinate axes.
///
/// - grid (dictionary): Dictionary specifying the diagram's grid, containing:
///   - `origin: (u-min, v-min)`, the minimum values of elastic coordinates,
///   - `flip: (x, y, xy)`, the axes orientation (see `interpret-axes()`),
///   - `centers: (x-centers, y-centers)`, the physical offsets of each row and each column,
///   - `cell-sizes: (x-sizes, y-sizes)`, the physical sizes of each row and
///     each column.
#let draw-debug-axes(grid) = {

	let (x-lims, y-lims) = range(2).map(axis => (
		grid.centers.at(axis).at( 0) - grid.cell-sizes.at(axis).at( 0)/2,
		grid.centers.at(axis).at(-1) + grid.cell-sizes.at(axis).at(-1)/2,
	))

	let (u-min, v-min) = grid.origin

	let xy-lens = grid.centers.map(array.len)
	let (u-len, v-len) = if grid.flip.xy { xy-lens.rev() } else { xy-lens }
	let v-range = range(v-min, v-min + v-len)
	let u-range = range(u-min, u-min + u-len)

	if grid.flip.x { u-range = u-range.rev() }
	if grid.flip.y { v-range = v-range.rev() }
	if grid.flip.xy { (u-range, v-range) = (v-range, u-range) }

	import cetz.draw
	draw.group({
		draw.rect(
			..array.zip(x-lims, y-lims),
			stroke: DEBUG_COLOR + .5pt,
		)

		draw.set-style(stroke: (
			paint: DEBUG_COLOR,
			thickness: .3pt,
			dash: "densely-dotted",
		))

		for axis in range(2) {
			let swap(a, b) = if axis != 1 { (a, b) } else { (b, a) }
			let x-range = (u-range, v-range).at(axis)
			let (min, max) = (y-lims, x-lims).at(axis)
			for (i, x) in x-range.enumerate() {
				// coordinate line
				draw.line(
					swap(grid.centers.at(axis).at(i), min),
					swap(grid.centers.at(axis).at(i), max),
				)
				// size bracket
				let size = grid.cell-sizes.at(axis).at(i)
				draw.rect(
					(to: swap(grid.centers.at(axis).at(i), min), rel: swap(-size/2, 0)),
					(to: swap(grid.centers.at(axis).at(i), min), rel: swap(+size/2, -1pt)),
					fill: DEBUG_COLOR,
					stroke: none,
				)
				// coordinate label
				draw.content(
					(to: swap(grid.centers.at(axis).at(i), min), rel: swap(0, -.2em)),
					text(fill: DEBUG_COLOR, size: .7em)[#x],
					anchor: if axis == 0 { "north" } else { "east" },
				)
			}
		}

		let (u-label, v-label) = if grid.flip.xy { ($arrow$, $arrow.t.twohead$) } else { ($u$, $v$) }

		let dir-to-arrow(dir) = {
			     if dir == ltr { $arrow.r$ }
			else if dir == rtl { $arrow.l$ }
			else if dir == ttb { $arrow.b$ }
			else if dir == btt { $arrow.t$ }
		}

		draw.content(
			(x-lims.at(0), y-lims.at(0)),
			pad(0.2em, text(0.5em, DEBUG_COLOR, $(#grid.axes.map(dir-to-arrow).join($,$))$)),
			anchor: "north-east"
		)


	})

}

#let find-node-at(nodes, pos) = {
	nodes.filter(node => {
		// node must be within a one-unit block around pos
		vector.sub(node.pos, pos).all(Δ => calc.abs(Δ) < 1)
	})
		.sorted(key: node => vector.len(vector.sub(node.pos, pos)))
		.at(0, default: none)
}

#let find-node(nodes, key) = {
	if type(key) == label {
		let node = nodes.find(node => node.name == key)
		assert(node != none, message: "Couldn't resolve name " + repr(key))
		node
	} else if type(key) == array {
		find-node-at(nodes, key)
	} else {
		panic("Couldn't find node corresponding to " + repr(key))
	}
}

#let draw-diagram(
	grid,
	nodes,
	edges,
	debug: 0,
) = {

	for edge in edges {
		// find start/end notes to snap to (each can be none!)
		let nodes = (
			map-auto(edge.snap-to.at(0), edge.vertices.at(0)),
			map-auto(edge.snap-to.at(1), edge.vertices.at(-1)),
		).map(find-node.with(nodes))
		draw-edge(edge, nodes, debug: debug)
	}

	for node in nodes {
		draw-node(node, debug: debug)
	}

	if debug >= 1 {
		draw-debug-axes(grid)
	}

}

/// Make diagram contents invisible, with or without affecting layout. Works by
/// wrapping final drawing objects in `cetz.draw.hide`.
///
/// #example(```
/// rect(diagram({
/// 	fletcher.hide({
/// 		node((0,0), [Can't see me])
/// 		edge("->")
/// 	})
/// 	node((1,1), [Can see me])
/// }))
/// ```)
///
/// - objects (content, array): Diagram objects to hide.
/// - bounds (bool): If `false`, layout is as if the objects were never there;
///   if `true`, the layout treats the objects is present but invisible.
#let hide(objects, bounds: true) = {
	if type(objects) == array { objects = objects.join() }
	let seq = objects + []
	seq.children.map(child => {
		if child.func() == metadata {
			let value = child.value
			value.post = cetz.draw.hide.with(bounds: bounds)
			metadata(value)
		} else {
			child
		}
	}).join()
}