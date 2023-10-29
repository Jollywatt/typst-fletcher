#import "arrow-diagrams.typ": *



#assert.eq(unitless(4pt), 4)
#assert.eq(unitless(4em), 4)

#assert.eq(vector-unitless((4pt, 5pt)), (4, 5))
#assert.eq(vector-unitless((4em, 5em)), (4, 5))
