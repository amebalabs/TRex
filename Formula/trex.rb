cask "trex" do
  version "1.9.0"
  sha256 "d8ff68dfee2f193ea253cd0bbaaefae958d9ddb64ebdc297002a4ac3e1373db7"

  url "https://github.com/amebalabs/TRex/releases/download/v#{version}/TRex-#{version}.zip"
  name "TRex"
  desc "Text Recognition for macOS"
  homepage "https://github.com/amebalabs/TRex"

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
