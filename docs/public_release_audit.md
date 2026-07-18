# Public Release Audit

## Summary

Release candidate: `v1.0.0-buildweek`

Status: recommended for release after CI and GitHub Pages settings are verified on GitHub.

## Blocking Items

- Demo media must be regenerated only after the workstation readiness signal confirms Shiny connection, active route rendering, loaded app CSS, populated CSS variables, stable layout, visible logo, and no failed required assets.
- Public README media must be present under `docs/media/`.
- Release artifacts must include source package, Windows distribution zip, release notes, and SHA256 manifest.
- Public markdown must not contain founder-machine paths or temporary screenshot paths.

## Blocking Fixes Applied

- Added deterministic DOM readiness signal for browser recording.
- Added Build Week public recorder with computed-style and required-asset assertions.
- Regenerated `docs/media/demo.webm`, `docs/media/demo_first_frame.png`, and `docs/media/demo_final_frame.png`.
- Added pkgdown configuration and article skeletons.
- Added CI, pkgdown, and tag-gated release workflows.
- Added local release preflight script.

## Recommended Follow-Ups

- Enable GitHub Pages using the `pkgdown site` workflow output.
- Confirm sibling first-party packages are public or documented for judges before the first public tag.
- Run the release workflow from tag `v1.0.0-buildweek` after local preflight passes.
- Review generated pkgdown reference index for any internal helper that should remain unexported in a future cleanup.

## Optional Follow-Ups

- Convert WebM videos to MP4 when a release encoder is available.
- Add shorter social clips after the judged Build Week submission is stable.
- Add screenshots from a fresh installed-package run in addition to source-tree captures.

## Manual Public Settings

- GitHub repository visibility: public.
- GitHub Pages source: GitHub Actions.
- Default branch protection: require `R package validation` and `pkgdown site` before release branches merge.
- Release tag convention: `vMAJOR.MINOR.PATCH-label`, beginning with `v1.0.0-buildweek`.
