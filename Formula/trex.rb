cask "trex" do
  version "2.0.0"
  sha256 "c4b5a0ff9895cb1317fe70d469cc3b37b7dc9e276f4f6b399ba46c5961ba5303"

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
