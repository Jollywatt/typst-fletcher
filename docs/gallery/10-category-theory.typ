#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#set page(width: auto, height: auto, margin: 5mm, fill: white)

#let member(..args) = edge(..args, " ", label: $in$, label-side: center, label-angle: right)

#diagram(
  spacing: 7mm,
  node-inset: 7pt,
$
id_S member() edge("d", |->) &
  "Hom"_cal(C)(S, S) edge(->, script(phi.alt_S)) edge("d", ->, script(f^*), #right) &
  A(S) edge("d", ->, script(A(f)), #left) &
  u_S member("l") edge("d", |->) \
f member() &
  "Hom"_cal(C)(T, S)) edge(->, script(phi.alt_T), #right) &
  A(T) &
  phi.alt_T (f) member("l") \
$)