{
  lib,
  buildDotnetModule,
  fetchFromGitHub,
  dotnetCorePackages,
}:

buildDotnetModule (finalAttrs: {
  pname = "credential-manager";
  version = "0.0.6";

  src = fetchFromGitHub {
    owner = "slp-tongji";
    repo = "CredentialManager";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Fg4uPvwOEOv3BamwSZoc9lbcuOz50n4RhJOj18kVck8=";
  };

  projectFile = "src/Tjslp.CredentialManager/Tjslp.CredentialManager.csproj";
  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_10_0;

  executables = [ "Tjslp.CredentialManager" ];

  nugetDeps = ./deps.nix;

  strictDeps = true;
  __structuredAttrs = true;

  meta = {
    description = "OIDC login + self-managed downstream credentials web service";
    homepage = "https://github.com/slp-tongji/CredentialManager";
    license = lib.licenses.mit;
    mainProgram = "Tjslp.CredentialManager";
    maintainers = [ ];
  };
})
