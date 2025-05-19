#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#for pos in (0.2, 20%, 20pt, 2em, 100% - 10pt, (0, 50%)) [
	#raw("label-pos: " + repr(pos))

	#for w in (20mm, 40mm) {
		diagram(spacing: (w, 10mm), {
			node((0,0), [A])
			edge([X], label-pos: pos, label-side: center)
			edge([X], label-pos: pos, label-side: center, bend: -40deg)
			edge((0,0), (20mm, 15mm), ((), "-|", (1,0)), (1,0), [X], label-pos: pos, label-side: center)
			node((1,0), [B])
		})
		linebreak()
	}
	#pagebreak(weak: true)
]