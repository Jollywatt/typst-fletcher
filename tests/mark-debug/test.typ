#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher


#context fletcher.MARKS.get().pairs().map(((key, mark)) => [
	#raw(key)
	#set align(center)
	#fletcher.mark-debug(mark, show-offsets: true)
	#fletcher.mark-demo(mark)
]).join(pagebreak())
