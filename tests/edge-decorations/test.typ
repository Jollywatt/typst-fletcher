#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(spacing: 4em, $
	A edge(<->, "wave") & B edge(<->, "zigzag") & C edge(<->, "coil")
$)

#diagram(spacing: (2em, 3em), $
	e^- edge("dr", "-<|-") & & & & & edge("dl", "-|>-") e^+ \
	& edge("wave") & edge(gamma, "wave", bend: #80deg) edge("wave", bend: #(-80deg)) & edge("wave") \
	e^+ edge("ur", "-|>-") & & & & & edge("ul", "-<|-") e^- \
$)


#diagram(spacing: (1cm, 0mm), $
	A edge(~>) & B \
	A edge(<~) & B \
	A edge("<~>") & B \
	A edge(">~<") & B \
$)