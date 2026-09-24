# CredentialManager Nix 打包

为 [CredentialManager](https://github.com/slp-tongji-68462dff5c2b4d79b999f6e/CredentialManager)（一个「OIDC 登录 + 自管理下游凭证」的 Web 服务）提供的 Nix flake 与 NixOS module。

上游项目本身是用 .NET 10 / Razor Pages 写成的服务，本仓库负责把它打成 Nix 包，并提供开箱即用的 NixOS 服务配置。

## 提供的 flake outputs

| Output | 说明 |
|--------|------|
| `packages.<system>.credential-manager` | 打好的主程序包（`Tjslp.CredentialManager`） |
| `packages.<system>.default` | `credential-manager` 的别名 |
| `nixosModules.credential-manager` | NixOS module，暴露 `services.credential-manager` |
| `nixosModules.default` | `credential-manager` 的别名 |

## 作为包使用

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    credential-manager.url = "github:slp-tongji-68462dff5c2b4d79b999f6e/CredentialManager-Nix";
  };

  outputs = { nixpkgs, credential-manager, ... }: {
    packages.x86_64-linux.credential-manager =
      credential-manager.packages.x86_64-linux.default;
  };
}
```

```bash
nix build .#credential-manager
./result/bin/Tjslp.CredentialManager --help
```

> 程序是 `Microsoft.NET.Sdk.Web` 应用，采用框架依赖发布（`framework-dependent`），
> 由 `buildDotnetModule` 打包时链入 ASP.NET Core 运行时（`aspnetcore_10_0`），
> 并通过 wrapper 设置 `DOTNET_ROOT`，因此无需在宿主机上预装 .NET。

### 升级上游版本

包通过 `fetchFromGitHub` 锁定上游源码的 tag。上游仓库用 `v<version>` 形式的 tag（如 `v0.0.1`）：

1. 在 `package/default.nix` 里更新 `version`（`rev` 会自动跟着变成 `v<version>`）。
2. 重新计算 `hash`：

   ```bash
   nix flake prefetch \
     github:slp-tongji-68462dff5c2b4d79b999f6e/CredentialManager/v0.0.2
   ```

3. 若依赖有变化，重新生成 NuGet 依赖锁：

   ```bash
   nix build '.#default.passthru.fetch-deps' --no-link --print-out-paths
   # 运行产出的脚本，把 package/deps.nix 写回仓库（先临时把 deps.nix 换成旧值再跑也行）
   ```

## 作为 NixOS module 使用

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    credential-manager.url = "github:slp-tongji-68462dff5c2b4d79b999f6e/CredentialManager-Nix";
  };

  outputs = { nixpkgs, credential-manager, ... }: {
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        credential-manager.nixosModules.default

        ({ ... }: {
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
        })
      ];
    };
  };
}
```

### `environmentFile`

OIDC client secret 不应出现在命令行里。通过 `environmentFile` 提供 —— 它是一个 systemd
`EnvironmentFile`（每行一个 `KEY=value`），内容形如：

```
CM_OIDC_SECRET=my-super-secret
```

对应上游程序的 `--oidc-secret` / `CM_OIDC_SECRET` 环境变量。可配合 sops-nix、agenix
等秘密管理工具生成。若省略 `environmentFile`，则 secret 不会注入，程序会因缺少该参数而拒绝启动。

### 可选配置

| Option | 默认值 | 说明 |
|--------|--------|------|
| `package` | flake 自身包 | 覆盖要用的包 |
| `stateDirectory` | `"credential-manager"` | systemd `StateDirectory` 名，LiteDB 文件写入 `/var/lib/<name>` |

### 运行形态

- 服务以 `DynamicUser = true` 运行，systemd 自动创建一个隔离的临时用户。
- 数据写到 `StateDirectory`（`/var/lib/credential-manager`），服务只对该目录有写权限。
- 通过 `ForwardedHeaders` 假定跑在同一台主机的反向代理之后，因此请用 loopback 监听并让
  反向代理（如 nginx / caddy）在前面终结 TLS。
- 已启用一组 systemd 沙箱加固项（`ProtectSystem=strict`、`NoNewPrivileges`、
  `CapabilityBoundingSet=""` 等）。
