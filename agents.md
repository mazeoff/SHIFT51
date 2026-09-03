# AGENTS.md

## Current Project State

Last updated: **2026-09-03**

The repository now contains **Prototype 02**, a short networked shift built for Godot 4.x.

Implemented:

- a runnable Godot project with a programmatically constructed industrial corridor;
- ENet host/join flow on UDP port `5151`;
- support for up to four connections, with the current playtest designed for two players;
- first-person movement and mouse look with host-relayed transform synchronization;
- a shared server-authoritative physical door;
- player-specific perception: the host sees a door and receives destination A-17, while connected clients see a wall and receive destination B-04;
- server-authoritative door interaction with range validation;
- one shared verification charge that reveals the container's authoritative `BLUE / B-04` label to all players;
- an on-screen event log showing perception claims separately from authoritative facts;
- a stable direct reference to the runtime HUD, avoiding dependency on auto-generated node names;
- Russian and English localization for the lobby, HUD, work orders, scanner feedback, and event log;
- a lobby language selector, with Russian as the default and the choice persisted in `user://settings.cfg`;
- camera-ray interaction prompts instead of distance-only button handling;
- a blue artifact container that one player can carry at a time, synchronized by the host;
- two containment bays, `A-17 / AMBER` and `B-04 / BLUE`;
- conflicting player-specific delivery orders: the host is told to use A-17 while connected players are told to use B-04;
- one shared scanner charge that establishes the reliable physical label `BLUE / B-04`;
- authoritative task resolution when the carrier deposits the container;
- an incorrect placement consequence that changes facility lighting to emergency red;
- an extraction elevator that becomes available after the containment decision;
- localized success/breach end-of-shift summaries.

Not yet implemented:

- a round timer;
- multi-stage anomaly escalation beyond the first power-loss consequence;
- audio divergence;
- production-ready replication, prediction, or reconnect handling;
- polished environment art and sound.

Current controls:

- `WASD`: move;
- mouse: look;
- `E`: interact with the object under the crosshair;
- `V`: spend the shared scanner charge while near the artifact container;
- `Esc`: release the mouse.

Current test procedure:

1. In Godot, open **Debug > Customize Run Instances…**.
2. Enable multiple instances and set the count to `2`.
3. Run the project and move the overlapping windows apart.
4. Select **HOST SHIFT** in the first instance.
5. Select **JOIN SHIFT** in the second instance using `127.0.0.1` on the same machine.
6. Compare the conflicting destination orders and the appearance of Door 12.
7. Look at the blue container and press `E` to carry it.
8. Decide whether to trust A-17, B-04, or spend the one scanner charge with `V` near the container.
9. While carrying the container, aim at a containment bay and press `E`.
10. Observe the stable result for B-04 or emergency power loss for A-17.
11. Return to the elevator at the beginning of the corridor, aim at its panel, and press `E`.

Known limitation: the prototype deliberately uses lightweight client-owned movement synchronization. Important interactions and door state remain server-authoritative. Movement authority should be hardened after the core interaction is validated.

### Documentation Rule

Update this `Current Project State` section whenever implementation, scope, controls, architecture, or design decisions change. It must describe the code that actually exists, not only planned features.

## Project Overview

Working title: **SHIFT 51**

SHIFT 51 is a 1–4 player cooperative anomaly-management game set in a secret underground facility inspired by Area 51.

The core hook:

> All players occupy the same physical facility, but each player may perceive a different version of reality.

Players work a night shift handling anomalous artifacts, following containment protocols, moving objects, restoring facility systems, and completing assigned tasks while reality gradually becomes less reliable.

The game should create tension, confusion, cooperation, and memorable player-to-player conversations through mechanics rather than expensive graphics or scripted cinematics.

Engine: **Godot 4.x**

Primary platform for MVP: **PC / Steam-oriented desktop build**

Primary mode: **1–4 player co-op**

---

## High-Level Product Goals

The MVP must prove that the following idea is fun:

