# This file was generated by pkgs.mastodon.updateScript.
{ fetchFromGitHub, applyPatches, patches ? [] }:
let
  version = "d7d4770";
  revision = "d7d477047eba7cb88df54dd78f42095ed0fbea76";
in
(
  applyPatches {
    src = fetchFromGitHub {
      owner = "glitch-soc";
      repo = "mastodon";
      rev = "${revision}";
      hash = "sha256-x1fqDtCOiNS61EhnpObUuxrdTd5n2mhjoGbIYGivbDg=";
    };
    patches = patches ++ [./yarn-typescript.patch];
  }) // {
  inherit version;
  yarnHash = "sha256-CIIz5wwWzvDKc/VbSIT7Z5D9kwOLoErXoO0WQWfV/g4=";
}
