#set page(width: auto, height: auto, margin: 1em)
#import "/src/edge.typ": normalize-label-pos

// this test contains no visual output
#show: none

#let assert-position-almost-equal(a, b) = {
  a.position = a.position + 0pt + 0%
  b.position = b.position + 0pt + 0%

  let dl = calc.abs(a.position.length - b.position.length)
  let dr = calc.abs(a.position.ratio - b.position.ratio)

  assert(a.segment == b.segment
    and dl < 1e-3pt
    and dr < 1e-3%
  , message: repr(a) + " != " + repr(b))
}

= `normalize-label-pos`

== Odd number of segments

#assert-position-almost-equal(normalize-label-pos(-10%, 5), (segment: 0, position: -50%))
#assert-position-almost-equal(normalize-label-pos(0%, 5), (segment: 0, position: 0%))
#assert-position-almost-equal(normalize-label-pos(10%, 5), (segment: 0, position: 50%))
#assert-position-almost-equal(normalize-label-pos(20%, 5), (segment: 0, position: 100%))
#assert-position-almost-equal(normalize-label-pos(30%, 5), (segment: 1, position: 50%))
#assert-position-almost-equal(normalize-label-pos(40%, 5), (segment: 1, position: 100%))
#assert-position-almost-equal(normalize-label-pos(50%, 5), (segment: 2, position: 50%))
#assert-position-almost-equal(normalize-label-pos(60%, 5), (segment: 2, position: 100%))
#assert-position-almost-equal(normalize-label-pos(70%, 5), (segment: 3, position: 50%))
#assert-position-almost-equal(normalize-label-pos(80%, 5), (segment: 3, position: 100%))
#assert-position-almost-equal(normalize-label-pos(90%, 5), (segment: 4, position: 50%))
#assert-position-almost-equal(normalize-label-pos(100%, 5), (segment: 4, position: 100%))
#assert-position-almost-equal(normalize-label-pos(110%, 5), (segment: 4, position: 150%))

== Even number of segments

#assert-position-almost-equal(normalize-label-pos(-10%, 4), (segment: 0, position: -40%))
#assert-position-almost-equal(normalize-label-pos(0%, 4), (segment: 0, position: 0%))
#assert-position-almost-equal(normalize-label-pos(10%, 4), (segment: 0, position: 40%))
#assert-position-almost-equal(normalize-label-pos(20%, 4), (segment: 0, position: 80%))
#assert-position-almost-equal(normalize-label-pos(30%, 4), (segment: 1, position: 20%))
#assert-position-almost-equal(normalize-label-pos(40%, 4), (segment: 1, position: 60%))
#assert-position-almost-equal(normalize-label-pos(50%, 4), (segment: 1, position: 100%))
#assert-position-almost-equal(normalize-label-pos(60%, 4), (segment: 2, position: 40%))
#assert-position-almost-equal(normalize-label-pos(70%, 4), (segment: 2, position: 80%))
#assert-position-almost-equal(normalize-label-pos(80%, 4), (segment: 3, position: 20%))
#assert-position-almost-equal(normalize-label-pos(90%, 4), (segment: 3, position: 60%))
#assert-position-almost-equal(normalize-label-pos(100%, 4), (segment: 3, position: 100%))
#assert-position-almost-equal(normalize-label-pos(110%, 4), (segment: 3, position: 140%))

== Different inputs

#assert-position-almost-equal(normalize-label-pos(100%, 5), (segment: 4, position: 100%))
#assert-position-almost-equal(normalize-label-pos(1, 5), (segment: 4, position: 100%))
#assert-position-almost-equal(normalize-label-pos(1.0, 5), (segment: 4, position: 100%))


== With length

#assert-position-almost-equal(normalize-label-pos(100% + 10pt, 5), (segment: 4, position: 100% + 10pt))
#assert-position-almost-equal(normalize-label-pos(-10pt, 5), (segment: 0, position: 0% - 10pt))

#assert-position-almost-equal(normalize-label-pos(1em, 5), (segment: 0, position: 0% + 1em))
#assert-position-almost-equal(normalize-label-pos(10pt - 1em, 5), (segment: 0, position: 0% + 10pt - 1em))
#assert-position-almost-equal(normalize-label-pos(10% + 10pt - 1em, 5), (segment: 0, position: 50% + 10pt - 1em))

== With segment

#assert-position-almost-equal(normalize-label-pos((3, 27%), 5), (segment: 3, position: 27%))
// Segment out of range
// #assert-position-almost-equal(normalize-label-pos((5, 27%), 3), (segment: 5, position: 27%))