> Players receive conflicting but believable information and must communicate to determine what is real enough to act on.

The game should generate situations such as:

- one player sees a door while another sees a wall;
- one player receives a different containment instruction;
- one player hears a different radio message;
- one player sees an entity that others cannot see;
- two players disagree about the state of the same object;
- an artifact alters one fundamental gameplay rule;
- players must cooperate despite not being able to fully trust their own perception.

The MVP does not need a large amount of content.

The MVP does need a strong repeatable gameplay loop.

---

## MVP Scope

Build only what is required to validate the core experience.

Target MVP content:

- 1 underground facility floor;
- approximately 8–12 rooms;
- 1 central operations room;
- 1 containment/storage room;
- 1 laboratory;
- 1 generator/electrical room;
- 1 security/camera room;
- several connecting corridors;
- 1 extraction/end-of-shift elevator;
- 1–4 networked players;
- 3 basic work-task types;
- 5 anomaly/artifact types;
- 5 perception/reality distortion types;
- 1 simple power system;
- 1 simple facility state system;
- 1 end-of-shift condition;
- basic lobby / host / join flow;
- simple death or desynchronization state.

Do not expand scope until the core loop is enjoyable.

---

## Core Gameplay Loop

A typical session should follow this rhythm:

1. Players enter the facility.
2. Players receive work orders and containment protocols.
3. Players perform mundane facility tasks.
4. Players encounter anomalous artifacts.
5. Reality differences begin appearing between clients.
6. Players communicate and compare observations.
7. Facility systems degrade or anomalies interact.
8. Players decide which information to trust.
9. Players finish mandatory work or abandon optional objectives.
10. Players return to the elevator and attempt to end the shift.

Target MVP round duration:

**20–35 minutes**

The game should begin relatively calm and become increasingly unreliable.

The game must not start at maximum chaos.

---

## Design Pillars

### 1. Communication Is Gameplay

Players should frequently need to say things like:

- "What do you see?"
- "Does this door exist for you?"
- "Read your instruction."
- "Do not touch that."
- "My terminal says the opposite."
- "Can you hear that?"
- "Are you standing next to me?"
- "How many of us do you see?"

If players can solve most situations silently, redesign the mechanic.

---

### 2. Perception Is Not Shared Truth

The server maintains an authoritative simulation state.

However, individual clients may intentionally receive modified representations of that state.

Distinguish between:

- authoritative world state;
- player-specific perceived state;
- deliberately false information;
- cosmetic hallucination;
- mechanically meaningful reality divergence.

Never implement perception differences as random visual noise only.

Every major distortion should influence player decisions.

---

### 3. Failure Should Create Stories

Avoid instant fail states whenever possible.

Mistakes should escalate the situation instead of immediately ending the round.

Examples:

- wrong artifact placement causes a new anomaly;
- broken containment changes facility rules;
- power loss disables verification tools;
- incorrect protocol creates conflicting information;
- player death introduces a ghost/desynchronized state.

The most entertaining run may be a failed run.

---

### 4. Artifacts Change Rules

Artifacts should not primarily be stat modifiers.

Each artifact should alter one understandable rule of the game.

Examples:

- observation;
- time;
- identity;
- language;
- memory;
- object state;
- sound;
- navigation;
- gravity;
- causality.

Prefer a small number of deep artifacts over many shallow ones.

---

### 5. Ordinary Work Makes Anomalies Stronger

Players should have mundane responsibilities.

Examples:

- move a container;
- inspect an artifact;
- restore power;
- scan an object;
- verify a containment room;
- enter a classification code;
- retrieve a sample;
- deliver a package.

The contrast between routine work and reality failure is essential to the tone.

---

## Initial Task Types

### Artifact Transport

Players retrieve an artifact container and move it to a destination.

Possible complications:

- destination differs between players;
- container appears different to different players;
- container changes weight;
- some players cannot see the container;
- carrying it changes nearby reality.

