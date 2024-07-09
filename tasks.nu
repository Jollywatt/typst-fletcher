#!/usr/bin/env nu
# This file contains commands to perform chores useful while developing typst packages

def main [] {

}


# Get the OS-specific data directory
def DATA_DIR [] {
	match $nu.os-info.name {
		"macos" => { $"($nu.home-path)/Library/Application Support" },
		"linux" => { $env.XDG_DATA_HOME? | default $"($nu.home-path)/.local/share" },
		"windows" => { $env.APPDATA },
	}
}


# Locally install a typst package under the given namespace
def 'main install' [
	path : path = . # Location of typst package
	--namespace (-n) : string = "local" # namespace to install to, e.g., 'preview'
	--symlink (-s) # Install by symlinking instead of copying
	--delete (-d) # Uninstall by deleting installed directory
] {
	let path = realpath $path
	let info = open typst.toml | get package
	let packages_dir = [(DATA_DIR) "typst" "packages"] | path join

	cd $packages_dir
	mkdir $namespace
	cd $namespace
	mkdir $info.name
	cd $info.name
	if ($info.version | path exists) { rm $info.version }

	if $delete {
		rm $info.version
	} else {
		if $symlink {
			ln -s ($path) ($info.version)
		} else {
			error make { msg: "copying not implemented", help: "pass --symlink to symlink instead of copy" }
		}
		print $'Installed package locally as "@($namespace)/($info.name):($info.version)".'
	}
}


# Compile gallery examples to SVGs
def 'main gallery' [
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


# Check for typos and version numbers in files
def 'main check' [
	--typos (-t) # Run a typo check on all files
	--versions (-v) # Search files for version numbers of the form `x.y.z`
] {
	let $both = not $typos and not $versions

	if $typos or $both {
		print (check typos)
	}
	if $versions or $both {
		print (check versions)
	}
}

def 'check typos' [] {
	print "Possible typos:"
	typos --config scripts/typos.toml --format brief | lines
}

def 'check versions' [] {
	print "Version numbers in files to check:"
	ls **/*.typ | get name | each { |file|
		open $file | lines | find -r '\d\.\d\.\d' |
			wrap match | insert file $file
	} | flatten | select file match
}
