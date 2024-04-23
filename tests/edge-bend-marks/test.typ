#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	spacing: (10mm, 6mm),
	for (i, bend) in (0deg, 40deg, 80deg, -90deg).enumerate() {
		let x = 2*i
		(
			(">->->->",),
			("<<->>",),
			(">>-<<",),
			(marks: ((inherit: "hook", rev: true), "head")),
			(marks: ((inherit: "hook", rev: true), "hook'")),
			(marks: ("bar", "bar", "bar")),
			(marks: ("||", "||")),
			("<=>",),
			("triple",),
			(marks: ("o", "O")),
			(marks: ((inherit: "solid", rev: true), "solid")),
		).enumerate().map(((i, args)) => {
			edge((x, i), (x + 1, i), ..args, bend: bend)
		}).join()

	}
)
