# WTF is it

Configuration of most of my infa.

Now it contains only nix things...

## Todo

- [ ] Refactor secrets pseudo-module and make it normal module:
  - [ ] Add proper schema for every secret param
  - [ ] Refactor some secret values and places
  - [ ] Make it nix module instead of ugly attrset
- [ ] Refactor flake.nix
- [ ] Make WSL builder less ugly (and less copypasted) and more nix-way
- [ ] Beatify and push all the local-ugly-undone modules:
  - [ ] wireguard-client
  - [ ] budget-git
  - [ ] vaultwarden
  - [ ] monitoring:
    - [x] grafana-agent-ng (successor to both grafana-agent-simple and grafana-agent)
    - [ ] ~~grafana-agent-simple~~
    - [ ] ~~grafana-agent~~
    - [ ] grafana
  - [ ] ss (syncthing)

## inspiration

- <https://github.com/balsoft/nixos-config>

- <https://github.com/0xb1b1/nixos-config>

- <https://github.com/kanashimia/nixos-config>
