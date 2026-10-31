# ci/

Two workflows, both in `.github/workflows/`:

- `contribs.yml` (run by hand, once per pinned VLC commit): `ci/contribs.sh <platform>` per target,
  assets on release `contribs-<TESTEDHASH>`.
- `build.yml` (every push to `shelf` that touches something other than `Package.swift`, `README.md`
  or `docs/`): three platform jobs with the prebuilt contribs, then one package job that runs
  VideoLAN's `Packaging/create-distributable-package.sh -a -x -m -t -s`, publishes the zip as a
  release and commits `Package.swift`.

Both put Homebrew's make 4 ahead of Apple's 3.81 through `VLC_PATH`; see the comments in the files.
