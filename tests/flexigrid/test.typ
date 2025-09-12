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

#page[
  Cell size interpolation
  #let N = 10
  #let figs = range(N + 1).map(t => {
    let u = t/N
    diagram(debug: "grid.cells", {
      import cetz.draw: *
      set-style(node: (fill: yellow))
      node((0,0), [Hello\ World])
      node((1,0), [!])
      node((u,0), stroke: 1pt, fill: white)[Flexigrids]
    })
  })
  #stack(dir: ttb, spacing: 5mm, ..figs)
]