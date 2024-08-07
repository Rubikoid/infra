#!/usr/bin/env just --justfile

HOST := `hostname -s`
USER := `whoami`

BASE_FLAKE := home_directory() / "infra/nix"
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

default: system

help:
  @just --list --justfile {{justfile()}}

system cmd=default_cmd *args=default_args:
    @echo "[+] Building system: '{{HOST}}' at '{{FLAKE_PATH}}'"
    {{rebuild_cmd}} {{cmd}} --flake "{{FLAKE_PATH}}#{{HOST}}" {{args}} {{nom}}

system-off cmd=default_cmd *args=default_args:
    @echo "[+] Building system: '{{HOST}}' at '{{FLAKE_PATH}}'"
    {{rebuild_cmd}} {{cmd}} --builders "" {{args}} --flake "{{FLAKE_PATH}}#{{HOST}}" {{nom}}

system-inspect:
    nix run "{{nix}}#nix-tree" -- '/var/run/current-system'

system-inspect-deriv:
    nix run "{{nix}}#nix-tree" -- --derivation '/var/run/current-system'

system-inspect-nb:
    nix run "{{nix}}#nix-tree" -- --derivation "{{FLAKE_PATH}}#nixosConfigurations.'{{HOST}}'.config.system.build.toplevel"

repl:
    nix repl --file './nix/test.nix'

flake action="show" *args=default_args:
    nix flake {{action}} {{args}} "{{FLAKE_PATH}}"

home cmd=default_cmd *args=default_args:
    @echo "[+] Building user '{{USER}}' at '{{FLAKE_PATH}}'"
    home-manager {{cmd}} {{args}} --flake "{{FLAKE_PATH}}#{{USER}}" {{nom}}

build pkg *args=default_args:
    nix build "{{FLAKE_PATH}}#{{pkg}}" -v {{args}}

eval attr *args=default_args:
    nix eval "{{FLAKE_PATH}}#{{attr}}" {{args}}

run-vm name *args=default_args:
    nix run {{args}} "{{FLAKE_PATH}}#nixosConfigurations.{{name}}.config.microvm.declaredRunner"

get-age-key:
    nix shell "{{nix}}#ssh-to-age" --command sh -c 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'

# pkg:
# 	echo "[+] Building package: $(pkg)"
# 	nix build $(FLAKE_PATH)#nixosConfigurations.$(HOST).pkgs.$(pkg) -v $(args)

# develop:
# 	nix develop $(args) $(FLAKE_PATH)

develop shell="default" *args=default_args: 
    nix develop "{{FLAKE_PATH}}#{{shell}}" {{args}} -c "$SHELL"

deploy target *args=default_args:
    rsync \
        -rlptD \
        --delete \
        -vzhP \
        --exclude=".direnv" \
        --exclude=".stfolder" \
        {{args}} \
        . \
        {{target}}:~/infra


deploy-rebuild target *args=default_args: (deploy target)
    ssh {{target}} just --justfile '~/infra/Justfile' system switch --no-update-lock-file {{ args }}

short-clean:
    sudo nix-collect-garbage -d

clean:
    sudo nix-collect-garbage -d
    sudo nix-env --delete-generations +1
    sudo nix-store --gc
    sudo rm /nix/var/nix/gcroots/auto/*
    sudo nix-collect-garbage -d
