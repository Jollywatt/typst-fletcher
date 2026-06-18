#import "flexigrid.typ"
#import "deps.typ": cetz
#import "edges.typ": _edge
#import "nodes.typ": node, _node
#import "parsing.typ": interpret-style-arguments

#let is-space(el) = {
	if el == none { return true }
	if repr(el.func()) == "space" { return true }
	if repr(el.func()) == "sequence" { return el.children.all(is-space) }
	return false
}

#let is-sequence(it) = {
	type(it) == content and repr(it.func()) == "sequence"
}

#let flatten-sequence-to-array(it) = {
	if is-sequence(it) {
		it.children.map(flatten-sequence-to-array).join() + ()
	} else { (it,) }
}


#let extract-nodes-and-edges-from-equation(eq, axes: (ltr, ttb)) = {
	assert(eq.func() == math.equation)
	let terms = flatten-sequence-to-array(eq.body)

	let edges = ()
	let nodes = ()

	let axis-flips = flexigrid.interpret-axes(axes)
	let to-uv(col, row) = {
		let (x, y) = (col, -row)
		if axis-flips.u { x *= -1 }
		if axis-flips.v { y *= -1 }
		if axis-flips.order { (x, y) = (y, x) }
		(x, y)
	}

	// convert math matrix into array-of-arrays matrix
	let matrix = ((none,),)
	let (col, row) = (0, 0)
	for child in terms {
		if child.func() == metadata and "fletcher" in child.value {
			if child.value.fletcher == "node" {
				let args = child.value.args
				args.position = to-uv(col, row)
				nodes.push(_node(..args))
			} else if child.value.fletcher == "edge" {
				let args = child.value.args
				if args.vertices.at(0) == auto { args.vertices.at(0) = to-uv(col, row) }
				if args.vertices.at(-1) == auto { args.vertices.at(-1) = (rel: (1, 0), no-flip: true) }
				edges.push(_edge(..args))
			}
		} else if repr(child.func()) == "linebreak" {
			row += 1
			col = 0
			matrix.push((none,))
		} else if repr(child.func()) == "align-point" {
			col += 1
			matrix.at(-1).push(none)
		} else {
			matrix.at(-1).at(-1) += child
		}
	}

	// turn matrix into an array of nodes
	for (row, items) in matrix.enumerate() {
		for (col, item) in items.enumerate() {
			if is-space(item) { continue }
			nodes.push(node(to-uv(col, row), $item$))
		}
	}

	return (nodes, edges)
}


/// Draw nodes, edges and CeTZ objects in a @flexigrid layout.
///
/// Default styles for nodes and edges may be specified with named arguments
/// such as `node-fill` or `edge-stroke-thickness`.
///
/// ```example
/// #diagram(
/// 	node-shape: rect,
/// 	node-corner-radius: 2pt,
/// 	node-outset: 3pt,
/// 	node-stroke: blue,
/// 	edge-stroke-thickness: 1pt,
/// 	node((0,0), $f$),
/// 	edge(".."),
/// 	node((1,1), $g$),
/// )
/// ```
#let diagram(
	..args,
  axes: (ltr, ttb),
) = {

	let objects = args.pos().map(arg => {
		if type(arg) == content and arg.func() == math.equation {
			extract-nodes-and-edges-from-equation(arg, axes: axes)
		} else {
			arg
		}
	}).filter(a => a != none).join(default: ()).flatten()

	let (named, styles) = interpret-style-arguments(args.named())

	let canvas = cetz.canvas(flexigrid.flexigrid(
		styles,
		objects,
		axes: axes,
		..named,
	))
	
	box(canvas, fill: none, stroke: none)
}
