#import "/src/exports.typ" as fletcher: *
#set page(height: 10cm)



#fletcher.diagram(
	spacing: 1cm,
	axes: (ltr, ttb),
$
	G edge(#auto, #auto, f, "->") edge(#auto, #(0,1), pi, "->>") & im(f) \
	G slash ker(f) edge(#auto, #(1,0), "hook'-->")
$)