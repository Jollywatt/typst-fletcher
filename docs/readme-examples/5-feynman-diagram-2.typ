#diagram(
  mark-scale:130%,
  /*darkmode*/edge-stroke: white,/*end*/
$
	edge("rdr", qbar, "-<|-") edge(#(4, 0), #(3.5, 0.5), b, "-<|-") edge(#(4, 1), #(3.5, 0.5), bbar, "-<|-", label-side:#left)\
 & & edge("d", "-<|-") & & edge(#(3.5, 0.5), #(2, 1), Z', "wave") \
	& & edge(#(3.5, 2.5), #(2, 2), gamma, "wave") \
	edge("rru", q, "-|>-") & \
$)