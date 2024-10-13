#!/usr/bin/env just --justfile

HOST := `hostname -s`
USER := `whoami`

# BASE_FLAKE := home_directory() / "infra/nix"
BASE_FLAKE := justfile_directory() / "nix"
FLAKE_PATH := canonicalize(BASE_FLAKE) + "?submodules=1"

default_cmd := "switch"
default_args := ""

rebuild_cmd := if os() == "linux" { 
    "sudo nixos-rebuild" 
} else if os() == "macos"{
    "darwin-rebuild"
} else { "echo unable to do it; " }

nix := "n"

nom := if HOST == "kubic" { "|& nom" } else { "" }

diff-current-system := "/nix/var/nix/profiles/system"

DISABLE_BUILDERS := "0"
builders := if DISABLE_BUILDERS == "1" { "--builders ''" } else { "" }

default: system

help:
  @just --list --justfile {{justfile()}}

system cmd=default_cmd *args=default_args:
    @echo "[+] Building system: '{{HOST}}' at '{{FLAKE_PATH}}'"
    {{rebuild_cmd}} {{cmd}} --flake "{{FLAKE_PATH}}#{{HOST}}" {{args}} {{nom}}

system-off cmd=default_cmd *args=default_args:
    @echo "[+] Building system: '{{HOST}}' at '{{FLAKE_PATH}}'"
    {{rebuild_cmd}} {{cmd}} --builders "" {{args}} --flake "{{FLAKE_PATH}}#{{HOST}}" {{nom}}

system-build-diff *args=default_args:
    @echo "[+] Building system: '{{HOST}}' at '{{FLAKE_PATH}}'"
    {{rebuild_cmd}} build --flake "{{FLAKE_PATH}}#{{HOST}}" {{args}} {{nom}}
    nix run "{{nix}}#nvd" diff "{{diff-current-system}}" "./result"
    rm ./result

system-inspect:
    nix run "{{nix}}#nix-tree" -- '/var/run/current-system'

system-inspect-deriv:
    nix run "{{nix}}#nix-tree" -- --derivation '/var/run/current-system'

system-inspect-nb hostname:
    nix run "{{nix}}#nix-tree" -- --derivation "{{FLAKE_PATH}}#nixosConfigurations.{{hostname}}.config.system.build.toplevel"

repl:
    nix repl --file './nix/test.nix' --show-trace

sys-repl *args=default_args:
    @echo "[+] Opening REPL for '{{HOST}}' at '{{FLAKE_PATH}}'"
    nix --extra-experimental-features repl-flake repl "{{FLAKE_PATH}}#nixosConfigurations.{{HOST}}" {{args}}


flake action="show" *args=default_args:
    nix flake {{action}} {{args}} "{{FLAKE_PATH}}"

home cmd=default_cmd *args=default_args:
    @echo "[+] Building user '{{USER}}' at '{{FLAKE_PATH}}'"
    home-manager {{cmd}} {{args}} --flake "{{FLAKE_PATH}}#{{USER}}" {{nom}}

build pkg *args=default_args:
    nix build "{{FLAKE_PATH}}#{{pkg}}" -v {{args}}

pkg pkg *args=default_args:
	echo "[+] Building package: {{pkg}} at {{HOST}}"
	nix build "{{FLAKE_PATH}}#nixosConfigurations.{{HOST}}.pkgs.{{pkg}}" -v {{args}}

eval attr *args=default_args:
    nix eval "{{FLAKE_PATH}}#{{attr}}" {{args}}

run-vm name *args=default_args:
    nix run {{args}} "{{FLAKE_PATH}}#nixosConfigurations.{{name}}.config.microvm.declaredRunner"

get-age-key:
    nix shell "{{nix}}#ssh-to-age" --command sh -c 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'

develop shell="default" *args=default_args: 
    nix develop "{{FLAKE_PATH}}#{{shell}}" {{args}} -c "$SHELL"

[no-cd]
shell shell="default" *args=default_args: 
    nix develop "{{FLAKE_PATH}}#{{shell}}" {{args}} -c "$SHELL"

[no-cd]
[private]
_shell shell="default" *args=default_args: 
    nix develop "{{FLAKE_PATH}}#{{shell}}" {{args}}

deploy target *args=default_args:
    @echo "I am {{canonicalize(source_directory())}}"
    rsync \
        -rlptD \
        --delete \
        -vzhP \
        --exclude=".direnv" \
        --exclude=".stfolder" \
        --exclude=".venv" \
        --checksum --ignore-times \
        {{args}} \
        "{{canonicalize(source_directory())}}/" \
        {{target}}:~/infra


deploy-rebuild target *args=default_args: (deploy target)
    ssh {{target}} just --justfile '~/infra/Justfile' system switch --no-update-lock-file {{ args }}

remote-sw hostname target *args=default_args:
    @echo "DISABLE_BUILDERS: {{ DISABLE_BUILDERS }}"
    @echo "HOST: {{ HOST }}"
    nixos-rebuild switch --flake "{{FLAKE_PATH}}#{{hostname}}" --target-host "{{target}}" --verbose --show-trace {{args}} {{builders}} # --build-host "root@{{target}}.prod.tests.rubikoid.ru" 

vm-run hostname *args=default_args:
    nix run "{{FLAKE_PATH}}#nixosConfigurations.{{hostname}}.config.system.build.vm" {{args}}

short-clean:
    sudo nix-collect-garbage -d

clean:
    sudo nix-collect-garbage -d
    sudo nix-env --delete-generations +1
    sudo nix-store --gc
    sudo rm /nix/var/nix/gcroots/auto/*
    sudo nix-collect-garbage -d

nds deriv:
    nix derivation show "{{deriv}}" | jq -C | less -R
