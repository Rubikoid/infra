HOST ?= $(shell hostname)

.PHONY: system deploy short-clean clean
.DEFAULT: system

system:
	sudo nixos-rebuild switch --flake ~/infra/nix?submodules=1#$(HOST) -v $(args)

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
