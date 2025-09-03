#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz


#page[
  Gutter defines minimum distance between cells.

  #let gutter = 1cm

  #set box(fill: yellow)
  #diagram(debug: "grid.cells", gutter: gutter, {
    import cetz.draw: *
    node((0,0), box(width: 1cm, height: 1cm), inset: 0)
    node((1,0), box(width: 2cm, height: 1cm), inset: 0)
    node((1,1), box(width: 1cm, height: 5mm), inset: 0)
    node((3,0))
    for u in range(-2, 5) {
      for v in range(-1, 3) {
        circle((uv: (u,v)), radius: 1pt)
      }
    }
  })

  This block...
  
  #box(width: gutter, height: gutter)

  ...should fit between all cells above without touching.
]