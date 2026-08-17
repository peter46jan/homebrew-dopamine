# Homebrew tap for Dopamine Code

One formula, for [Dopamine Code](https://github.com/peter46jan/dopamine-code) — a macOS menu
bar app that keeps your Mac awake with the lid closed.

```bash
brew tap peter46jan/dopamine
brew install dopamine-code
```

Then link the app across once, because a formula may not write outside its own prefix:

```bash
ln -sfn "$(brew --prefix)/opt/dopamine-code/Dopamine Code.app" /Applications/
```

## Why a formula and not a cask

A cask installs a pre-built binary. Homebrew puts the quarantine attribute on anything it
downloads, so an app that is not notarised by Apple gets blocked by Gatekeeper and the user
has to work around it.

This builds from source instead, and **a locally compiled app is never quarantined** — so
there is no warning and no Apple Developer account in the chain. The build needs only the
Swift compiler from the Xcode command line tools, which Homebrew requires anyway. No
dependencies, no network access during the build, about 45 seconds.

## Before you install

This app switches off macOS's automatic sleep on a nearly empty battery and on overheating,
and replaces both with limits of its own. It needs one sudoers rule that makes exactly two
`pmset` commands passwordless. Both of those are explained in the first section of the
[README](https://github.com/peter46jan/dopamine-code#why-this-needs-root-and-what-it-does-not-get),
and there is a
[security audit](https://github.com/peter46jan/dopamine-code/blob/main/SECURITY-AUDIT.md)
covering the privilege-escalation surface.

## Updating the formula

After a new release in the main repository:

```bash
brew bump-formula-pr --url=https://github.com/peter46jan/dopamine-code/archive/refs/tags/vX.Y.Z.tar.gz peter46jan/dopamine/dopamine-code
```

Or edit `url` and `sha256` in `Formula/dopamine-code.rb` by hand — `shasum -a 256` on the
downloaded tarball gives the checksum.
