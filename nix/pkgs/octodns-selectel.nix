{ lib
, buildPythonPackage
, fetchFromGitHub
, octodns
, pytestCheckHook
, pythonOlder
, requests
, requests-mock
, setuptools
}:

buildPythonPackage rec {
  pname = "octodns-selectel";
  version = "0.99.3-unstable-2024-09-08";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "octodns";
    repo = "octodns-selectel";
    rev = "21dadcf39fa5e8cbfea9b97519f47f1976551985";
    hash = "sha256-kVC2hEXWcGoQJzi7BFkNLPI4UFhxfYpIunOleRw9nfE=";
  };

  nativeBuildInputs = [
    setuptools
  ];

  propagatedBuildInputs = [
    octodns
    requests
  ];

  pythonImportsCheck = [ "octodns_selectel" ];

  nativeCheckInputs = [
    pytestCheckHook
    requests-mock
  ];

  meta = with lib; {
    description = "Selectel DNS provider for octoDNS";
    homepage = "https://github.com/octodns/octodns-selectel/";
    changelog = "https://github.com/octodns/octodns-selectel/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = [ ];
  };
}
