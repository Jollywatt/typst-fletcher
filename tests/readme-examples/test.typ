#set page(width: auto, height: auto, margin: 1em, fill: none)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#let render-example(name, darkmode: false) = {
	let src = read("/docs/readme-examples/" + name + ".typ")
	if not darkmode {
		src = src.replace(regex("/\*darkmode\*/[\s\S]*/\*end\*/"), "")
		src = src.replace(regex("\n.*// darkmode"), "")
	}
	let out = eval(src, mode: "markup", scope: (
		fletcher: fletcher,
		diagram: diagram,
		node: node,
		edge: edge,
	))
	if darkmode [
		#set page(fill: black)
		#set text(fill: white)
		#out
	] else {
		out
	}
}

#(
	"feynman-diagram",
	"first-isomorphism-theorem",
	"flowchart-trap",
	"ml-architecture",
	"state-machine",
).map(name => {
	render-example(name, darkmode: false)
	render-example(name, darkmode: true)
}).join()
