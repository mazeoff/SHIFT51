# SHIFT 51 — Prototype 03

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
- `E`: interact with the object under the crosshair
- `V`: spend the shared scanner charge while close to the container
- `Esc`: release mouse cursor

## Prototype question

Does conflicting but believable information produce an interesting conversation when the team has one costly, reliable way to establish a shared fact?

The playable loop is now:

1. Compare the conflicting containment orders.
2. Pick up the blue container by aiming at it and pressing `E`.
3. Optionally spend the single shared scanner charge with `V` while close to the container.
4. Carry it to either `A-17 / AMBER` or `B-04 / BLUE`.
5. Aim at the bay and press `E` to commit the decision.
6. Return to the elevator panel at the start of the corridor and press `E` to end the shift.

Choosing the wrong bay does not immediately end the run. It causes an emergency power failure and produces a breach result after extraction. The on-screen log distinguishes local information from host-authoritative events for debugging.

## Observer artifact

The pale spherical artifact changes position after 2.5 seconds outside every player's forward view. Movement is selected by the host from four predefined points and replicated to all players. Connected non-host players also see a purple-tinted false copy that does not exist in the authoritative simulation.

The current gaze test uses player direction and distance rather than exact geometry occlusion. This is intentional for Prototype 03 and is documented in `agents.md`.
