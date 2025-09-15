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
                vscode
                code-cursor
                go
                python314
                uv

                # media
                davinci-resolve

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
                    "voiceink"
                    "sublime-text"
                    "hammerspoon"
                    "zen"
                    "iina"
                    "the-unarchiver"
                ];
                masApps = {
                    # "Slack" = 457622435;
                };
                onActivation = {
                    cleanup = "zap";
                    autoUpdate = true;
                    upgrade = true;
                };
            };

            fonts.packages = with pkgs; [
                nerd-fonts.jetbrains-mono
                dejavu_fonts
                ffmpeg
                fd
                hack-font
                noto-fonts
                noto-fonts-emoji
                meslo-lgs-nf
                fira-code
            ];

            users.users.daniel = {
                home = "/Users/daniel";
                packages = with pkgs; [
                    nodePackages.npm
                    nodejs_24
                ];
            };

            # leaving this out for now, hopefully it isn't needed
            # Configure npm global directory
            #environment.variables = {
            #    NPM_CONFIG_PREFIX = "/Users/daniel/.npm-global";
            #    NODE_PATH = "/Users/daniel/.npm-global/lib/node_modules";
            #};

            # Add npm global bin to PATH
            #environment.systemPath = [ "/Users/daniel/.npm-global/bin" ];

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

            # Enable Touch ID for sudo
            security.pam.services.sudo_local.touchIdAuth = true;

            system = {
                primaryUser = "daniel";
                defaults = {
                    # dock.autohide = false;
                    # dock.persisent-apps = [];
                    NSGlobalDomain.AppleInterfaceStyle = "Dark";
                    NSGlobalDomain.KeyRepeat = 2;
                };

                ## default settings ##
                stateVersion = 6;
                configurationRevision = self.rev or self.dirtyRev or null;
            };
            nix.settings.experimental-features = "nix-command flakes";
            nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
        # Build darwin flake using:
        # $ darwin-rebuild build --flake .#Floaty
        darwinConfigurations."Floaty" = nix-darwin.lib.darwinSystem {
            modules = [
                nix-homebrew.darwinModules.nix-homebrew
                configuration
                {
                    nix-homebrew = {
                        enable = true;
                        enableRosetta = true;
                        user = "daniel";
                    };
                }
            ];
        };
    };
}
