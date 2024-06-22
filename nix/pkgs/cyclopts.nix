{ lib
, fetchFromGitHub
, buildPythonPackage
  # native deps
, poetry-core
, poetry-dynamic-versioning
  # deps
, attrs
, docstring-parser
, importlib-metadata
, rich
, rich-rst
, typing-extensions
  # optional deps
, tomli
, pyyaml
,
}:
buildPythonPackage rec {
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
    poetry-core
    poetry-dynamic-versioning
  ];

  propagatedBuildInputs = [
    attrs
    docstring-parser
    importlib-metadata
    rich
    rich-rst
    typing-extensions
  ];

  passthru.optional-dependencies = {
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
