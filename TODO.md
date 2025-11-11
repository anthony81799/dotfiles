# Roadmap

- ~~Snapper snapshots do not work yet~~ (disabled for now)
- ~~install, npm and node before doing Rust install to allow for Helix install~~
- ~~investigate yazelix as terminal based development environment~~ (created install script. Haven't commited to using it.)
- ~~Nix does not currently work with Selinux enabled~~ (Swithced to lix instead. Added to yazelix install script.)
- ~~docker is installed but services fail to start~~
- ~~find a better to to exit scripts on failure ```exit 1``` causes the entire install process to stop~~ (changed to fail_message with ```exit 0```)
- move GUI editor installations to a separate script
- give the user option to install the different Go tools
- general speed up
