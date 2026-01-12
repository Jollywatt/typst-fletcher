#import "@preview/fletcher:0.6.0" as fletcher: cetz, node, edge

#cetz.canvas({
	let (p1, p2, p3) = ((0,0), (0,1), (1.5,1.5))
	edge(p1, "-<|-", "lld", $q$)
	edge(p1, "-|>-", p2)
	edge(p2, "-|>-", "llu", $overline(q)$)
	edge(p2, "~", p3, $Z'$)
	edge(p3, "-|>-", (rel: (.5, .5)), $b$)
	edge(p3, "-|>-", (rel: (.5, -.5)), $overline(b)$, label-side: bottom)
	edge(p1, "~", "rrd", $gamma$)
})
