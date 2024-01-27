#import "/src/exports.typ" as fletcher: *


#set page(width: 10cm, height: auto)
#show heading.where(level: 1): it => pagebreak(weak: true) + it


= Wishlist

```typc

edge(->) == edge(auto, auto, "->")
```


= Automatic edge positions

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
		if unicode in EDGE_ARGUMENT_SHORTHANDS {
			let marks = EDGE_ARGUMENT_SHORTHANDS.at(unicode).marks
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