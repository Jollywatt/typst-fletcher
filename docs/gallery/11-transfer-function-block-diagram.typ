#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge, cetz

#set page(width: auto, height: auto, margin: 5mm)

#let black-circle(node, extrude, ..extra) = {
  cetz.draw.circle((0, 0), radius: node.radius/6) 
}

#let white-circle(node, extrude, ..extra) = {
  cetz.draw.circle((0, 0), radius: node.radius/3)
}

#let black-circle-node(in_node) = {
  node(in_node, shape: black-circle, fill: black, stroke: 1pt, $$)
}

#let white-circle-node(in_node) = {
  node(in_node, shape:white-circle, stroke: 1pt, $$)
}

#let block-node(in_node, content) = {
  node(in_node, content, shape: rect, stroke: 1pt)
}



#diagram(
  debug: false,
  spacing: (5mm, 5mm),
  mark-scale: 60%,
  edge-stroke: 0.75pt,
  edge-corner-radius: 0pt,
  // Nodes Positions
  let w              = (0,0),
  let sum_point_1    = (2,0),
  let branch_point_1 = (3,0),
  let block_1        = (4,0),
  let block_2        = (4, 1),
  let block_3        = (5, 1),
  let sum_point_2    = (6,0),
  let i              = (8,0),
  let w_input        = (8,2),
  
  // Node materialization
  node(w, $omega$),
  white-circle-node(sum_point_1),
  black-circle-node(branch_point_1),
  block-node(block_1, $K_P$),
  block-node(block_2, $K_I$),
  block-node(block_3, $1/s$),
  white-circle-node(sum_point_2),
  node(i, $I "[A]"$),
  node(w_input, $omega_(i n p u t)$),
  
  // Enclosing box
  node(enclose: (sum_point_1, (6,1)), stroke: (thickness:1pt, dash: "dashed", ), snap: false, extrude: (10)),
  
  // Edges materialization
  edge(w, sum_point_1, "-|>", label: $+$, label-pos: 90%, label-sep: 0pt, label-size: 7pt),
  edge(sum_point_1, branch_point_1, "-"),
  edge(branch_point_1, block_1, "-|>"),
  edge(branch_point_1, "d,r", "-|>"),
  edge(block_1, sum_point_2,"-|>", label: $+$, label-pos: 95%, label-sep: 0pt, label-size: 7pt),
  edge(block_2, block_3,"-|>"),
  edge(block_3, "r,u", "-|>", label: $+$, label-pos: 97%, label-sep: 0pt, label-size: 7pt),
  edge(sum_point_2, i, "-|>"),
  edge(w_input, "l,l,l,l,l,l,u,u", "-|>", label: $-$, label-pos: 99%, label-sep: 1pt, label-size: 7pt),
)
