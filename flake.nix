{
  description = "CredentialManager — OIDC login + self-managed downstream credentials web service";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      packages = forAllSystems (
        system:
        let
          package = nixpkgs.legacyPackages.${system}.callPackage ./package { };
        in
        {
          credential-manager = package;
          default = package;
        }
      );

      nixosModules =
        let
          module = ./nixos-module;
        in
        {
          credential-manager = module;
          default = module;
        };
    };
}
