# Asset Sources

## Project-created assets

### `assets/textures/facility_wall_albedo.png`

- Purpose: tileable wall albedo for the SHIFT 51 facility.
- Created specifically for this project with OpenAI's built-in image generation tool on 2026-09-03.
- Final generation prompt: seamless late-1990s industrial painted concrete and steel composite wall; stylized low-poly game art; dark desaturated blue-gray and oxidized green-gray palette; broad panels, subtle scuffs and grime; flat material lighting; no text, logos, objects, borders, baked highlights, or perspective.
- Import settings: mipmaps enabled and anisotropic filtering selected by the consuming 3D material.

## Third-party CC0 assets

### Quaternius — Sci-Fi Essentials Kit (Standard)

- Source: https://quaternius.com/packs/scifiessentialskit.html
- Repository mirror used for individual files: https://github.com/agentkaerf/FreeModels
- License: CC0 1.0 Universal / public domain dedication.
- Local license copy: `assets/third_party/quaternius_sci_fi_essentials/LICENSE.txt`.
- Imported models: `Prop_Crate`, `Prop_Locker`, `Prop_Shelves_ThinTall`, `Prop_Desk_Medium`, and `Prop_Chair`.
- Optimization: external texture references were removed from the glTF material definitions and replaced with a small neutral metallic material definition. Mesh geometry and binary buffers are otherwise retained.

Although attribution is not required by CC0, source records are retained for provenance and future asset audits.
