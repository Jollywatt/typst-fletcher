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


#let extract-nodes-and-edges-from-equation(eq) = {
	assert(eq.func() == math.equation)
	let terms = flatten-sequence-to-array(eq.body)

	let edges = ()
	let nodes = ()

	// convert math matrix into array-of-arrays matrix
	let matrix = ((none,),)
	let (x, y) = (0, 0)
	for child in terms {
		if child.func() == metadata and "fletcher" in child.value {
			if child.value.fletcher == "node" {
				let args = child.value.args
				args.position = (x, y)
				nodes.push(_node(..args))
			} else if child.value.fletcher == "edge" {
				let args = child.value.args
				if args.vertices.at(0) == auto { args.vertices.at(0) = (x, y) }
				// if args.label != none { edge.label = $edge.label$ } // why is this needed?
				if args.vertices.at(-1) == auto { args.vertices.at(-1) = (rel: (1, 0)) }
				// args.node-index = none
				edges.push(_edge(..args))
			}
		} else if repr(child.func()) == "linebreak" {
			y -= 1
			x = 0
			matrix.push((none,))
		} else if repr(child.func()) == "align-point" {
			x += 1
			matrix.at(-1).push(none)
		} else {
			matrix.at(-1).at(-1) += child
		}
	}

	// turn matrix into an array of nodes
	for (y, row) in matrix.enumerate() {
		for (x, item) in row.enumerate() {
			if not is-space(item) {
				nodes.push(node((x, -y), $item$))
			}
		}
	}


	(nodes, edges)
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
#let diagram(..args) = {
	let pos = args.pos().map(arg => {
		if type(arg) == content and arg.func() == math.equation {
			extract-nodes-and-edges-from-equation(arg)
		} else {
			arg
		}
	}).join().flatten()
	let (named, styles) = interpret-style-arguments(args.named())
	let canvas = cetz.canvas(flexigrid.flexigrid(styles, pos, ..named))
	box(canvas, fill: none, stroke: none)
}