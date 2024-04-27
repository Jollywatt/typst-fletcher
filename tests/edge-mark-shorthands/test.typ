#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge


$
#for i in (
	"->",
	"<-",
	">-<",
	"<->",
	"<=>",
	"<==>",
	">==<",
	"|->",
	"|=>",
	">->",
	"<<->>",
	">>-<<",
	">>>-}>",
	"hook-hook",
	"hook'--hook'",
	"|=|",
	"||-||",
	"|||-|||",
	"/--\\",
	"\\=\\",
	"/=/",
	"x-X",
	">>-<<",
	"harpoon-harpoon",
	"harpoon'-<<",
	"<--hook'",
	"|..|",
	"hooks--hooks",
	"o-o",
	"O-o",
	"*-@",
	"o==O",
	"||->>",
	"<|-|>",
	"|>-<|",
	"-|-",
	"hook-/->",
	"<{-}>",
) {
	$ #block(inset: 2pt, fill: white.darken(5%), raw(repr(i)))
	&= #align(center, box(width: 15mm, diagram(edge((0,0), (1,0), marks: i), debug: 0))) \ $
}
$

