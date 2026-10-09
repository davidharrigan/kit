# macOS defaults (a home-manager module shared by every user via
# home-manager.sharedModules in system.nix). Override per user in that user's
# home-manager block.
{ config, lib, pkgs, ... }:
let
  home = config.home.homeDirectory;

  dockApps = [
    "/Applications/Ghostty.app"
    "/Applications/Firefox.app"
    "/Applications/Obsidian.app"
    "/Applications/Claude.app"
    "/Applications/ChatGPT.app"
    "/Applications/Antigravity.app"
    "/System/Applications/Mail.app"
    "/System/Applications/Music.app"
    "/System/Applications/Home.app"
    "/System/Applications/System Settings.app"
  ];

  # Content types Finder opens in VS Code.
  vscodeTypes = [
    "public.plain-text"
    "public.source-code"
    "public.script"
    "public.shell-script"
    "public.json"
    "public.yaml"
    "public.xml"
    "net.daringfireball.markdown"
  ];

  # Dock tiles in the format com.apple.dock stores them.
  appTile = path: {
    tile-data.file-data = {
      _CFURLString = path;
      _CFURLStringType = 0;
    };
  };
  # arrangement 1 = name, 2 = date added; showas 0 = automatic, 1 = fan; displayas 0 = stack.
  folderTile =
    {
      path,
      arrangement ? 1,
      showas ? 0,
    }:
    {
      tile-data = {
        file-data = {
          _CFURLString = "file://${path}";
          _CFURLStringType = 15;
        };
        inherit arrangement showas;
        displayas = 0;
      };
      tile-type = "directory-tile";
    };

  # HID usage codes for modifier remapping (Apple TN2450).
  key = {
    capsLock = 30064771129;
    leftAlt = 30064771298;
    leftCmd = 30064771299;
    rightCtrl = 30064771300;
    rightAlt = 30064771302;
    rightCmd = 30064771303;
  };
  remap = src: dst: {
    HIDKeyboardModifierMappingSrc = src;
    HIDKeyboardModifierMappingDst = dst;
  };

  # Per-keyboard modifier keys, as System Settings → Keyboard → Modifier Keys
  # stores them: keyed by <vendorID>-<productID>-0, with 0-0-0 for the built-in keyboard.
  modifierMappings = {
    "0-0-0" = [ (remap key.capsLock key.rightCtrl) ];
    # External keyboard with a PC layout: Caps Lock is Control, Cmd and Option swapped.
    "7185-45133-0" = [
      (remap key.capsLock key.rightCtrl)
      (remap key.rightCmd key.rightAlt)
      (remap key.leftCmd key.leftAlt)
      (remap key.rightAlt key.rightCmd)
      (remap key.leftAlt key.leftCmd)
    ];
  };

  # Tap to click off.
  trackpad.Clicking = false;
in
{
  # macOS defaults captured from chainsaw (baseline/capture.sh).
  targets.darwin.defaults = {
    # Dark mode, fast key repeat, no autocorrect or smart punctuation, silent alert sound.
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 25;
      ApplePressAndHoldEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      "com.apple.sound.beep.volume" = 0.0;
      # Natural scrolling off (mouse and trackpad share this setting).
      "com.apple.swipescrolldirection" = false;
    };

    # Auto-hiding dock on the left, scale minimize effect, no recent apps.
    "com.apple.dock" = {
      autohide = true;
      orientation = "left";
      mineffect = "scale";
      tilesize = 50;
      show-recents = false;
      persistent-apps = map appTile dockApps;
      persistent-others = [
        (folderTile { path = "/Applications"; })
        (folderTile {
          path = "${home}/Downloads";
          arrangement = 2;
          showas = 1;
        })
      ];
    };

    # Finder opens in list view.
    "com.apple.finder".FXPreferredViewStyle = "Nlsv";

    # Screenshots go to Downloads.
    "com.apple.screencapture".location = "~/Downloads";

    # Menu bar clock: 0 = show date when space allows; AM/PM shown.
    "com.apple.menuextra.clock" = {
      ShowDate = 0;
      ShowAMPM = true;
    };

    # Built-in and Bluetooth trackpads read separate domains.
    "com.apple.AppleMultitouchTrackpad" = trackpad;
    "com.apple.driver.AppleBluetoothMultitouch.trackpad" = trackpad;

    # Stage Manager off.
    "com.apple.WindowManager".GloballyEnabled = false;

    # Apple personalized ads off.
    "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
  };

  # macOS applies these at login or when the keyboard connects.
  targets.darwin.currentHostDefaults.NSGlobalDomain = lib.mapAttrs' (
    device: mappings: lib.nameValuePair "com.apple.keyboard.modifiermapping.${device}" mappings
  ) modifierMappings;

  home.activation.macosApps = lib.hm.dag.entryAfter [ "setDarwinDefaults" ] ''
    # Pick up the Dock settings above (no-op when the user isn't logged in).
    run /usr/bin/killall -qu "$USER" Dock || true

    # VS Code is the default editor for text and code files.
    if [ -e "/Applications/Visual Studio Code.app" ]; then
      for type in ${lib.escapeShellArgs vscodeTypes}; do
        run ${pkgs.duti}/bin/duti -s com.microsoft.VSCode "$type" all
      done
    fi

    # Firefox is the default browser. macOS asks to confirm the change, so
    # only set it when it isn't already the default.
    if [ -e /Applications/Firefox.app ] && [ "$(/usr/bin/osascript -l JavaScript -e \
      'ObjC.import("AppKit"); $.NSWorkspace.sharedWorkspace.URLForApplicationToOpenURL($.NSURL.URLWithString("https://example.com")).path.js')" != /Applications/Firefox.app ]; then
      run ${pkgs.duti}/bin/duti -s org.mozilla.firefox http
      run ${pkgs.duti}/bin/duti -s org.mozilla.firefox https
    fi
  '';
}
