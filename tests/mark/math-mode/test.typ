#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#table(
	columns: 3,
	align: horizon,
	[Math], [Mark], [Diagram],
	..(
		$->$, $-->$, $<-$, $<->$, $<-->$,
		$->>$, $<<-$,
		$>->$, $<-<$,
		$=>$, $==>$, $<==$, $<=>$, $<==>$,
		$|->$, $|=>$,
		$~>$, $<~$,
		$arrow.hook$, $arrow.hook.l$,
	).map(x => {
		let unicode = x.body.text
		(x,)
		if unicode in fletcher.MARK_SYMBOL_ALIASES {
			let marks = fletcher.MARK_SYMBOL_ALIASES.at(unicode)
			(raw(marks), diagram(edge((0,0), (1,0), marks: marks)))
		} else {
			(text(red)[none!],) * 2
		}
	}).flatten()
)
