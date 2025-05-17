#import "utils.typ": *
#import "marks.typ": *
#import "coords.typ": uv-to-xy

#let DEBUG_COLOR = rgb("f008")
#let DEBUG_COLOR2 = rgb("0f08")

#let draw-debug(objs) = {
	cetz.draw.floating(objs)
}

#let draw-node-outline(node) = {
	cetz.draw.group({
		cetz.draw.translate(node.pos.xyz)
		(node.shape)(node, node.outset)
	})
}

#let draw-node(node, debug: 0) = {

	let result = {
		if node.stroke != none or node.fill != none or not node.auto-shape {
			cetz.draw.group({
				cetz.draw.translate(node.pos.xyz)
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
			let ε = 1e-10pt // temp fix for https://github.com/Jollywatt/typst-fletcher/issues/64
			cetz.draw.content(
				node.pos.xyz,
				box(
					// wrapping label in a box allows user to control its alignment
					align(center + horizon, node.label),
					stroke: if debug >= 3 { DEBUG_COLOR2 + 0.25pt },
					width:  node.size.at(0) - 2*node.inset + ε,
					height: node.size.at(1) - 2*node.inset,
				),
				anchor: "center",
			)
		}
	}

	if node.layer != 0 { result = cetz.draw.on-layer(node.layer, result) }

	(node.post)(result) // post-process (e.g., hide)

	// Draw debug stuff
	if debug >= 1 {
		// dot at node anchor
		draw-debug(cetz.draw.circle(
			node.pos.xyz,
			radius: 0.5pt,
			fill: DEBUG_COLOR,
			stroke: none,
		))
	}

	if debug >= 2 and node.radius != 0pt {
		// node bounding rectangle
		draw-debug({
			cetz.draw.rect(
				..rect-at(node.pos.xyz, node.size),
				stroke: DEBUG_COLOR + .1pt,
			)

			// node anchoring outline (what edges snap to)
			cetz.draw.set-style(stroke: DEBUG_COLOR2 + 0.25pt)
			draw-node-outline(node)
		})
	}

	if debug >= 3 and "enclosed-vertices" in node {
		draw-debug(node.enclosed-vertices.map(pos => {
			cetz.draw.circle(pos, radius: node.inset, stroke: 0.1pt + blue)
		}).join())
	}
}


/// Draw an edge label at point along a curve.
///
/// Label is drawn near the point `curve(edge.label-pos)`, respecting the label
/// options of `edge()` such as #param[edge][label-side] and
/// #param[edge][label-angle].
///
/// - edge (dictionary): Edge object. Must include:
///   - `label-pos`
///   - `label-sep`
///   - `label-side`
///   - `label-anchor`
///   - `label-angle`
///   - `label-wrapper`
/// - curve (function): Parametric curve $RR -> RR^2$ describing the shape of
///   the edge in $x y$ coordinates.
#let place-edge-label-on-curve(edge, curve, debug: 0) = {

	let curve-point = curve(edge.label-pos.position)
	let curve-point-ε = curve(edge.label-pos.position + 1e-3%)

	let θ = wrap-angle-180(angle-between(curve-point, curve-point-ε))
	let θ-normal = θ + if edge.label-side == right { +90deg } else { -90deg }

	if type(edge.label-angle) == alignment {
		edge.label-angle = θ - (
			right: 0deg,
			top: 90deg,
			left: 180deg,
			bottom: 270deg,
		).at(repr(edge.label-angle))

	} else if edge.label-angle == auto {
		edge.label-angle = θ
		if calc.abs(edge.label-angle) > 90deg {
			edge.label-angle += 180deg
		}
	}

	if edge.label-anchor == auto {
		edge.label-anchor = angle-to-anchor(θ-normal - edge.label-angle)
	}

	let label-pos = (to: curve-point, rel: (θ-normal, -edge.label-sep))

	cetz.draw.content(
		label-pos,
		box(
			{
				set text(edge.label-size)
				(edge.label-wrapper)(edge)
			},
			stroke: if debug >= 2 { DEBUG_COLOR2 + 0.25pt },
		),
		angle: edge.label-angle,
		anchor: if edge.label-anchor != auto { edge.label-anchor },
	)

	if debug >= 2 {
		draw-debug(cetz.draw.circle(
			label-pos,
			radius: 0.75pt,
			stroke: none,
			fill: DEBUG_COLOR2,
		))
	}
}


