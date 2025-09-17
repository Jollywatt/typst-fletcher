#set page(width: auto, height: auto, margin: 1em)
#import "/src/flexigrid.typ": split-style-argument, interpret-style-arguments

#for (arg, path) in (
  "node-fill": ("node", "fill"),
  "node-radius": ("node", "radius"),
  "node-circle-radius": ("node", "circle", "radius"),
  "node-corner-radius": ("node", "corner-radius"),
) {
  assert.eq(split-style-argument(arg), path)
}

