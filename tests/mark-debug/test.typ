#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher

#fletcher.MARKS.pairs().map(((key, mark)) => [
	#raw(key)
	#set align(center)
	#fletcher.mark-debug(mark)
	#fletcher.mark-demo(mark)
]).join(pagebreak())
