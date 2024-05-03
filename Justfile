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

default: system

help:
  @just --list --justfile {{justfile()}}

system cmd=default_cmd *args=default_args:
    @echo "[+] Building system: '{{HOST}}' at '{{FLAKE_PATH}}'"
    {{rebuild_cmd}} {{cmd}} -v --no-update-lock-file {{args}} --flake "{{FLAKE_PATH}}#{{HOST}}"

system-inspect:
	nix run "{{nix}}#nix-tree" -- '/var/run/current-system'

system-inspect-deriv:
	nix run "{{nix}}#nix-tree" -- --derivation '/var/run/current-system'

system-inspect-nb:
	nix run "{{nix}}#nix-tree" -- --derivation "'{{FLAKE_PATH}}'#nixosConfigurations.'{{HOST}}'.config.system.build.toplevel"

repl:
	nix repl --file './nix/test.nix'

# user:
# 	echo "[+] Building user"
# 	home-manager $(cmd) --flake $(FLAKE_PATH)#$(USER) -L $(args)

# pkg:
# 	echo "[+] Building package: $(pkg)"
# 	nix build $(FLAKE_PATH)#nixosConfigurations.$(HOST).pkgs.$(pkg) -v $(args)

# flake:
# 	nix flake $(flk) -v $(args) $(FLAKE_PATH) 

# develop:
# 	nix develop $(args) $(FLAKE_PATH)

deploy target *args=default_args:
	rsync \
		-rlptD \
		--delete \
		-vzhP \
		{{args}} \
		. \
		{{target}}:~/infra

short-clean:
	sudo nix-collect-garbage -d

clean:
	sudo nix-collect-garbage -d
	sudo nix-env --delete-generations +1
	sudo nix-store --gc
	sudo rm /nix/var/nix/gcroots/auto/*
	sudo nix-collect-garbage -d
