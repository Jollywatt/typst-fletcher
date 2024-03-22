gallery_dir := "docs/gallery/"

example PATTERN="":
	for f in "{{gallery_dir}}"*{{PATTERN}}*.typ; do echo $f; typst c "$f" "${f/typ/svg}"; done

readme *ARGS:
	./build-readme.py {{ARGS}}