cask "trex" do
  version "1.9.1"
  sha256 "01937c514552f2a377de1c272b8cd5bda28e3f3ce752036e48200adaff457c65"

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
