# Proton VPN

Enable the optional `protonVpn` icon in Nexus → Panels → Taskbar → Status icons → Add entry → Proton VPN. It is absent from the active icon list by default.

With status popouts enabled, hover the icon to show the attached panel. Click the icon or press `SUPER+SHIFT+ALT+V` to pin the panel for keyboard input. When the icon is disabled or absent, the shortcut opens the panel from the middle of the taskbar, using the same fallback as the speaker panel.

The icon reflects NetworkManager's activated Proton tunnel; the IPv6 leak guard and unrelated VPN connections do not count as connected. The panel exposes connection details, fastest/random/country connections, Kill Switch and NetShield. Plan restrictions and failed requests appear in the panel. Sign-in opens the configured terminal for Proton's own password and 2FA prompts.

The official `proton-vpn-cli` package and NetworkManager are required. CLI requests run sequentially; actions never run automatically. Polling stops when the icon is disabled and all VPN panels are closed.

Settings live under `protonVpn` in `caelestia/config/integration.json`:

- `cliPath`, `nmcliPath`: executable paths.
- `watchIntervalSeconds`: tunnel poll interval, default 4.
- `refreshIntervalSeconds`: closed-panel detail interval, default 30.
- `panelRefreshIntervalSeconds`: open-panel detail interval, default 5.
- `signInTerminal`: terminal command arguments, default `["/usr/bin/kitty"]`; the terminal must wait for the command to finish and exit afterwards.

Waybar and Noctalia retain `SUPER+SHIFT+ALT+V` → `~/bin/launch-vpn`. The launcher blocks the Proton desktop app in Caelestia; the local Proton desktop entry also uses this launcher. `~/bin/toggle-shell-mode` stops `protonvpn-app` before starting Caelestia and verifies it is stopped. These guards leave Proton's CLI, daemon and tunnel intact.

Preview the guard and switch behavior without launching or stopping anything:

```bash
/home/dxle/bin/launch-vpn --dry-run
/home/dxle/bin/toggle-shell-mode --dry-run --caelestia
```

Behavioral reference: [OmaProton VPN](https://github.com/grichard99/omaproton-vpn). The panel uses Caelestia's controls, theme tokens and existing attached popout container.