### Facility Maintenance

Players restore a system such as electricity.

Possible interactions:

- fuse IDs differ between players;
- one player sees a dangerous panel state;
- power enables or disables reality verification equipment.

### Artifact Verification

Players run a simple test.

Example flow:

1. Place object in test chamber.
2. Activate scanner.
3. Observe result.
4. Compare result with containment manual.
5. classify object.
6. transport object.

Different players may receive different test results.

---

## Initial Artifact Concepts

### Observer

Rule:

The artifact behaves differently depending on whether it is being observed.

Possible MVP implementation:

- exists only for selected players;
- changes position when nobody has line of sight;
- requires players to coordinate gaze direction.

### Echo

Rule:

Actions repeat after a delay.

Possible repeated actions:

- doors opening;
- object drops;
- switches changing state;
- sounds;
- footsteps.

Avoid fully replaying player physics for MVP.

Use event replay instead.

### Redacted

Rule:

Information disappears.

Can affect:

- signs;
- labels;
- player names;
- terminal text;
- item descriptions;
- room numbers.

Use progressively increasing severity.

### Employee

Rule:

Creates identity uncertainty.

Possible MVP implementation:

- spawn a duplicate player-shaped NPC;
- use copied player appearance;
- duplicate performs simple believable actions;
- different clients may see a different duplicated player.

Do not build advanced human AI for MVP.

Simple scripted behavior is enough.

### Mirror

Rule:

Shows information displaced in time.

MVP version:

- selected player receives a preview of an event several seconds before it occurs;
- some previewed events may be preventable;
- use predefined event types rather than full future simulation.

---

## Initial Reality Distortion Types

Implement distortions as modular systems.

### Visual Divergence

Examples:

- object visible only to selected players;
- door represented as wall;
- room sign text differs;
- lighting state differs;
- NPC appearance differs.

### Audio Divergence

Examples:

- different radio instructions;
- footsteps heard by only one player;
- artifact sounds;
- false alarm.

### Information Divergence

Examples:

- terminal text differs;
- protocol text differs;
- task destination differs;
- item labels differ.

### Interaction Divergence

Examples:

- switch appears usable only to some players;
- selected player can pass through a perceived obstruction;
- object interaction target differs.

Use carefully. Server authority must remain understandable.

### Identity Divergence

Examples:

- player name hidden;
- duplicate player;
- incorrect player label;
- incorrect employee count.

---

## Reality Integrity

Do not implement a conventional sanity meter for the player to watch.

Instead, use an internal per-player value such as:

`reality_integrity`

This value may influence:

- probability of perception divergence;
- intensity of anomalies;
- reliability of terminals;
- susceptibility to artifact effects.

Players should normally not see their own true value.

Other players may be able to inspect it using facility equipment.

This enables situations where the inspected player sees a different result from the observer.

For MVP, keep the system deterministic enough to debug.

---

## Multiplayer Architecture

Use Godot 4 multiplayer APIs.

Prefer an authoritative host/server architecture.

The authoritative host owns:

- actual object positions;
- artifact state;
- facility power state;
- task progression;
- player health/alive state;
- round progression;
- authoritative interactable state.

Clients own:

- local camera;
- local UI;
- local perception presentation;
- hallucination rendering;
- player-specific text/audio substitutions.

Important architectural principle:

**Do not duplicate the entire world scene per reality.**

Maintain one authoritative world state and add a player-specific perception layer.

Recommended conceptual pipeline:

`Authoritative State -> Perception Resolver -> Player-Specific Presentation`

Example:

```text
Server:
Door_12 = CLOSED

Player A perception:
Door_12 = CLOSED

Player B perception:
Door_12 = OPEN_VISUAL

Player C perception:
Door_12 = WALL_VISUAL
```

The underlying server collision state should remain explicit.

When a distortion affects actual gameplay physics, represent it as an intentional server-side anomaly rule rather than an accidental client mismatch.

---

## Networking Rules

