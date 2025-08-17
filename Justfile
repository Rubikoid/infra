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
} else if os() == "macos" {
    "sudo darwin-rebuild"
} else { "echo unable to do it; " }

remote_rebuild_cmd := if os() == "linux" { 
    "nixos-rebuild" 
} else if os() == "macos" {
    "nix run nixpkgs#nixos-rebuild --"
} else { "echo unable to do it; " }


nix := "n"

nom := if HOST == "kubic" { "|& nom" } else { "" }

diff-current-system := "/nix/var/nix/profiles/system"

DISABLE_BUILDERS := "0"
builders := if DISABLE_BUILDERS == "1" { "--builders ''" } else { "" }

export NIX_SSHOPTS := "-o ServerAliveInterval=60"

default: system

# show help
help:
  @just --list --justfile {{justfile()}}

# build system (and switch, via default-cmd)
system cmd=default_cmd *args=default_args:
    @echo "[+] Building system: '{{HOST}}' at '{{FLAKE_PATH}}'"
    {{rebuild_cmd}} {{cmd}} --flake "{{FLAKE_PATH}}#{{HOST}}" {{args}} {{nom}}

# build system without builders
system-off cmd=default_cmd *args=default_args:
    @echo "[+] Building system: '{{HOST}}' at '{{FLAKE_PATH}}'"
    {{rebuild_cmd}} {{cmd}} --builders "" {{args}} --flake "{{FLAKE_PATH}}#{{HOST}}" {{nom}}

# build system, show diff by nvd, and cleanup
system-build-diff *args=default_args:
    @echo "[+] Building system: '{{HOST}}' at '{{FLAKE_PATH}}'"
    {{rebuild_cmd}} build --flake "{{FLAKE_PATH}}#{{HOST}}" {{args}} {{nom}}
    nix run "{{nix}}#nvd" diff "{{diff-current-system}}" "./result"
    rm ./result

# build system, show diff by nix-diff, and cleanup
system-build-nix-diff *args=default_args:
    @echo "[+] Building system: '{{HOST}}' at '{{FLAKE_PATH}}'"
    {{rebuild_cmd}} build --flake "{{FLAKE_PATH}}#{{HOST}}" {{args}} {{nom}}
    nix run "{{nix}}#nix-diff" "{{diff-current-system}}" "./result"
    rm ./result

system-build-sdcard *args=default_args:
    @echo "[+] Building system sd card: '{{HOST}}' at '{{FLAKE_PATH}}'"
    nix build "{{FLAKE_PATH}}#nixosConfigurations.{{HOST}}.config.system.build.sdImage" {{args}} {{nom}}

system-build-qcow *args=default_args:
    @echo "[+] Building system qcow2: '{{HOST}}' at '{{FLAKE_PATH}}'"
    nix build "{{FLAKE_PATH}}#nixosConfigurations.{{HOST}}.config.system.build.qcow2" {{args}} {{nom}}

# nix-tree on current system
system-inspect:
    nix run "{{nix}}#nix-tree" -- '/var/run/current-system'

# nix-tree on current system derivation
system-inspect-deriv:
    nix run "{{nix}}#nix-tree" -- --derivation '/var/run/current-system'

# nix-tree on `hostname` derivation
system-inspect-nb hostname:
    nix run "{{nix}}#nix-tree" -- --derivation "{{FLAKE_PATH}}#nixosConfigurations.{{hostname}}.config.system.build.toplevel"

# run repl with test.nix loaded
repl:
    nix repl --file '{{canonicalize(source_directory()) / "nix" / "test.nix"}}' --show-trace

# run repl with test.nix loaded from base
repl-base:
    nix repl --file '{{canonicalize(source_directory()) / "nix" / "base" / "test.nix"}}' --show-trace

# run repl with HOST config prepared
sys-repl host=HOST *args=default_args:
    @echo "[+] Opening REPL for '{{ host }}' at '{{FLAKE_PATH}}'"
    nix repl "{{FLAKE_PATH}}#nixosConfigurations.{{ host }}" {{args}}

# run flake thing
flake action="show" *args=default_args:
    nix flake {{action}} {{args}} "{{FLAKE_PATH}}"

# build home (not used anymore i think)
home cmd=default_cmd *args=default_args:
    @echo "[+] Building user '{{USER}}' at '{{FLAKE_PATH}}'"
    home-manager {{cmd}} {{args}} --flake "{{FLAKE_PATH}}#{{USER}}" {{nom}}

# just build package
build pkg *args=default_args:
    nix build "{{FLAKE_PATH}}#{{pkg}}" -v {{args}}

# build package from some system (overlay)
pkg pkg *args=default_args:
	echo "[+] Building package: {{pkg}} at {{HOST}}"
	nix build "{{FLAKE_PATH}}#nixosConfigurations.{{HOST}}.pkgs.{{pkg}}" -v {{args}}

# don't remember
eval attr *args=default_args:
    nix eval "{{FLAKE_PATH}}#{{attr}}" {{args}}

