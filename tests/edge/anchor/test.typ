#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#let label(it) = par(leading: 0.5pt, text(0.25em, raw(repr(it).replace(" + ", "\n"))))
#cetz.canvas({
  let obj = cetz.draw.merge-path({
    cetz.draw.line((0,0), (1,0), (2,1), (2,0), (3,0))
    cetz.draw.arc-through((3,0), (3.5,0.5), (3,1))
  })
  obj
  cetz.draw.get-ctx(ctx => {
    let (drawables, element) = cetz.process.element(ctx, obj.first())
    let drawable = drawables.first()
    let anchors = fletcher.edges.edge-anchor-handler.with(ctx, drawable, element.anchors)

    for it in (0, "50%", "75pc", 1, 1.5, -1, 8pt, 100% - 8pt, 50% + 8pt, "end") {
      let pt = anchors(it)
      cetz.draw.circle(pt, radius: 4pt, fill: white, stroke: 0.2pt)
      cetz.draw.content(pt, label(it), padding: 0.3em)
    }
    
  })
})