{ lib
, fetchFromGitHub
, python312
,
}:
let
  python = python312;
in
python.pkgs.buildPythonPackage rec {
  pname = "cyclopts";
  version = "2.7.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "BrianPugh";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-oYYsHT8VZdqcOkMj++Bh7xjZ3JfJ9CiacFt92lBiQmc=";
  };

  nativeBuildInputs = [
    python.pkgs.poetry-core
    python.pkgs.poetry-dynamic-versioning
  ];

  propagatedBuildInputs = with python.pkgs; [
    attrs
    docstring-parser
    importlib-metadata
    rich
    rich-rst
    typing-extensions
  ];

  passthru.optional-dependencies = with python.pkgs; {
    toml = [
      tomli
    ];
    yaml = [
      pyyaml
    ];
  };

  pythonImportsCheck = [ "cyclopts" ];

  meta = with lib; {
    description = "Intuitive, easy CLIs based on python type hints";
    homepage = "https://github.com/BrianPugh/cyclopts/tree/main";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    mainProgram = "cyclopts";
  };
}
