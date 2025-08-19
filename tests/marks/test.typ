#set page(width: auto, height: auto, margin: 1em)
#import "/src/deps.typ": cetz
#import "/src/marks.typ": test-mark
#import "/src/default-marks.typ": DEFAULT_MARKS

#test-mark

#let length = 100pt
#set rect(inset: 0pt, width: length, fill: yellow.lighten(70%))
#rect(layout(size => size.width))
#rect(test-mark(">>", stroke: 3pt, length: length))

#for (name, m) in DEFAULT_MARKS.pairs() {
  page(align(center, {
    raw(name)
    test-mark(m, debug: 3)
  }))
}
