# typed: strict
# frozen_string_literal: true

# Builds Dopamine Code from source.
#
# A formula rather than a cask, deliberately. A cask installs a pre-built binary, and an
# unnotarised one arrives with the quarantine attribute Homebrew sets on downloads — so
# Gatekeeper blocks it and the user has to work around that. Building here sidesteps the
# problem entirely: a locally compiled app never gets quarantined, so there is no warning
# and no notarisation needed.
#
# The build needs nothing but the Swift compiler from the Xcode command line tools, which
# Homebrew already requires for any source build. No Xcode project, no package manager, no
# network access during the build.
class DopamineCode < Formula
  desc "Menu bar app that keeps your Mac awake with the lid closed"
  homepage "https://github.com/peter46jan/dopamine-code"
  url "https://github.com/peter46jan/dopamine-code/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "6de8619c5c63c505e49ebfb5915cd6a964abebee709261c96dca554175e36eb2"
  license "MIT"
  head "https://github.com/peter46jan/dopamine-code.git", branch: "main"

  # SleepDisabled, SMAppService and the SwiftUI the app is built on. The bundle declares
  # LSMinimumSystemVersion 14.0 for the same reason.
  depends_on macos: :sonoma

  def install
    # build.sh takes its version from `git describe`, and a release tarball has no .git.
    # Without this the app would call itself 0.0.0 and its update check would report that
    # it does not know its own version.
    ENV["DOPAMINE_VERSION"] = version.to_s

    system "./build.sh"

    prefix.install "build/Dopamine Code.app"

    # The command line talks to the running app over a unix socket; it switches nothing
    # itself. Linking it means `dopamine on --until-exit $$` works in a script without
    # spelling out the path inside the bundle.
    bin.install_symlink prefix/"Dopamine Code.app/Contents/MacOS/dopamine"
  end

  def caveats
    <<~EOS
      The app is installed in the Cellar rather than /Applications, because a formula must
      not write outside its own prefix. Link it across once:

        ln -sfn "#{opt_prefix}/Dopamine Code.app" /Applications/

      If you built the app by hand before and followed its suggestion to symlink the command
      line onto your PATH, remove that first — Homebrew will not link over it:

        rm -f "$(brew --prefix)/bin/dopamine" && brew link dopamine-code

      Then open it from /Applications. On first use it asks once for your admin password,
      for a sudoers rule that makes exactly two pmset commands passwordless:

        <your-username> ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, \\
                                             /usr/bin/pmset -a disablesleep 0

      Those arguments are the point — without them the same rule would hand over all of
      power management as root. Why root is needed at all, and what it deliberately does
      not get, is the first section of the README.

      Note that this app switches off macOS's automatic sleep on a nearly empty battery and
      on overheating; it replaces both with its own limits. Read the README before using it
      somewhere that matters.
    EOS
  end

  test do
    app = prefix/"Dopamine Code.app"
    assert_path_exists app

    # The version actually stamped into the bundle, not the one the formula thinks it is.
    # These drift apart the moment DOPAMINE_VERSION stops being picked up.
    plist = app/"Contents/Info.plist"
    stamped = shell_output("/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' '#{plist}'").strip
    assert_equal version.to_s, stamped

    # All four languages have to be in the bundle; a missing .lproj shows raw keys in the UI.
    %w[nl en de fr].each do |lang|
      assert_path_exists app/"Contents/Resources/#{lang}.lproj/Localizable.strings"
    end

    # `--help` and not `status`: status returns 0 when the app is running and 4 when it is
    # not, so a test asserting either one passes or fails depending on whether the machine
    # running it happens to have the app open. That is a test measuring the wrong thing.
    assert_match "dopamine", shell_output("#{bin}/dopamine --help")
  end
end
