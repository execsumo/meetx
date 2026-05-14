cask "heard" do
  version "0.2.0"
  # Run scripts/dmg.sh to build the release DMG, then fill in the SHA256 it prints.
  sha256 "6feb5d2d1366c760acc420712b36f4e873ff31412d66c390c66d5f95cc938c9f"

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
