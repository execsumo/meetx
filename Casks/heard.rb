cask "heard" do
  version "0.1.0"
  # Run scripts/dmg.sh to build the release DMG, then fill in the SHA256 it prints.
  sha256 "01a87b8e2878171744741e8891ce4b1c8a6df368f14515f67889c4a5f56059ff"

  url "https://github.com/execsumo/heard/releases/download/v#{version}/Heard-#{version}.dmg"
  name "Heard"
  desc "Menu bar app that auto-records and transcribes Microsoft Teams meetings on-device"
  homepage "https://github.com/execsumo/heard"

  # macOS 15 Sequoia or later required (uses CATapDescription process tap)
  depends_on macos: ">= :sequoia"

  app "Heard.app"

  zap trash: [
    "~/Library/Application Support/Heard",
    "~/Library/Preferences/com.execsumo.heard.plist",
  ]
end
