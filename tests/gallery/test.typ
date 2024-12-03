#let render-example(name) = {
	let src = read("/docs/gallery/" + name + ".typ")
		.replace(regex("@preview/fletcher:\d+\.\d+.\d+"), "/src/exports.typ")
	eval(src, mode: "markup")
}

#(
	"1-commutative",
	"2-algebra-cube",
	"3-ml-architecture",
	"4-io-flowchart",
	"5-digraph",
	"6-node-groups",
	"7-uml-diagram",
).map(render-example).join()