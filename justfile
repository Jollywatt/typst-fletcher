gallery_dir := "docs/gallery/"

default:
	just --list

readme ARG="build":
	./build-readme.py {{ARG}}

example PATTERN="":
	for f in "{{gallery_dir}}"*{{PATTERN}}*.typ; do echo $f; typst c "$f" "${f/typ/svg}"; done

test PATTERN="":
	typst-test run {{PATTERN}}

fix PATTERN:
	typst-test update {{PATTERN}} --exact