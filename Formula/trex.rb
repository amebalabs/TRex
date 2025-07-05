cask "trex" do
  version "1.9.0-BETA-2"
  sha256 "7f5268143662ef5e791645f4f276e8de9a1342408f22fa1f8e5c92cabdd8061c"

  url "https://github.com/ameba/TRex/releases/download/v#{version}/TRex-#{version}.zip"
  name "TRex"
  desc "Text Recognition for macOS"
  homepage "https://github.com/ameba/TRex"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true

  app "TRex.app"
  binary "#{appdir}/TRex.app/Contents/MacOS/TRex CMD", target: "trex"

  zap trash: [
    "~/Library/Application Support/com.ameba.TRex",
    "~/Library/Caches/com.ameba.TRex",
    "~/Library/Preferences/com.ameba.TRex.plist",
  ]
end
