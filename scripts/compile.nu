#!/usr/bin/env nu

def main [
	--gallery
] {
	if $gallery { gallery }
}


# Compile gallery examples to SVGs
def gallery [
	pattern : string = "" # Filter to filenames matching regex
] {
	ls docs/gallery/*.typ |
		insert basename { $in.name | path basename } |
		where basename =~ $pattern |
		each { |it|
			print $"Compiling ($it.name)"
			typst compile --root . ($it.name) --format svg
		}
	null
}

