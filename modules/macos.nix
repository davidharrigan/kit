{ config, lib, pkgs, ... }:
let
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
in
{
  # macOS defaults captured from chainsaw (baseline/capture.sh).
  system.defaults = {
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
    dock = {
      autohide = true;
      orientation = "left";
      mineffect = "scale";
      tilesize = 50;
      show-recents = false;
      persistent-apps = dockApps;
      persistent-others = [
        "/Applications"
        {
          folder = {
            path = "/Users/david/Downloads";
            arrangement = "date-added";
            showas = "fan";
          };
        }
      ];
    };

    # Finder opens in list view.
    finder.FXPreferredViewStyle = "Nlsv";

    # Screenshots go to Downloads.
    screencapture.location = "~/Downloads";

    # Menu bar clock: 0 = show date when space allows; AM/PM shown.
    menuExtraClock = {
      ShowDate = 0;
      ShowAMPM = true;
    };

    # Tap to click off.
    trackpad.Clicking = false;

    # Stage Manager off.
    WindowManager.GloballyEnabled = false;

    # Apple personalized ads off.
    CustomUserPreferences."com.apple.AdLib".allowApplePersonalizedAdvertising = false;
  };

  # Dock apps installed by Homebrew don't exist yet when the Dock is set up,
  # so they show as "?". Note any missing ones before Homebrew runs.
  system.activationScripts.preActivation.text = ''
    dockAppsMissing=
    for app in ${lib.escapeShellArgs dockApps}; do
      [ -e "$app" ] || dockAppsMissing=1
    done
  '';

  system.activationScripts.postActivation.text =
    let
      user = config.system.primaryUser;
      asUser = ''launchctl asuser "$(id -u -- ${user})" sudo --user=${user} --'';
    in
    # nix-darwin's system.defaults can't write ByHost (-currentHost) prefs.
    # macOS applies them at login or when the keyboard connects.
    lib.concatStrings (
      lib.mapAttrsToList (device: mappings: ''
        ${asUser} defaults -currentHost write -g \
          ${lib.escapeShellArg "com.apple.keyboard.modifiermapping.${device}"} \
          ${lib.escapeShellArg (lib.generators.toPlist { escape = true; } mappings)}
      '') modifierMappings
    )
    + ''
      # Rewrite the user defaults (Dock included) now that Homebrew apps exist.
      if [ -n "$dockAppsMissing" ]; then
        ${config.system.activationScripts.userDefaults.text}
      fi

      # VS Code is the default editor for text and code files.
      if [ -e "/Applications/Visual Studio Code.app" ]; then
        for type in ${lib.escapeShellArgs vscodeTypes}; do
          ${asUser} ${pkgs.duti}/bin/duti -s com.microsoft.VSCode "$type" all
        done
      fi

      # Firefox is the default browser. macOS asks to confirm the change, so
      # only set it when it isn't already the default.
      if [ -e /Applications/Firefox.app ] && [ "$(${asUser} osascript -l JavaScript -e \
        'ObjC.import("AppKit"); $.NSWorkspace.sharedWorkspace.URLForApplicationToOpenURL($.NSURL.URLWithString("https://example.com")).path.js')" != /Applications/Firefox.app ]; then
        ${asUser} ${pkgs.duti}/bin/duti -s org.mozilla.firefox http
        ${asUser} ${pkgs.duti}/bin/duti -s org.mozilla.firefox https
      fi
    '';
}
