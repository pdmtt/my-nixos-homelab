{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  outputs = { nixpkgs, disko, nixos-facter-modules, ... }:
    let
      myPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCnMhmge4PMIl+fF//k2vLPihftQGpsk3qm/y7MSX1ji0WlAY8WsvL5xTsHnFOXdaCg2ny67xhA9Q31P51LQoif78lRNenPR6JvYfBHEkZJC20YDDStm2pHyCzw1tnTQaffLZRsp79YK0MKwiB7ggYJNNw2go8E0YOQnU/vHqebXNOfXBfYGjPkFh2oeQ7DQi+VLDr6+OMi2VsUuqXjXOM03AoL5so2Ohzv0vBC49qFiRsvUxhag5qMcejF7H6SRDE5YD+PMpCqFQc9THYdenUmppAm4kg6gTrpJ0dYdzEJpOQwlpiIzqYzCrJ9ugu15xHk9q85Rpyd5mUm/MamXiBSy9Jx4GMMitM1YQVzK2O598jAyXjUU+nZyoBo4uNu+HrVezPOIpFvO+lsXAYTYn7K8CyFOPI+d5bGozfVPyqwCV2JFtt+Wexkd8nKClB61X9wRM65K/tZY4Xkwg/nbA3cDU6GVbE/GZWhjMVXelFFj7XZwtCIfulMvOJqBds/Nns=";
    in {
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit myPublicKey; };
        modules = [
          disko.nixosModules.disko
          ./config/configuration.nix
          nixos-facter-modules.nixosModules.facter
          {
            config.facter.reportPath =
              if builtins.pathExists ./facter.json then
                ./facter.json
              else
                throw "Have you forgotten to run nixos-anywhere with `--generate-hardware-config nixos-facter ./facter.json`?";
          }
        ];
      };
    };
}
