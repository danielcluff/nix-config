{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      nixpkgs.config.allowUnfree = true;
            environment.systemPackages = with pkgs; [ 
                rectangle
                raycast
                alacritty
                mkalias

                brave
                discord
                slack

          # programming
                claude-code
                vscode
                go
                python314
                uv

          # terminal
                aspell
                aspellDicts.en
                bash-completion
                zsh-powerlevel10k
                openssh
        ];

      homebrew = {
        enable = true;
        brews = [
          "mas"
        ];
        casks = [
          "hammerspoon"
          "zen"
          "iina"
          "the-unarchiver"
        ];
        masApps = {
          # "Slack" = 457622435;
        };
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
        user = "daniel";
      };

      fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.dejavu_fonts
        pkgs.ffmpeg
        pkgs.fd
        pkgs.hack-font
        pkgs.noto-fonts
        pkgs.noto-fonts-emoji
        pkgs.meslo-lgs-nf
        pkgs.fira-code
      ];

      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
      '';

      system.defaults = {
        # dock.autohide = true;
        # dock.persisent-apps = [];
        # NSGlobalDomain.AppleInterfaceStyle = "Dark";
        # NSGlobalDomain.KeyRepeat = 2;
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Daniels-MacBook-Air
    darwinConfigurations."Daniels-MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        configuration
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "daniel";
          };
        }
      ];
    };
  };
}
