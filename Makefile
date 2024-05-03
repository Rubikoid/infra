HOST ?= $(shell hostname -s)
USER ?= $(shell whoami)

BASE_FLAKE = ~/infra/nix
FLAKE_PATH = $(shell realpath $(BASE_FLAKE))?submodules=1

# DARWIN_FLAKE_PATH = /Users/rubikoid/projects/personal/infra/nix?submodules=1

cmd ?= switch
flk ?= check

.PHONY: system system-darwin system-inspect system-inspect-deriv system-inspect-nb repl user pkg flake develop deploy short-clean clean
.DEFAULT: system

system:
	echo "[+] Building system"
	sudo nixos-rebuild $(cmd) --flake $(FLAKE_PATH)#$(HOST) -v --no-update-lock-file $(args)

system-darwin:
	echo "[+] Building darwin system"
	darwin-rebuild $(cmd) --flake $(FLAKE_PATH)#$(HOST) -v $(args)

system-inspect:
	nix run n#nix-tree -- '/var/run/current-system'

system-inspect-deriv:
	nix run n#nix-tree -- --derivation '/var/run/current-system'

system-inspect-nb:
	nix run n#nix-tree -- --derivation "$(FLAKE_PATH)"#nixosConfigurations."$(HOST)".config.system.build.toplevel

repl:
	nix repl --file './nix/test.nix'

user:
	echo "[+] Building user"
	home-manager $(cmd) --flake $(FLAKE_PATH)#$(USER) -L $(args)

pkg:
	echo "[+] Building package: $(pkg)"
	nix build $(FLAKE_PATH)#nixosConfigurations.$(HOST).pkgs.$(pkg) -v $(args)

flake:
	nix flake $(flk) -v $(args) $(FLAKE_PATH) 

develop:
	nix develop $(args) $(FLAKE_PATH)

deploy:
	rsync \
		-rlptD \
		--delete \
		-vzhP \
		$(args) \
		. \
		$(target):~/infra

short-clean:
	sudo nix-collect-garbage -d

clean:
	sudo nix-collect-garbage -d
	sudo nix-env --delete-generations +1
	sudo nix-store --gc
	sudo rm /nix/var/nix/gcroots/auto/*
	sudo nix-collect-garbage -d