Do not trust clients for important gameplay state.

Validate interactions on the authority.

Examples:

- pickup;
- drop;
- door interaction;
- artifact interaction;
- task completion;
- player death;
- containment success.

Avoid networking every cosmetic hallucination.

Player-specific cosmetic effects should usually be generated locally using a replicated seed/event.

Prefer sending:

- anomaly event ID;
- target player IDs;
- seed;
- start timestamp;
- duration;
- parameters.

Instead of constantly replicating every visual property.

---

## Proposed Godot Project Structure

```text
res://
  autoload/
    game.gd
    network.gd
    event_bus.gd
    session.gd

  scenes/
    bootstrap/
    lobby/
    facility/
    player/
    artifacts/
    interactables/
    tasks/
    ui/

  scripts/
    core/
    multiplayer/
    perception/
    artifacts/
    tasks/
    facility/
    interaction/
    utils/

  resources/
    artifacts/
    anomalies/
    tasks/
    protocols/

  audio/
  materials/
  models/
  textures/
```

Keep content data-driven where practical.

Use custom `Resource` classes for artifact definitions, task definitions, and anomaly configuration.

---

## Suggested Core Systems

### Interaction System

Use a reusable interaction interface/component.

Examples:

- doors;
- buttons;
- terminals;
- artifact containers;
- scanners;
- power panels.

Avoid placing bespoke interaction code directly in the player controller.

### Task System

Tasks should be data-driven.

Each task needs:

- ID;
- title;
- authoritative target;
- completion condition;
- optional player-specific display overrides.

### Anomaly Manager

Responsible for:

- choosing anomaly events;
- assigning affected players;
- applying duration;
- resolving conflicts;
- cleaning up effects.

Do not place global anomaly logic inside artifact scripts.

### Perception Resolver

Central system responsible for answering questions such as:

- What should this player see?
- What text should this player read?
- What audio should this player hear?
- What identity should this player perceive?

Avoid scattering `if hallucinating` logic throughout unrelated nodes.

### Facility State

Track:

- power;
- alarm state;
- sector access;
- containment status;
- shift phase.

---

## Code Style

Language: **GDScript unless there is a compelling reason otherwise.**

Use typed GDScript wherever practical.

Prefer:

```gdscript
var health: float = 100.0
var target_player: Node3D
```

over untyped variables.

Prefer small scripts with clear responsibilities.

Avoid giant manager scripts.

Use signals for decoupled event communication.

Do not create unnecessary abstractions before they are needed.

Names:

- files: `snake_case.gd`
- functions: `snake_case`
- variables: `snake_case`
- classes: `PascalCase`
- constants: `UPPER_SNAKE_CASE`
- signals: descriptive past/present events such as `artifact_activated`

Use comments to explain intent, constraints, or non-obvious networking behavior.

Do not comment trivial syntax.

---

## Visual Direction

Target style:

**Stylized low-poly / late-1990s to early-2000s industrial sci-fi**

References should evoke:

- secret military research facility;
- utilitarian underground architecture;
- analog equipment mixed with primitive digital terminals;
- concrete;
- painted steel;
- fluorescent lighting;
- warning labels;
- thick cables;
- CRT displays;
- industrial doors;
- laboratory glass;
- storage racks;
- archival equipment.

Do not aim for photorealism.

Do not aim for highly detailed PBR environments.

The visual style must remain achievable for a small team or solo developer.

---

## Graphics Rules

Geometry should be:

- simple;
- chunky;
- readable;
- modular;
- reusable.

Prefer large recognizable silhouettes.

Textures should be:

- low to medium resolution;
- reusable;
- slightly dirty/worn;
- restrained rather than noisy.

Suggested target:

- 256–1024 px textures depending on asset importance;
- trim sheets;
- decals;
- tiled concrete/metal materials;
- atlas textures where useful.

Use lighting and composition to carry atmosphere instead of geometry density.

---

## Why This Style Fits the Game