# run vm with `name`
run-vm name *args=default_args:
    nix run {{args}} "{{FLAKE_PATH}}#nixosConfigurations.{{name}}.config.microvm.declaredRunner"

# get current host age key
get-age-key:
    nix --extra-experimental-features nix-command --extra-experimental-features flakes \
        shell "{{nix}}#ssh-to-age" --command sh -c 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'

# drop to shell with path changing
develop shell="default" *args=default_args: 
    nix develop "{{FLAKE_PATH}}#{{shell}}" {{args}} -c "$SHELL"

# drop to shell without path change
[no-cd]
shell shell="default" *args=default_args: 
    nix develop "{{FLAKE_PATH}}#{{shell}}" {{args}} -c "$SHELL"

[no-cd]
[private]
_shell shell="default" *args=default_args: 
    nix develop "{{FLAKE_PATH}}#{{shell}}" {{args}}

# run rsync to `target`
deploy target *args=default_args:
    @echo "I am {{canonicalize(source_directory())}}"
    rsync \
        -rlptD \
        --delete \
        -vzhP \
        --exclude=".direnv" \
        --exclude=".stfolder" \
        --exclude=".venv" \
        --exclude="*.sync-conflict-*" \
        --checksum --ignore-times \
        {{args}} \
        "{{canonicalize(source_directory())}}/" \
        {{target}}:~/infra

# run rsync on `target` and then switch over ssh
deploy-rebuild target *args=default_args: (deploy target)
    ssh {{target}} just --justfile '~/infra/Justfile' system switch --no-update-lock-file --show-trace {{ args }}

# deploy configuration on remote
remote-sw hostname target *args=default_args:
    @echo "DISABLE_BUILDERS: {{ DISABLE_BUILDERS }}"
    @echo "HOST: {{ HOST }}"
    {{ remote_rebuild_cmd }} switch --flake "{{FLAKE_PATH}}#{{hostname}}" --target-host "{{target}}" --show-trace {{args}} {{builders}} # --build-host "root@{{target}}.prod.tests.rubikoid.ru" 

deploy2 hostname *args=default_args:
    nix flake check -L "{{FLAKE_PATH}}" --show-trace
    deploy -s "{{FLAKE_PATH}}#{{hostname}}" {{args}}

deploy2s hostname *args=default_args:
    deploy -s "{{FLAKE_PATH}}#{{hostname}}" {{args}}

deploy2all *args=default_args:
    nix flake check -L "{{FLAKE_PATH}}" --show-trace
    deploy -s "{{FLAKE_PATH}}" {{args}}

deploy2all_s *args=default_args:
    deploy -s "{{FLAKE_PATH}}" {{args}}

# run not microvm i guess
vm-run hostname *args=default_args:
    nix run "{{FLAKE_PATH}}#nixosConfigurations.{{hostname}}.config.system.build.vm" {{args}}

# alias for `nix derivation show`` with fancy output
nds deriv:
    nix derivation show "{{deriv}}" | jq -C | less -R

# update one input
update-input input="base" *args=default_args:
    # nix flake lock --update-input "{{input}}" "{{FLAKE_PATH}}"
    nix flake update --flake "{{FLAKE_PATH}}" "{{input}}"

# simple clean
short-clean:
    sudo nix-collect-garbage -d

# big clean...
long-clean:
    sudo nix-collect-garbage -d
    sudo nix-env --delete-generations +1
    sudo nix-store --gc
    sudo rm /nix/var/nix/gcroots/auto/*
    sudo nix-collect-garbage -d

# magic to pull selectel api token
@get-selectel-token:
    curl -i -XPOST -s \
    -H 'Content-Type: application/json' \
    -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"{{SELECTEL_USER}}","domain":{"name":"{{SELECTEL_ACCOUNT_ID}}"},"password":"{{SELECTEL_PASSWORD}}"}}},"scope":{"project":{"name":"{{SELECTEL_PROJECT}}","domain":{"name":"{{SELECTEL_ACCOUNT_ID}}"}}}}}' \
    'https://cloud.api.selcloud.ru/identity/v3/auth/tokens' \
    | grep 'x-subject-token' | awk '{ print $2; }'


[private]
_build_octodns *args="":
    nix build "{{FLAKE_PATH}}#octodns" -v -o "./octodns.yaml"

[private]
_check_octodns *args="":
    octodns-sync --config-file ./octodns.yaml {{args}}
    
[private, confirm]
_exec_octodns *args="":
    octodns-sync --config-file ./octodns.yaml --doit {{args}}
    @echo "Done, cleaning..."
    rm octodns.yaml
    @echo "Done!"

[private]
_deploy-octodns *args="": _build_octodns (_check_octodns args) && (_exec_octodns args)
    @echo "...?"

# deploy octodns config to selectel with acient `just` magic
deploy-octodns *args="":
    just _shell octodns --command "bash" -c "\"octodns-versions --version && just _deploy-octodns {{args}} \""
