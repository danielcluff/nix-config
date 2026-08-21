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
                go
                python314
                uv
                zig
                pnpm

                # containers
                colima
                docker
                docker-compose
                docker-buildx
                docker-credential-helpers

                #devops
                kubectl
                kubernetes-helm
                kubeseal # for sealed secrets
                tailscale
                devpod

                # terminal
                aspell
                aspellDicts.en
                bash-completion
                zsh-powerlevel10k
                openssh
                starship
		        tmux
                ripgrep
            ];

            homebrew = {
                enable = true;
                taps = [
                    "siderolabs/tap"
                ];
                brews = [
                    "ffmpeg"
                    "mas"
                    "siderolabs/tap/talosctl"
                    "glslang"
                ];
                casks = [
                    "ghostty"
                    "voiceink"
                    "sublime-text"
                    "hammerspoon"
                    "zen"
                    "iina"
                    "the-unarchiver"
                ];
                masApps = {
                    # "Slack" = 803453959;
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
                noto-fonts-color-emoji
                meslo-lgs-nf
                fira-code
            ];

            users.users.daniel = {
                home = "/Users/daniel";
                packages = with pkgs; [
                    nodejs_24
                    bun
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

            # Config files for npm and bun
            system.activationScripts.extraActivation.text = ''
                # bun config
                echo 'minimumReleaseAge = "7 days"' > /Users/daniel/.bunfig.toml
                chown daniel:staff /Users/daniel/.bunfig.toml

                # npm config - append if not present
                if ! grep -q 'min-release-age' /Users/daniel/.npmrc 2>/dev/null; then
                    echo 'min-release-age=7d' >> /Users/daniel/.npmrc
                fi
                chown daniel:staff /Users/daniel/.npmrc
            '';

            system.activationScripts.applications.text = let
                env = pkgs.buildEnv {
                    name = "system-applications";
                    paths = config.environment.systemPackages;
                    pathsToLink = [ "/Applications" ];
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

            programs.zsh = {
                enable = true;
                promptInit = "";
                interactiveShellInit = ''
                    source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
                    eval "$(${pkgs.starship}/bin/starship init zsh)"

                    # swap tab and right arrow in zsh
                    bindkey '^I' autosuggest-accept
                    bindkey '^[[1;5C' expand-or-complete
                '';
            };

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
            nix.gc = {
                automatic = true;
                interval = { Weekday = 0; Hour = 2; Minute = 0; };
                options = "--delete-older-than 30d";
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
