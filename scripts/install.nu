#!/usr/bin/env nu

# Locally install a typst package under the given namespace
# so it is installable with `import "@namespace/package:version"`.
def main [
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
		if ($info.version | path exists) {
			rm $info.version
		}
	} else {
		if $symlink {
			print $"Linking (pwd)"
			ln -s ($path) ($info.version)
		} else {
			error make { msg: "copying not implemented", help: "pass --symlink to symlink instead of copy" }
		}
		print $'Installed package locally as "@($namespace)/($info.name):($info.version)".'
	}
}


# Get the OS-specific data directory
def DATA_DIR [] {
	match $nu.os-info.name {
		"macos" => { $"~/Library/Application Support" },
		"linux" => { $env.XDG_DATA_HOME? | default $"~/.local/share" },
		"windows" => { $env.APPDATA },
	}
}

