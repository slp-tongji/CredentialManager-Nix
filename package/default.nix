{
  lib,
  buildDotnetModule,
  fetchFromGitHub,
  dotnetCorePackages,
}:

buildDotnetModule (finalAttrs: {
  pname = "credential-manager";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "slp-tongji-68462dff5c2b4d79b999f6e";
    repo = "CredentialManager";
    rev = "v${finalAttrs.version}";
    hash = "sha256-fnuNnXe2UpGz3e+3dDyTJN2I+5gDLfGCrmr8qoDhw+s=";
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
    homepage = "https://github.com/slp-tongji-68462dff5c2b4d79b999f6e/CredentialManager";
    license = lib.licenses.mit;
    mainProgram = "Tjslp.CredentialManager";
    maintainers = [ ];
  };
})
