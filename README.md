# CredentialManager-Nix

Nix packaging for [CredentialManager](https://github.com/slp-tongji-68462dff5c2b4d79b999f6e/CredentialManager) — an OIDC login + self-managed downstream credentials web service.

## Adding as a flake input

```nix
{
  inputs = {
    credential-manager.url = "github:slp-tongji-68462dff5c2b4d79b999f6e/CredentialManager-Nix";
  };
}
```

## Package

The binary is exposed as `Tjslp.CredentialManager`:

```nix
credential-manager.packages.${system}.credential-manager
```

Or try it directly from the CLI:

```console
$ nix shell github:slp-tongji-68462dff5c2b4d79b999f6e/CredentialManager-Nix
$ CM_OIDC_SECRET=my-secret Tjslp.CredentialManager \
    --listen http://127.0.0.1:8080 \
    --title "My Platform" \
    --data /var/lib/credential-manager \
    --downstream https://downstream.example.com \
    --administrator administrators \
    --oidc https://dex.example.com \
    --oidc-id credential-manager
```

## NixOS module

A module is exposed as `nixosModules.credential-manager` (also available as
`nixosModules.default`):

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    credential-manager.url = "github:slp-tongji-68462dff5c2b4d79b999f6e/CredentialManager-Nix";
  };

  outputs = { nixpkgs, credential-manager, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        credential-manager.nixosModules.default
        {
          services.credential-manager = {
            enable = true;
            listen = "http://127.0.0.1:8080";
            title = "My Platform";
            downstream = "https://downstream.example.com";
            administrator = "administrators";
            oidc = "https://dex.example.com";
            oidcId = "credential-manager";
            environmentFile = "/run/credentials/credential-manager.env";
          };
        }
      ];
    };
  };
}
```

The module runs the service as a systemd unit with a dynamic system user and a
`StateDirectory` for the credential database.

Options under `services.credential-manager`:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `enable` | bool | `false` | Whether to enable the service |
| `package` | package | this flake's package | The package to install |
| `listen` | str | (required) | Address to listen on, as a full URL (e.g. `http://127.0.0.1:8080`) |
| `title` | str | (required) | Platform name shown in the page title |
| `stateDirectory` | str | `"credential-manager"` | systemd `StateDirectory` (under `/var/lib`) holding the LiteDB file |
| `downstream` | str | (required) | Base URL of the downstream credential service |
| `administrator` | str | (required) | Dex `groups` value that grants administrator access |
| `oidc` | str | (required) | OIDC authority (Dex) URL |
| `oidcId` | str | (required) | OIDC client id |
| `environmentFile` | nullOr path | `null` | systemd `EnvironmentFile` providing `CM_OIDC_SECRET` |

The service assumes it sits behind a same-host reverse proxy, so bind to
loopback and let the reverse proxy terminate TLS in front of it. The OIDC
client secret is provided via `environmentFile` (as `CM_OIDC_SECRET=...`) so it
never appears on the process command line.

---

All documentation and `description` fields in this repository are AI-generated.
