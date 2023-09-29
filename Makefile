HOST ?= $(shell hostname)
USER ?= $(shell whoami)

FLAKE_PATH = ~/infra/nix?submodules=1

.PHONY: system user deploy short-clean clean
.DEFAULT: system

system:
	echo "[+] Building system"
	sudo nixos-rebuild switch --flake $(FLAKE_PATH)#$(HOST) -v $(args)

user:
	echo "[+] Building user"
	home-manager switch --flake $(FLAKE_PATH)#$(USER) -L $(args)

deploy:
	rsync \
		-rlptD \
		--delete \
		-vzhP \
		--exclude 'flake.lock' $(args) \
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
