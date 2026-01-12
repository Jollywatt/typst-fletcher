#import "@preview/fletcher:0.6.0" as fletcher: diagram, node, edge

#let hom = edge.with(in-math: true)
#let obj = node.with(in-math: true)

#diagram(
	spacing: (1em, 3em),
	axes: (rtl, ttb),
	$
		& tau^* (bold(A B)^n R slash.double R^times) hom(->) & bold(B)^n R slash.double R^times \
		obj(X) hom("ur", "-->") hom("=") & X hom(->, tau) hom("u", <-) & bold(B) R^times hom("u", <-)
	$,
	// edge((2,-1), "d,ll,u", "->>", text(blue, $Gamma^*_R$), stroke: blue, label-side: center)
)
