#import "@preview/fletcher:0.5.7" as fletcher: diagram, node, edge
#set page(width: auto, height: auto, margin: 5mm, fill: white)

#diagram(
	spacing: (1em, 3em),
	$
		& tau^* (bold(A B)^n R slash.double R^times) edge(->) & bold(B)^n R slash.double R^times \
		X edge("ur", "-->") edge("=") & X edge(->, tau) edge("u", <-) & bold(B) R^times edge("u", <-)
	$,
	edge((2,1), "d,ll,u", "->>", text(blue, $Gamma^*_R$), stroke: blue, label-side: center)
)