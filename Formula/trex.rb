cask "trex" do
  version "2.0.0"
  sha256 "4e8defc680daa6e09cb2daba576aa243683c775b93a9510ce5f12544d222de4d"

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
