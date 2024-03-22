gallery_dir := "docs/gallery/"

examples:
	for f in "{{gallery_dir}}"/*.typ; do typst c "$f" "${f/typ/svg}"; done

readme *ARGS:
	./build-readme.py {{ARGS}}