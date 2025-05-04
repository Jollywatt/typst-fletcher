#let render-example(name) = {
	let src = read("/docs/gallery/" + name + ".typ")
		.replace(regex("@preview/fletcher:\d+\.\d+.\d+"), "/src/exports.typ")
	eval(src, mode: "markup")
}

#(
	"01-commutative",
	"02-algebra-cube",
	"03-ml-architecture",
	"04-io-flowchart",
	"05-digraph",
	"06-node-groups",
	"07-uml-diagram",
	"08-tree",
	"09-feynman-diagram",
	"10-category-theory",
).map(render-example).join()