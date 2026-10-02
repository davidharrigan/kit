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
    };

    # Auto-hiding dock on the left, scale minimize effect.
    dock = {
      autohide = true;
      orientation = "left";
      mineffect = "scale";
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
}
