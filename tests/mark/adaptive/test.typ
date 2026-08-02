#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#let extrudes = (
  (0,),
  (-2, 2),
  (-4, 0, 4),
  (10, 5, 0, -5, -10),
  (5, 3,),
  (-5, -3,),
)

#let test-adaptive(mark) = stack(..extrudes.map(e => {
  show: rect.with(height: 1cm, stroke: 0.5pt + red)
  show: align.with(center + horizon)
  diagram(edge(mark, extrude: e))
}))

#stack(
  dir: ltr,
  test-adaptive("->"),
  test-adaptive("harpoon-harpoon"),
  test-adaptive("harpoons-harpoons"),
  test-adaptive("hook-hook'"),
  test-adaptive("hooks-hooks"),
)