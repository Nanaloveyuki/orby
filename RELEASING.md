# Releasing Orby

1. Ensure the MoonView dependency is a stable compatible release, not an alpha.
2. Update `moon.mod` and `CHANGELOG.md` for the release version.
3. Run native validation and both MoonView integration smokes from a clean checkout.
4. Merge the release gate PR and wait for GitHub Actions to pass.
5. Create a signed `v<version>` tag matching `moon.mod`.
6. Publish the Mooncakes package, create the GitHub release, and record package URLs.

The release workflow verifies only tag/version consistency and native checks. It
does not publish packages or create releases automatically.
