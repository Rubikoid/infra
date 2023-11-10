{ pkgs, config, inputs, lib, ... }:

{
  virtualisation = {
    oci-containers.backend = "docker";

    docker = {
      enable = true;

      storageDriver = "overlay2";
      daemon.settings = {
        data-root = "/data/docker";
      };
    };
  };
}
