{
  config,
  lib,
  defaultPackage,
  ...
}:

{
  options.services.credential-manager = {
    enable = lib.mkEnableOption "CredentialManager (OIDC login + self-managed downstream credentials web service)";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      description = "The CredentialManager package to use.";
    };

    listen = lib.mkOption {
      type = lib.types.str;
      example = "http://127.0.0.1:8080";
      description = ''
        The address to listen on, as a full URL (e.g. `http://127.0.0.1:8080`).

        The service assumes it sits behind a same-host reverse proxy, so it
        trusts forwarded headers from loopback. Bind to loopback and let a
        reverse proxy terminate TLS in front of it.
      '';
    };

    title = lib.mkOption {
      type = lib.types.str;
      example = "My Platform";
      description = "Platform name shown in the page title.";
    };

    stateDirectory = lib.mkOption {
      type = lib.types.str;
      default = "credential-manager";
      description = ''
        Name of the systemd `StateDirectory` used to store the LiteDB file
        `credentials.db`. It is created and owned by the service user
        automatically, and the data is written to `/var/lib/` followed by this
        value (i.e. `/var/lib/credential-manager` by default).
      '';
    };

    downstream = lib.mkOption {
      type = lib.types.str;
      example = "https://downstream.example.com";
      description = "Base URL of the downstream credential service.";
    };

    administrator = lib.mkOption {
      type = lib.types.str;
      example = "administrators";
      description = "Name of the Dex `groups` value that grants administrator access.";
    };

    oidc = lib.mkOption {
      type = lib.types.str;
      example = "https://dex.example.com";
      description = "OIDC authority (Dex) URL.";
    };

    oidcId = lib.mkOption {
      type = lib.types.str;
      example = "credential-manager";
      description = "OIDC client id.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/credentials/credential-manager.env";
      description = ''
        Optional systemd `EnvironmentFile` to load environment variables from
        (one `KEY=value` per line). This is where the OIDC client secret should
        be provided as `CM_OIDC_SECRET=...`, so it never appears in the process
        command line.

        It is common to generate this from a secret managed by agenix/sops.
      '';
    };
  };

  config = lib.mkIf config.services.credential-manager.enable {
    systemd.services.credential-manager = {
      description = "CredentialManager — OIDC login + self-managed downstream credentials";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = ''
          ${lib.getExe config.services.credential-manager.package} \
            --listen "${config.services.credential-manager.listen}" \
            --title "${config.services.credential-manager.title}" \
            --data "/var/lib/${config.services.credential-manager.stateDirectory}" \
            --downstream "${config.services.credential-manager.downstream}" \
            --administrator "${config.services.credential-manager.administrator}" \
            --oidc "${config.services.credential-manager.oidc}" \
            --oidc-id "${config.services.credential-manager.oidcId}"
        '';

        DynamicUser = true;

        EnvironmentFile = config.services.credential-manager.environmentFile;

        StateDirectory = config.services.credential-manager.stateDirectory;
        WorkingDirectory = "/var/lib/${config.services.credential-manager.stateDirectory}";

        Restart = "on-failure";
        RestartSec = "5s";

        CapabilityBoundingSet = "";
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
    };
  };
}
