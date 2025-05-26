#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#set page(width: auto, height: auto, margin: 5mm, fill: white)

#diagram(
	mark-scale:130%,
$
	edge("rdr", overline(q), "-<|-")
	edge(#(4, 0), #(3.5, 0.5), b, "-<|-")
	edge(#(4, 1), #(3.5, 0.5), overline(b), "-<|-", label-side:#left) \
	& & edge("d", "-<|-") & & edge(#(3.5, 0.5), #(2, 1), Z', "wave") \
	& & edge(#(3.5, 2.5), #(2, 2), gamma, "wave") \
	edge("rru", q, "-|>-") & \
$)