Low-poly industrial visuals make perception anomalies easier to read.

A door changing into a wall should be immediately understandable.

A duplicated employee should be recognizable by silhouette.

A changed sign should attract attention.

An impossible corridor should not be lost inside visual clutter.

The slightly retro appearance also makes visual glitches, low-resolution cameras, CRT terminals, and corrupted UI feel intentional rather than cheap.

---

## Reality Distortion Visual Language

Reality distortions should not all use generic glitch effects.

Different anomaly classes should have distinct visual behaviors.

Examples:

### Information distortion

- changed text;
- missing labels;
- redaction blocks;
- incorrect symbols.

### Spatial distortion

- repeated corridor modules;
- impossible doorway placement;
- shifted room geometry;
- false walls.

### Identity distortion

- duplicated character;
- incorrect badge;
- hidden name;
- swapped uniform detail.

### Temporal distortion

- repeated object action;
- delayed sound;
- brief future state;
- duplicated movement trace.

Use screen-space glitch effects sparingly.

If every anomaly causes VHS distortion, the mechanic becomes predictable and visually noisy.

---

## UI Direction

UI should resemble internal facility software.

Use:

- monochrome or limited-color terminal interfaces;
- employee ID screens;
- diagnostic displays;
- camera feeds;
- containment forms;
- work-order terminals.

Avoid modern glossy sci-fi HUDs.

Do not put excessive information permanently on screen.

Whenever possible, information should exist physically in the world:

- wall terminals;
- handheld scanner;
- signs;
- monitors;
- printed protocols.

This makes altered information more meaningful.

---

## Audio Direction

Audio is a major gameplay system.

Prioritize:

- positional footsteps;
- fluorescent hum;
- ventilation;
- electrical relays;
- distant machinery;
- PA announcements;
- radio messages;
- containment alarms;
- artifact-specific sounds.

Player-specific audio hallucinations are a core feature.

Do not rely on music to create most tension.

Silence and facility ambience should carry the atmosphere.

---

## Horror Direction

The game should be unsettling rather than constantly aggressive.

Avoid dependence on:

- jumpscares;
- constant monster pursuit;
- gore;
- loud sting sounds;
- scripted chase sequences.

Preferred tension source:

> uncertainty about whether the player's perception is correct.

Humor should naturally emerge from co-op communication and failure.

Do not turn the tone into parody.

---

## Player Controller

MVP player abilities:

- walk;
- sprint;
- crouch if needed;
- interact;
- carry one object;
- drop/throw object;
- use handheld tool;
- voice/chat integration later if required.

Do not implement:

- combat;
- advanced parkour;
- skill trees;
- complex inventory;
- crafting.

Keep player verbs limited.

---

## Solo Play

The game should technically support one player.

However, co-op is the primary design target.

For solo MVP testing, information comparison can be supported by:

- scanners;
- cameras;
- recorded system logs;
- verification terminals.

Do not build AI companions for MVP.

---

## Death / Desynchronization

Avoid immediately removing dead players from the game.

Potential MVP approach:

After death, the player enters a **desynchronized state**.

They may:

- move through selected areas;
- see additional anomaly information;
- interact with a very limited set of anomaly objects;
- observe living players.

Living players may:

- not hear them;
- occasionally see them;
- see their body elsewhere.

Keep this system simple during initial implementation.

It is optional for the first playable prototype.

---

## Procedural Content

Do not build procedural level generation for MVP.

Use a handcrafted modular facility.

Randomize:

- task selection;
- artifact selection;
- affected players;
- anomaly timing;
- protocol changes;
- some item locations.

A strong fixed level with systemic variation is preferable to a weak procedural map.

---

## Save / Progression

Do not prioritize persistent progression during the core prototype.

For later versions, possible progression:

- security clearance;
- deeper facility levels;
- artifact archive;
- employee records;
- new equipment;
- new protocols.

MVP should focus on session gameplay.

---

## Performance Targets

Aim for stable gameplay on mid-range PCs.

