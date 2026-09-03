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

Each new shift selects one of three data-driven artifact orders: `COBALT-7`, `AMBER-3`, or `[REDACTED] Archive`. Container color, verified scanner classification, and the authoritative destination change with the selected order. The server randomly decides whether the host or the connected-player role receives the correct instruction; the other side receives a believable conflicting destination. Restarting never repeats the immediately previous task when multiple definitions are available.

## Observer artifact

The pale spherical artifact changes position after 2.5 seconds outside every player's forward view. Movement is selected by the host from four predefined points and replicated to all players. Connected non-host players also see a purple-tinted false copy that does not exist in the authoritative simulation.

The gaze test uses player direction, distance, and an authoritative physics ray, so facility geometry can block observation. Each movement briefly shrinks and restores the object instead of visibly sliding it between points.

After five unseen movements, Observer reaches critical activity: normal lighting fails and the shift can no longer receive a fully stable result. The shift also has a synchronized five-minute limit. When a run ends, either player can request **Start New Shift** to reset the shared round without restarting the application.

The project has been import- and startup-checked with Godot `4.7.2-stable`. Multiplayer behavior should still be verified with two visible debug instances after gameplay changes.

## Visual prototype

The start menu is centered and scales from viewport anchors. Its current visual language uses dark oxidized metal, restrained green-gray accents, and internal-facility typography. The corridor combines procedural structural ribs, light panels, wall rails, floor joints, fog, and amber/blue containment navigation with a project-specific wall texture and a curated set of low-poly CC0 environment props.

See `ASSET_SOURCES.md` for provenance, licenses, and optimization notes.
