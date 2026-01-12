#import "@preview/fletcher:0.6.0" as fletcher: diagram, node, edge

#let hom = edge.with(in-math: true)

#let member(..args) = hom(..args, stroke: none, label: $in$, label-side: center, label-angle: right)

#diagram(
  spacing: 7mm,
  node-inset: 7pt,
$
id_S member() hom("d", |->) &
  "Hom"_cal(C)(S, S) hom(->, script(phi.alt_S)) hom("d", ->, script(f^*), #right) &
  A(S) hom("d", ->, script(A(f)), #left) &
  u_S member("l") hom("d", |->) \
f member() &
  "Hom"_cal(C)(T, S)) hom(->, script(phi.alt_T), #right) &
  A(T) &
  phi.alt_T (f) member("l") \
$)
