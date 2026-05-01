(function () {
    /**
     * Generates a URL-friendly ID from heading text
     * @param {string} text - The heading text
     * @param {Set} existingIds - Set of existing IDs to avoid duplicates
     * @returns {string} - A URL-friendly ID
     */
    function generateId(text, existingIds = new Set()) {
        let id = text
            .toLowerCase()
            .trim()
            .replace(/\s+/g, "-") // Replace spaces with hyphens
            .replace(/[^\w\-]/g, "") // Remove non-alphanumeric characters except hyphens
            .replace(/\-+/g, "-") // Replace multiple hyphens with single hyphen
            .replace(/^\-+|\-+$/g, ""); // Remove leading/trailing hyphens

        // Handle duplicates by appending a number
        if (existingIds.has(id)) {
            let counter = 1;
            while (existingIds.has(`${id}-${counter}`)) {
                counter++;
            }
            id = `${id}-${counter}`;
        }

        existingIds.add(id);
        return id;
    }

    /**
     * Escapes HTML special characters to prevent XSS
     * @param {string} text - Text to escape
     * @returns {string} - Escaped text
     */
    function escapeHtml(text) {
        const map = {
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            '"': "&quot;",
            "'": "&#039;",
        };
        return text.replace(/[&<>"']/g, (m) => map[m]);
    }

    /**
     * Builds a nested HTML list structure for the TOC
     * @param {Array} headings - Array of heading objects with level, id, and text
     * @returns {string} - HTML string for the nested TOC
     */
    function buildNestedToc(headings) {
        if (headings.length === 0) {
            return "";
        }

        let html = '<nav id="TableOfContents">\n<ul>\n';
        const stack = []; // Stack of heading levels currently open

        headings.forEach((heading) => {
            const { level, id, text } = heading;

            // Close any deeper levels
            while (stack.length > 0 && stack[stack.length - 1] >= level) {
                stack.pop();
                html += "</li>\n";
                if (stack.length > 0) {
                    html += "</ul>\n";
                }
            }

            // If we're going deeper than the current level, open a new nested ul
            if (stack.length > 0 && stack[stack.length - 1] < level) {
                html += "<ul>\n";
            }

            // Add the current heading item
            html += `<li><a href="#${id}">${escapeHtml(text)}</a>`;
            stack.push(level);
        });

        // Close all remaining open items
        while (stack.length > 0) {
            stack.pop();
            html += "</li>\n";
            if (stack.length > 0) {
                html += "</ul>\n";
            }
        }

        html += "</ul>\n</nav>";
        return html;
    }

    /**
     * Extracts headings from the article content and builds a nested TOC structure
     * @returns {string} - HTML string for the TOC or null if no headings found
     */
    function generateTableOfContents() {
        const articleElement = document.querySelector(".book-article");
        if (!articleElement) {
            return null;
        }

        const headings = [];
        const usedIds = new Set();

        // Extract all headings (h1-h6) from the article
        articleElement
            .querySelectorAll("h1, h2, h3, h4, h5, h6")
            .forEach((heading) => {
                // Skip if heading is empty
                if (!heading.textContent.trim()) {
                    return;
                }

                // Determine heading level
                const level = parseInt(heading.tagName[1], 10);

                // Get or generate ID
                let id = heading.id;
                if (!id) {
                    id = generateId(heading.textContent, usedIds);
                    heading.id = id; // Assign the generated ID back to the heading
                } else {
                    usedIds.add(id);
                }

                headings.push({
                    level,
                    id,
                    text: heading.textContent,
                });
            });

        // If no headings found, return null
        if (headings.length === 0) {
            return null;
        }

        // Build nested TOC structure
        return buildNestedToc(headings);
    }

    /**
     * Injects the generated TOC into the page
     */
    function injectTableOfContents() {
        const tocContainer = document.querySelector(".book-toc-content");

        if (!tocContainer) {
            return; // No container to inject into
        }

        // Only inject if the TOC container is empty (preserves Hugo-generated TOCs)
        if (
            tocContainer.childNodes.length > 0 &&
            tocContainer.innerHTML.trim().length > 0
        ) {
            return;
        }

        // Generate the TOC
        const tocHtml = generateTableOfContents();
        if (tocHtml) {
            tocContainer.innerHTML = tocHtml;
        }
    }

    // Run when DOM is ready
    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", injectTableOfContents);
    } else {
        // DOM is already loaded
        injectTableOfContents();
    }
})();
