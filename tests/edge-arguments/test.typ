#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

// this test contains no visual output
#show: none

= `auto` vertices

#assert(edge(<from>, <to>).value.vertices == (<from>, <to>))
#assert(edge(<from>, auto).value.vertices == (<from>, auto))
#assert(edge(auto, auto).value.vertices == (auto, auto))
#assert(edge().value.vertices == (auto, auto))
#assert(edge(<to>).value.vertices == (auto, <to>))

= Coordinate vertices

#assert(edge((1, 2), (3, 4)).value.vertices == ((1, 2), (3, 4)))
#assert(edge((1, 2), "r").value.vertices == ((1, 2), (rel: (1, 0))))
#assert(edge((1, 2), (rel: (1, 0))).value.vertices == ((1, 2), (rel: (1, 0))))

#assert(edge("r") == edge(auto, "r"))
#assert(edge("r,u") == edge(auto, "r", "u"))
#assert(edge((), (<a>, 50%, <b>)).value.vertices == ((), (<a>, 50%, <b>)))

= Vertices and marks
#assert(edge(<u>, <v>, "->") == edge(vertices: (<u>, <v>), marks: "->"))
#assert(edge(<u>, "->", <v>) == edge(vertices: (<u>, <v>), marks: "->"))
#assert(edge(<v>, "->") == edge(vertices: (auto, <v>), marks: "->"))
#assert(edge("->", <v>) == edge(vertices: (auto, <v>), marks: "->"))

= Marks and labels

#assert(edge() == edge(marks: (), label: none))
#assert(edge([Hi]) == edge(marks: (), label: [Hi]))
#assert(edge("->", [Hi]) == edge(marks: "->", label: [Hi]))
#assert(edge([Hi], "->") == edge(marks: "->", label: [Hi]))

= Error messages
// #edge((), "->", (), "=>")
// #edge((), "r", vertices: (<a>,))
// #edge(2, 3, 4)
// #edge(right, label-side: left)
// #edge([], label: (<a>,))
