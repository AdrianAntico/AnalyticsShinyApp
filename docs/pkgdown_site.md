# pkgdown Site

The public package site is configured through `_pkgdown.yml`.

Expected GitHub Pages URL:

<https://adrianantico.github.io/AnalyticsShinyApp/>

## Sections

- Product overview
- Installation
- Build Week demo
- Evidence and integrity review
- Architecture
- Package reference
- Development story
- Release notes
- Troubleshooting

## Local Build

From the repository root:

```sh
Rscript scripts/build_pkgdown_site.R
```

The generated site is written to `pkgdown-site/` so the repository's source `docs/` folder remains the architecture-document source of truth.

The build wrapper copies public media from `docs/media/` into `pkgdown-site/docs/media/` after pkgdown renders the site so GitHub README paths and pkgdown paths stay aligned.

The site is documentation-only. It must not require provider secrets or execute paid model calls.
