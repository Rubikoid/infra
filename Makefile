HOST ?= $(shell hostname)

.PHONY: system
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
