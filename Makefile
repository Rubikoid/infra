HOST ?= $(shell hostname)

.PHONY: system
.DEFAULT: system

system:
	sudo nixos-rebuild switch --flake ~/infra/nix#${HOST} -v
