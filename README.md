# SHIFT 51 — Prototype 01

A minimal Godot 4 multiplayer prototype for testing conflicting player perceptions.

The interface supports Russian and English. Russian is selected by default; the lobby language selector saves the choice between launches.

## Run the playtest

1. Import `project.godot` in Godot 4.x.
2. In the editor, open **Debug > Customize Run Instances…**.
3. Enable **Enable Multiple Instances** and set the instance count to `2`.
4. Close the dialog and run the project with `F6`/`F5`.
5. Click **HOST SHIFT** in one game window.
6. Click **JOIN SHIFT** in the other window. Use `127.0.0.1` for a same-machine test.
7. Compare what each player sees and what each work order says.

Both windows are debug instances connected to the same editor debugger. They may initially overlap; move one window aside before selecting Host/Join.

If **Customize Run Instances…** is unavailable in an older Godot 4 release, run the project once from the editor and start a second copy from a terminal:

```bash
godot --path "/home/mazeoff/Рабочий стол/dev/godot/SHIFT 51" --editor-pid 0
```

Depending on the installation, the executable may be named `godot4` rather than `godot`.

The prototype listens on UDP port `5151`. Remote players need the host's reachable IP address and firewall/NAT access to that port.

## Controls

- `WASD`: movement
- Mouse: camera
- `E`: operate Door 12 when nearby
- `V`: spend the shared verification charge near Door 12
- `Esc`: release mouse cursor

## Prototype question

Does conflicting but believable information produce an interesting conversation when the team has one costly, reliable way to establish a shared fact?

The on-screen log deliberately distinguishes local perception from authoritative state for playtest debugging.
