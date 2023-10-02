{ pkgs, config, inputs, lib, ... }:

{
  virtualisation = {
    oci-containers.backend = "docker";

    docker = {
      storageDriver = "overlay2";
      daemon.settings = {
        data-root = "/data/docker";
      };
    };
  };
}
