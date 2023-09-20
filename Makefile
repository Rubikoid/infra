HOST ?= $(shell hostname)

.PHONY: system deploy clean
.DEFAULT: system

system:
	sudo nixos-rebuild switch --flake ~/infra/nix#$(HOST) -v $(args)

deploy:
	rsync \
		-rlptD \
		--delete \
		-vzhP \
		--exclude 'flake.lock' \
		. \
		$(target):~/infra

clean:
	sudo nix-collect-garbage -d
	sudo nix-env --delete-generations +1
	sudo nix-store --gc
	sudo rm /nix/var/nix/gcroots/auto/*
	sudo nix-collect-garbage -d
