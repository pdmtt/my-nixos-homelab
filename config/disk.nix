{ lib, ... }:
{
  disko.devices = {
    disk.disk1 = {
      device = lib.mkDefault "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          bios = {
            # this partition allows BIOS systems to function on GPT disks
            size = "1M";
            type = "EF02";
            priority = 1; # first on disk, as required by MBR bootloaders
          };

          esp = {
            name = "ESP";
            size = "500M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          luks = {
            size = "100%";
            # GPT partition label — lets configuration.nix find the device
            # without hardcoding a UUID
            label = "luks-main";
            content = {
              type = "luks";
              name = "cryptroot";
              passwordFile = "/tmp/secret.key"; # must match the remote path in --disk-encryption-keys
              settings.allowDiscards = true;
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };
    };

    lvm_vg.pool = {
      type = "lvm_vg";
      lvs = {
        root = {
          size = "100%FREE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = [
              "defaults"
              # systemd stage 1 gives up waiting for the root device after 90s, which
              # is too short when the LUKS passphrase is typed in remotely
              "x-systemd.device-timeout=infinity"
            ];
          };
        };
      };
    };
  };
}
