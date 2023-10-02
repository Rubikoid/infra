lib: rec {
  mkBinarySecrets =
    basePath: paths:
    builtins.listToAttrs
      (map
        (
          pathName: {
            name = pathName;
            value = {
              sopsFile = basePath + "/" + pathName;
              format = "binary";
            };
          }
        )
        paths
      );
}
