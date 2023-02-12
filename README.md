# Fix VSCode Server

Patches the VSCode server and extensions when running on a NixOS server.

Extensions need libraries, and there are two strategies for this:

* Path extensions with impure paths
* Wrap node in an `FhsUserEnv`

I found FHS environments had many quirks in the terminal, such as:

* `sudo` not working: [nixpkgs#42117](https://github.com/NixOS/nixpkgs/issues/42117)
* ssh config provided by home-manager not working: [home-manager#322](https://github.com/nix-community/home-manager/issues/322)

This commits a nix sin and creates impure paths to avoid using an `FhsUserEnv`.

## Usage

Please note that this script is a hack.  Do not expect a polished experience.

1. Run VSCode on the client, and connect to a remote host, wait for install to fail.
2. Run this script on the server.
3. Re-connect from the client VSCode and it should work now.