Target:

- 60 FPS under normal conditions;
- up to 4 players;
- modest GPU requirements;
- limited dynamic shadow cost;
- sensible physics object counts.

Do not use expensive effects to hide weak art direction.

---

## Development Priorities

Implement systems in roughly this order:

1. basic first-person controller;
2. reusable interaction system;
3. one small facility test map;
4. multiplayer host/join;
5. replicated player movement;
6. replicated interactable objects;
7. simple task system;
8. perception resolver;
9. first visual divergence;
10. first information divergence;
11. one artifact;
12. round flow;
13. additional artifacts;
14. sound divergence;
15. polish.

The first meaningful prototype should test this exact scenario:

> Two players stand in the same corridor. One sees a door and a task instructing them to enter it. The other sees a solid wall and receives a warning not to continue. Both must decide what to do.

If this situation is not interesting in playtesting, do not add more content. Revisit the core interaction.

---

## Prototype Milestone 1

Goal:

Prove that player-specific realities work technically.

Requirements:

- 2 networked players;
- one corridor;
- one door;
- server-authoritative door state;
- Player A sees door;
- Player B sees wall;
- each player receives different terminal text;
- both players can communicate externally during testing;
- logging clearly reports authoritative state and perceived state.

No polished art required.

---

## Prototype Milestone 2

Goal:

Prove that conflicting information creates gameplay.

Add:

- artifact container;
- transport task;
- destination room;
- player-specific protocol text;
- scanner;
- simple success/failure consequence.

---

## Prototype Milestone 3

Goal:

Create a complete short shift.

Add:

- 3 tasks;
- 3 artifacts;
- power failure;
- escalating anomaly manager;
- extraction elevator;
- win/fail summary.

Target session:

10–15 minutes.

---

## Testing Rules

For every anomaly, test:

1. Is it understandable after discussion?
2. Does it create a decision?
3. Does it encourage communication?
4. Can players discover a pattern?
5. Does it create funny, tense, or memorable outcomes?
6. Can it combine with another anomaly?
7. Is it still interesting after seeing it several times?

If an anomaly only looks cool, it is not enough.

---

## Debugging Requirements

Reality divergence is inherently difficult to debug.

Build debugging tools early.

Required debug features:

- display player ID;
- display authoritative object state;
- display perceived state;
- force anomaly on selected player;
- force artifact activation;
- change reality integrity;
- disable random events;
- deterministic session seed;
- network event logging.

Add a developer-only debug overlay.

Do not depend on print statements alone.

---

## AI / Codex Instructions

When implementing features:

1. Read this file first.
2. Preserve the authoritative-state / perceived-state separation.
3. Do not expand MVP scope without explicit instruction.
4. Prefer reusable systemic mechanics over scripted one-off events.
5. Prefer simple implementations that can be tested quickly.
6. Avoid introducing third-party dependencies unless necessary.
7. Keep Godot scenes and scripts modular.
8. Never silently change multiplayer authority rules.
9. When implementing a new anomaly, describe:
   - authoritative effect;
   - player-specific perception effect;
   - networking behavior;
   - cleanup behavior.
10. Before large refactors, explain what architectural problem the refactor solves.

When uncertain, prioritize:

**playability > architecture purity > visual polish**

but do not create architecture that makes player-specific reality impossible to maintain.

---

## Non-Goals for MVP

Do not build these unless explicitly requested:

- open world;
- large procedural facility;
- advanced enemy AI;
- combat system;
- weapons;
- crafting;
- large inventory system;
- character classes;
- skill trees;
- cosmetics;
- matchmaking backend;
- dedicated servers;
- advanced account system;
- large narrative campaign;
- fully voiced story;
- photorealistic graphics;
- complex destruction;
- dozens of artifacts.

---

## Final Product Test

At any point, ask:

> Does this feature make players question what is real and require them to communicate?

If the answer is no, it should probably not be a priority for SHIFT 51.