// Get the arrow head adjustment for a given extrusion distance.
//
// Returns a pair `(from, to)` of distances.
// If `from < 0pt` and `to > 0pt`, the path length of the edge increases.
#let cap-offsets(edge, y) = {
	(0, 1).map(pos => {
		let mark = edge.marks.find(mark => calc.abs(mark.pos - pos) < 1e-3)
		if mark == none { return 0pt }

		let is-tip = (pos == 0) == mark.rev
		let sign = if mark.rev { -1 } else { +1 }

		let x = cap-offset(
			mark + (tip: is-tip),
			sign*y/edge.stroke.thickness,
		)

		let origin = if is-tip { mark.tip-origin } else { mark.tail-origin }
		x -= origin*float(mark.scale)

		sign*x*edge.stroke.thickness
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
	let θ = angle-between(from, to)

	// Draw line(s), one for each extrusion shift
	for shift in edge.extrude {

		let offsets = cap-offsets(edge, shift)
		let points = (from, to).zip(offsets)
			.map(((point, offset)) => {
				// Shift line sideways (for multi-stroke effect)
				point = (rel: (θ + 90deg, shift), to: point)
				// Shift end points lengthways depending on marks
				point = (rel: (θ, offset), to: point)
				point
			})

		let obj = cetz.draw.line(
			..points,
			stroke: edge.stroke,
		)

		with-decorations(edge, obj)
	}

	// Draw marks
	let total-path-len = vector-len(vector.sub(from, to))
	let curve(t) = {
		if calc.abs(total-path-len) > 1e-3pt {
			t = relative-to-float(t, len: total-path-len)
			vector.lerp(from, to, t)
		} else { from }
	}

	for mark in edge.marks {
		place-mark-on-curve(mark, curve, stroke: edge.stroke, debug: debug >= 3)
	}

	// Draw label
	// This edge only has a single segment, so don't draw the label unless it's 
	// placed on segment 0. This means that when calling this function for the
	// individual segments of an edge (`draw-edge-polyline`), the `segment` field
	// of `label-pos` must be set to 0.
	if edge.label != none and edge.label-pos.segment == 0 {

		// Choose label anchor based on edge direction,
		// preferring to place labels above the edge
		if edge.label-side == auto {
			edge.label-side = if calc.abs(θ) < 90deg { left } else { right }
		}

		place-edge-label-on-curve(edge, curve, debug: debug)
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

		// Adjust arc angles to accommodate for cap offsets
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

		with-decorations(edge, obj)
	}

	// Draw marks
	let total-path-len = calc.abs(stop - start)/1rad*radius
	let curve(t) = {
		t = relative-to-float(t, len: total-path-len)
		vector.add(center, vector-polar(radius, lerp(start, stop, t)))
	}
	for mark in edge.marks {
		place-mark-on-curve(mark, curve, stroke: edge.stroke, debug: debug >= 3)
	}

	// Draw label
	if edge.label != none and edge.label-pos.segment == 0 {

		if edge.label-side == auto {
			// Choose label side to be on outside of arc
			edge.label-side = if edge.bend > 0deg { left } else { right }
		}

		place-edge-label-on-curve(edge, curve, debug: debug)

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
		angle-between(vert, vert-next)
	})


	// round corners
	let calculate-rounded-corner(i) = {
		let pt = verts.at(i)
		let Δθ = wrap-angle-180(θs.at(i) - θs.at(i - 1))
		let dir = if Δθ > 0deg { +1 } else { -1 } // +1 if ccw, -1 if cw


		let θ-normal = θs.at(i - 1) + Δθ/2 + 90deg  // direction to center of curvature

		let radius = edge.corner-radius
		// radius *= 90deg/calc.max(calc.abs(Δθ), 45deg) // visual adjustment so that tighter bends have smaller radii
		radius *= 1 + calc.cos(Δθ)
		// skip correcting the corner radius for extruded strokes if there's no stroke at all
		if edge.extrude != () {
			radius += if dir > 0 { calc.max(..edge.extrude) } else { -calc.min(..edge.extrude) }
		}
		radius *= dir // ??? makes math easier or something

		if calc.abs(Δθ) > 179deg {
			// singular line; skip arc
			(
				arc-center: pt,
				arc-radius: 0*radius,
				start: θs.at(i - 1) - 90deg,
				delta: wrap-angle-180(Δθ),
				line-shift: 0*radius, // distance from vertex to beginning of arc
			)
		} else {

			// distance from vertex to center of curvature
			let dist = radius/calc.cos(Δθ/2)

			(
				arc-center: vector.add(pt, vector-polar(dist, θ-normal)),
				arc-radius: radius,
				start: θs.at(i - 1) - 90deg,
				delta: wrap-angle-180(Δθ),
				line-shift: radius*calc.tan(Δθ/2), // distance from vertex to beginning of arc
			)
		}

	}

	let rounded-corners
	if edge.corner-radius != none {
		rounded-corners = range(1, θs.len()).map(calculate-rounded-corner)
	}

	let lerp-scale(t, i) = {
		if type(t) in (int, float) {
			let τ = t*n-segments - i
			if (0 < τ and τ <= 1 or
				i == 0 and τ <= 0 or
				i == n-segments - 1 and 1 < τ) { τ }
		} else  {
			t = as-relative(t)
			let τ = lerp-scale(float(t.ratio), i)
			if τ != none {τ *100% + t.length }
		}
	}

	let debug-stroke = edge.stroke.thickness/4 + DEBUG_COLOR2

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
					inherit: "bar",
					pos: 0,
					angle: 90deg - Δθ/2,
					hide: true,
				))
			}
			if i < θs.len() - 1 {
				let Δθ = θs.at(i + 1) - θs.at(i)
				marks.push((
					inherit: "bar",
					pos: 1,
					angle: 90deg + Δθ/2,
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
					if calc.abs(delta) > 1deg {
						cetz.draw.arc(
							arc-center,
							radius: arc-radius - d,
							start: start,
							delta: delta,
							anchor: "origin",
							stroke: stroke-with-phase(phase + Δphase),
						)
					}

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

		marks = marks.map(resolve-mark)

		// distribute original marks across segments
		marks += edge.marks.map(mark => {
			mark.pos = lerp-scale(mark.pos, i)
			mark
		}).filter(mark => mark.pos != none)

		// If the current segment is the one where the label is placed, keep the
		// label (but change its segment to 0 because `draw-edge-line` will consider
		// this segment a single-segment edge and only draw labels on segment 0).
		// Otherwise, draw no label.
		let label-options = if i == edge.label-pos.segment {
			(label-pos: edge.label-pos + (segment: 0), label: edge.label)
		} else {
			(label: none)
		}


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
				point.at(1) *= -1 // CETZ Y AXIS
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
		cetz.draw.translate(node.pos.xyz)
		(node.shape)(node, node.outset)
	})
	let dummy-line = cetz.draw.line(
		node.pos.xyz,
		(rel: (θ, 10*node.radius))
	)

	find-farthest-intersection(outline + dummy-line, node.pos.xyz, callback)
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
	let θ = angle-between(from, to) + 90deg

	// TODO: do defocus adjustment sensibly
	if nodes.at(0).len() == 1 {
		from = vector.add(from, defocus-adjustment(nodes.at(0).at(0), θ - 90deg))
	}
	if nodes.at(1).len() == 1 {
		to = vector.add(to, defocus-adjustment(nodes.at(1).at(0), θ + 90deg))

	}


	let dummy-line = cetz.draw.line(from, to)

	let intersection-objects = nodes.map(nodes => {
		cetz.draw.group(nodes.map(draw-node-outline).join())
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
	let θ = angle-between(from, to)
	let θs = (θ + edge.bend, θ - edge.bend + 180deg)

	let dummy-lines = (from, to).zip(θs, nodes)
		.map(((point, φ, node)) => cetz.draw.line(
			point,
			vector.add(point, vector-polar(10cm, φ)), // ray emanating from node
		))

	let intersection-objects = nodes.zip(dummy-lines).map(((nodes, dummy-line)) => {
		cetz.draw.group(nodes.map(draw-node-outline).join())
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

	let dummy-lines = end-segments.map(points => cetz.draw.line(..points))

	let intersection-objects = nodes.zip(dummy-lines).map(((nodes, dummy-line)) => {
		cetz.draw.group(nodes.map(draw-node-outline).join())
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


#let draw-edge(edge, ..args) = {
	let obj = if edge.kind == "line" {
		draw-anchored-line(edge, ..args)
	} else if edge.kind == "arc" {
		draw-anchored-arc(edge, ..args)
	} else if edge.kind == "poly" {
		draw-anchored-polyline(edge, ..args)
	} else { error("Invalid edge kind #0.", edge.kind) }

	if edge.layer != 0 { obj = cetz.draw.on-layer(edge.layer, obj)}

	obj
}



/// Draw diagram coordinate axes.
///
/// - grid (dictionary): Dictionary specifying the diagram's grid, containing:
///   - `origin: (u-min, v-min)`, the minimum values of elastic coordinates,
///   - `flip: (x, y, xy)`, the axes orientation (see `interpret-axes()`),
///   - `centers: (x-centers, y-centers)`, the physical offsets of each row and each column,
///   - `cell-sizes: (x-sizes, y-sizes)`, the physical sizes of each row and
///     each column.
#let draw-debug-axes(grid, debug: false, floating: true) = {

	let (x-lims, y-lims) = range(2).map(axis => (
		grid.centers.at(axis).at( 0) - grid.cell-sizes.at(axis).at( 0)/2,
		grid.centers.at(axis).at(-1) + grid.cell-sizes.at(axis).at(-1)/2,
	))

	let (u-min, v-min) = grid.origin

	let (u-len, v-len) = grid.centers.map(array.len)
	if grid.flip.xy { (u-len, v-len) = (v-len, u-len) }
	let v-range = range(v-min, v-min + v-len)
	let u-range = range(u-min, u-min + u-len)

	if grid.flip.x { u-range = u-range.rev() }
	if grid.flip.y { v-range = v-range.rev() }
	if grid.flip.xy { (u-range, v-range) = (v-range, u-range) }

	import cetz.draw
	let objs = draw.group({
		let (a, b) = array.zip(x-lims, y-lims)
		if a == b { b = vector.add(b, (1e-3pt, 1e-3pt)) }
		draw.rect(a, b, stroke: DEBUG_COLOR + .5pt)

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

		if debug {
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
		}

	})

	if floating {
		cetz.draw.floating(objs)
	} else {
		objs
	}
}

// Find candidate nodes that an edge should snap to
//
// Returns an array of zero or more nodes. False positives are acceptable.
#let find-snapping-nodes(grid, nodes, key) = {
	if type(key) == label {
		return nodes.filter(node => node.name == key)
	}

	if type(key) == array and key.len() == 2 {

		let xy-pos = key
		let candidates = nodes.filter(node => {
			if node.snap == false { return false }
			point-is-in-rect(xy-pos, (
				center: node.pos.xyz,
				size: node.size,
			))
		})

		if candidates.len() > 0 {
			// filter out nodes with lower snap priority
			let max-snap-priority = calc.max(..candidates.map(node => node.snap))
			candidates = candidates.filter(node => node.snap == max-snap-priority)
		}

		return candidates
	}

	error("Couldn't find node corresponding to #0 in diagram.", key)
}


// return a pair of arrays of nodes to which the edge should snap
#let find-nodes-for-edge(grid, nodes, edge) = {
	let select-nodes = find-snapping-nodes.with(grid, nodes)
	let first-last(x) = (x.at(0), x.at(-1))
	array.zip(
		edge.snap-to,
		first-last(edge.vertices),
		first-last(edge.final-vertices),
	).map(((given, vertex, xy)) => {
		if given == none { return () } // user explicitly disabled snapping
		let key = if type(vertex) == label { vertex } else { xy }
		select-nodes(map-auto(given, key))
	})
}

#let draw-diagram(
	grid,
	nodes,
	edges,
	debug: 0,
) = {

	for edge in edges {
		let nodes = find-nodes-for-edge(grid, nodes, edge)
		draw-edge(edge, nodes, debug: debug)
	}

	for node in nodes {
		draw-node(node, debug: debug)
	}

	if debug >= 1 {
		draw-debug-axes(grid, debug: debug >= 2)
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
