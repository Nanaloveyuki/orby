# Releasing Orby

1. Ensure the declared MoonView version is tagged, compatible, and resolvable
   from Mooncakes; do not release against an unpublished local checkout.
2. Update `moon.mod` and `CHANGELOG.md` for the release version and dependency
   version, then run native validation from a clean checkout to resolve the
   declared dependencies.
3. Run native validation and both MoonView integration smokes from a clean
   checkout. Each smoke must destroy its WebView before its Orby window.
4. Merge the release gate PR and wait for GitHub Actions to pass.
5. Create a signed `v<version>` tag matching `moon.mod`.
6. Publish the Mooncakes package, create the GitHub release, and record package URLs.

The release workflow verifies only tag/version consistency and native checks. It
does not publish packages or create releases automatically.
