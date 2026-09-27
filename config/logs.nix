{ ... }:
let
  victorialogsPort = 9428;
in
{
  services.victorialogs = {
    enable = true;

    # reachable over the tailnet only: tailscale0 is a trusted interface (see tailscale.nix),
    # so other hosts can ship their journals here without opening the port on the LAN
    listenAddress = "0.0.0.0:${toString victorialogsPort}";

    extraOptions = [ "-retentionPeriod=90d" ];
  };

  # ships this machine's own journal; VictoriaLogs ingests journal-upload's protocol natively
  services.journald.upload = {
    enable = true;
    settings.Upload.URL = "http://127.0.0.1:${toString victorialogsPort}/insert/journald";
  };

  # victorialogs only counts as started once it answers /ping, so this avoids
  # restart loops on boot while the upload target is still coming up
  systemd.services.systemd-journal-upload = {
    wants = [ "victorialogs.service" ];
    after = [ "victorialogs.service" ];
  };
}
