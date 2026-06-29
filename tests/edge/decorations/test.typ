#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#cetz.canvas({
  import cetz.draw: *
  for l in (0.5, 1, 1.5, 2) {
    edge(line((0,0), (l,0)), decorate: "wave")
    translate(y: -0.5)
  }
})

#pagebreak()

With marks

#diagram(edge("<~>", decorate: (wavelength: 2))) \
#diagram(edge("<<~>>", decorate: (wavelength: 2))) \
#diagram(edge("<<<~>>>", decorate: (wavelength: 2))) \

#pagebreak()

With marks and styles

#diagram(edge("rrr", "<~>", decorate: (shorten: 4))) \


#pagebreak()

Style inheritance

#cetz.canvas({
  import cetz.draw: *
  for a in (5, 10, 20) {
    set-style(edge: (decorate: (amplitude: a)))
    translate(x: 1)
    edge("wave")
  }
})

#cetz.canvas({
  import cetz.draw: *
  for a in ("wave", "zigzag", "coil", "square") {
    set-style(edge: (decorate: (
      kind: a,
      smooth: 0,
      shorten: 0,
    )))
    translate(x: 1)
    edge()
  }
})

#pagebreak()

#diagram(
  node-fill: yellow,
  node-shape: rect,
  cetz.draw.set-style(edge: (corner-radius: 1em)),
  node((0,0), [A], <A>),
  edge("r,d,r", "<~>"),
  edge("dd,rr,u", decorate: (kind: "zigzag", smooth: (3,0), shorten: (0, 5pt))),
  node((2,1), [B], <B>),
)

