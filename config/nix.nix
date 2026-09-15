{ ... }:
{
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    gc = {
      automatic = true;
      dates = "daily";
      persistent = true;
      options = "--delete-older-than 14d";
    };

    # hard-link identical files in the store, on a timer
    optimise.automatic = true;
  };
}
