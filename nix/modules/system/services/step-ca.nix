{ inputs, config, pkgs, lib, ... }:

let
  mkBinarySecrets = pkgs.my-lib.mkBinarySecrets;
  secretsPermData = {
    mode = "400";
    owner = config.users.users.step-ca.name;
    group = config.users.groups.step-ca.name;
  };
in
{
  environment.systemPackages = with pkgs; [
    step-cli
  ];

  sops.secrets = (
    {
      "step_ca_pw" = {
        sopsFile = config.deviceSecrets + "/secrets.yaml";
      };
    }
    //
    mkBinarySecrets (config.deviceSecrets + "/step/") secretsPermData [ "step.hjson" ]
    //
    mkBinarySecrets (config.deviceSecrets + "/step/") secretsPermData [
      # certs
      "certs/intermediate_ca.crt"
      "certs/root_ca.crt"
      "certs/ssh_host_ca_key.pub"
      "certs/ssh_user_ca_key.pub"
      # keys
      "keys/intermediate_ca.key"
      # "keys/root_ca.key"
      "keys/ssh_host_ca.key"
      "keys/ssh_user_ca.key"
    ]
  );


  services.step-ca = {
    enable = true;
    openFirewall = false;

    intermediatePasswordFile = config.sops.secrets.step_ca_pw.path;

    address = "127.0.0.1";
    port = 4443;

    settings = {
      root = config.sops.secrets."certs/root_ca.crt".path;
      crt = config.sops.secrets."certs/intermediate_ca.crt".path;
      key = config.sops.secrets."keys/intermediate_ca.key".path;

      ssh = {
        hostKey = config.sops.secrets."keys/ssh_host_ca.key".path;
        userKey = config.sops.secrets."keys/ssh_user_ca.key".path;
      };

      db = {
        type = "badgerv2";
        dataSource = "/var/lib/step-ca/db";
        badgerFileLoadingMode = "";
      };
    };
  };

  systemd.services."step-ca" = {
    serviceConfig = {
      ExecStart = lib.mkForce [
        "" # override upstream ;(((
        (pkgs.my-lib.makeJobScript
          "step-ca-start"
          ''
            set -euo pipefail

            # prepare config file
            echo \
              '${builtins.toJSON config.services.step-ca.settings}' \
              $(cat '${config.sops.secrets."step.hjson".path}') \
              '{ "address": "${config.services.step-ca.address + ":" + toString config.services.step-ca.port}" }' \
            | ${pkgs.jq}/bin/jq -s add > /var/lib/step-ca/step-ca.json

            ${config.services.step-ca.package}/bin/step-ca /var/lib/step-ca/step-ca.json --password-file $CREDENTIALS_DIRECTORY/intermediate_password
          ''
        )
      ];
    };
  };

  environment.etc."smallstep/ca.json".source = lib.mkForce "/dev/null";
}
