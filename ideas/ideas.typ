#import "/src/exports.typ" as fletcher: *


#set page(width: 10cm, height: auto)
#show heading.where(level: 1): it => pagebreak(weak: true) + it


= Automatic edge and end points

#diagram(edge((0,0), (1,0), [label], "->"))

#diagram(edge((1,0), [label], "-->"))

#diagram(
	node((0,0), [O]),
	node((1,2), [hi]),
	edge([label], "->", bend: 45deg),
	node((2,0), [bye]),
)


= Symbol arrow aliases


#table(
	columns: 4,
	[Math], [Unicode], [Mark], [Diagram],
	..(
		$->$, $<-$, $<->$,
		$=>$, $==>$, $<==$, $<=>$, $<==>$,
		$|->$,
		$->>$, $<<-$,
		$~>$, $<~$
	).map(x => {
		let unicode = x.body.text
		(x, unicode)
		if unicode in MARK_SYMBOL_ALIASES {
			let marks = MARK_SYMBOL_ALIASES.at(unicode)
			(raw(marks), diagram(edge((0,0), (1,0), marks: marks)))
		} else {
			(text(red)[none!],) * 2
		}
	}).flatten()
)

= Demo with tikz-style syntax


#fletcher.diagram(
	axes: (ltr, ttb),
	$
	G edge(f, ->) edge(#(0,1), pi, ->>) & im(f) \
	G slash ker(f) edge(#(1,0), tilde(f), "hook'-->")
$)


#fletcher.diagram(
	axes: (ltr, ttb),
	node((0,0), $G$),
	edge((0,0), (1,0), $f$, "->"),
	edge((0,0), (0,1), $pi$, "->>"),
	node((1,0), $im(f)$),
	node((0,1), $G slash ker(f)$),
	edge((0,1), (1,0), $tilde(f)$, "hook'-->")
)

#diagram(
	spacing: 2cm,
	$A edge(->, bend: #40deg) edge(->, bend: #(-40deg)) & B$,
	edge((0.5, .2), (0.5, -.2), "=>"),
)
