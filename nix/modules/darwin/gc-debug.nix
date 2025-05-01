{ mode, lib, ... }:
{
  config.launchd = lib.mkMerge [
    (lib.mkIf (mode == "Darwin-HM") {
      agents.nix-gc = {
        config = {
          StandardOutPath = "/tmp/nix-gc-user.out.log";
          StandardErrorPath = "/tmp/nix-gc-user.err.log";
        };
      };
    })
    # (lib.mkIf (mode == "Darwin") {
    #   daemons.nix-gc = {
    #     serviceConfig = {
    #       StandardOutPath = "/tmp/nix-gc-user.out.log";
    #       StandardErrorPath = "/tmp/nix-gc-user.err.log";
    #     };
    #   };
    # })
  ];
}
