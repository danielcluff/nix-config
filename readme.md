### Setup Nix for my mac
commands and such

## Install
# Install nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    pick no for installing determinate

# Isntall nix darwin
nix flake init -t nix-darwin/master
    this command replaced the simple string with the computer name
    used when starting a new flake.nix file
sed -i '' "s/simple/$(scutil --get LocalHostName)/" flake.nix


setup nix-darwin latest
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/nix-config

# homebrew
add the following line to ~/.zshrc
export PATH="/opt/homebrew:$PATH"


## Run
sudo darwin-rebuild switch --flake ~/nix-config


## Update
sudo nix flake update


## Commands
homebrews
mas search appname