HOST ?= $(shell hostname)
USER ?= $(shell whoami)

FLAKE_PATH = ~/infra/nix?submodules=1

cmd ?= switch

.PHONY: system system-inspect system-inspect-deriv repl user deploy short-clean clean
.DEFAULT: system

system:
	echo "[+] Building system"
	sudo nixos-rebuild $(cmd) --flake $(FLAKE_PATH)#$(HOST) -v $(args)

system-inspect:
	nix run github:utdemir/nix-tree -- '/var/run/current-system'

system-inspect-deriv:
	nix run github:utdemir/nix-tree -- --derivation '/var/run/current-system'

repl:
	nix repl --file './nix/test.nix'

user:
	echo "[+] Building user"
	home-manager $(cmd) --flake $(FLAKE_PATH)#$(USER) -L $(args)

pkg:
	echo "[+] Building package: $(pkg)"
	nix build $(FLAKE_PATH)#nixosConfigurations.$(HOST).pkgs.$(pkg) -v $(args)

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
