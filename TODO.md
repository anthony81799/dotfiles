# Roadmap

- ~~Snapper snapshots do not work yet~~ (disabled for now)
- ~~install, npm and node before doing Rust install to allow for Helix install~~
- ~~investigate yazelix as terminal based development environment~~ (created install script. Haven't commited to using it.)
- ~~Nix does not currently work with Selinux enabled~~ (swithced to lix instead. Added to yazelix install script.)
- ~~docker is installed but services fail to start~~
- ~~find a better to to exit scripts on failure ```exit 1``` causes the entire install process to stop~~ (switched to fail_message with ```exit 0```)
- ~~move editor installations to a separate scripts~~ (created install/desktop/editor.sh and install/terminal/editor.sh)
- ~~give the user option to install the different Go tools~~
- ~~remove flatpaks and replace with native distro packages where available~~ (installed discord left LocalSend as flatpak)
- ~~split terminal emulator installations into separate script~~ (added install/desktop/terminal-emulator.sh)
- general speed up
  - ~~script executions~~
  - ~~rust crate installation~~ (added cargo-binstall to install binaries directly)
  - ~~package installations~~
