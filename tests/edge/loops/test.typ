#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	node((0,0), [Loop], shape: circle, fill: eastern),
	edge((0,0), "->", (0,0), bend: 120deg, layer: 2, loop-angle:   0deg),
	edge((0,0), "->", (0,0), bend: 120deg, layer: 2, loop-angle:  90deg),
	edge((0,0), "->", (0,0), bend: 120deg, layer: 2, loop-angle: 180deg),
	edge((0,0), "->", (0,0), bend: 120deg, layer: 2, loop-angle: 270deg),
	node((1,0), [Boop], shape: circle, fill: orange.mix(red)),
	edge((), (), "->", bend: 120deg, layer: 2, loop-angle: -135deg),
	edge((), (), "->", bend: 120deg, layer: 2, loop-angle: -45deg),
	edge((), (), "->", bend: 120deg, layer: 2, loop-angle: +45deg),
	edge((), (), "->", bend: 120deg, layer: 2, loop-angle: +135deg),
)
