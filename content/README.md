# Site copy

Since 9 November 2026 the home page copy is edited in the admin (`/admin`,
Home page) and goes live when David presses Publish. It is held in the
database (`site_content`, key `home`), and the build uses the copy carried by
the newest release. `home.json` is the original source and the fallback the
build reads only when a release does not carry the copy; editing it no longer
changes the site.

`vistula.json` is the course of the river, drawn on every map. It is still
read from this folder.
