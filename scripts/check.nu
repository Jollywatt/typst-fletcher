#!/usr/bin/env nu

# Check for possible typos or incorrect version numbers in files
def main [
	--typos (-t) # Run a typo check on all files
	--versions (-v) # Search files for version numbers of the form `x.y.z`
] {
	let all = not ($typos or $versions)

	if $typos or $all {
		print (typos)
	}
	if $versions or $all {
		print (versions)
	}
}

def typos [] {
	print "Possible typos:"
	^typos --config scripts/typos.toml --format brief | lines
}

def versions [] {
	print "Version numbers in files to check:"
	ls **/*.typ **/*.toml | get name | each { |file|
		let matches = open $file --raw | lines | find -r '\d\.\d\.\d'
		$matches | wrap match | insert file $file
	} | flatten | select file match
}
