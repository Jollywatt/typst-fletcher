#let render-example(name) = {
	let src = read("/docs/gallery/" + name + ".typ")
		.replace(regex("@preview/fletcher:\d+\.\d+.\d+"), "/src/exports.typ")
	eval(src, mode: "markup")
}

#(
	"algebra-cube",
	"commutative",
	"digraph",
	"io-flowchart",
	"ml-architecture",
	"node-groups",
	"uml-diagram",
).map(render-example).join()