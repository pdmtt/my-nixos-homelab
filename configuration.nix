{ modulesPath, lib, pkgs, myPublicKey, ...  } @ args:
let 
  adminUser = "admin";
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  boot = {
      loader = {
        efi.canTouchEfiVariables = false;
        grub = {
          enable = true;
          efiSupport = true;
          efiInstallAsRemovable = true;
          # no need to set devices, disko will add all devices that have a EF02 partition to the list already
          device = "nodev";
        };
      };

      # we need DHCP in initrd to SSH into the machine to unlock the LUKS partition
      # DHCP in initrd requires the ip= kernel parameter
      kernelParams = [ "ip=dhcp" ];

      initrd = {
        luks.devices.cryptroot = {
          # uses the GPT partition label set in disk-config.nix to find the device
          device = "/dev/disk/by-partlabel/luks-main";
          allowDiscards = true;
        };

      # bring up networking in initrd so SSH is reachable before LUKS is unlocked
      # needed for remote LUKS unlocking
      network = {
        enable = true;

        ssh = {
          enable = true;
          port = 2222;  # different from the default port 22 to avoid known_hosts issues

          # this key MUST be stored outside the encrypted partition so it is
          # available before LUKS is unlocked. Deploy it with nixos-anywhere's
          # --extra-files flag (see README).
          hostKeys = [ /etc/secrets/initrd/initrd_host_key ];

          # Your own public key — paste the contents of ~/.ssh/id_ed25519.pub
          authorizedKeys = [ myPublicKey ];
        };

        # after SSH login, automatically prompt for the LUKS passphrase
        postCommands = ''
          cat <<'EOF' >> /root/.profile
          if pgrep -x "cryptsetup" > /dev/null; then
            cryptsetup-askpass
          fi
          EOF
        '';
      };
    };
  };

  system.stateVersion = "25.11";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # ssh
      3000  # adguard home web UI
      53    # dns
    ];
    allowedUDPPorts = [
      53    # dns
    ];
  };

  services = {
    adguardhome = {
      enable = true;
      mutableSettings = true;
      host = "0.0.0.0";
      port = 3000;
      settings = {
        dns = {
          bind_hosts = [ "0.0.0.0" ];
          port = 53;
        };
      };
    };

    logind.settings.Login = {
      # my homelab is an old laptop that I like keeping closed :)
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };

    openssh = {
      enable = true;
      settings = { 
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        X11Forwarding = false;
        MaxAuthTries = 3;
        LoginGraceTime = 20;
        AllowUsers = [ adminUser ];
      };
    };
  };

  security.sudo.wheelNeedsPassword = true;

  users.users.${adminUser} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ myPublicKey ];
    initialPassword = "admin";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
