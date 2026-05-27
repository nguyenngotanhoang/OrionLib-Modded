# OrionLib Source Layout

`scr/Orion.lua` stays as the runtime bundle entrypoint for executors that load a single file. Shared source now lives in small modules so the project is easier to maintain:

- `scr/theme/palette.lua` contains built-in themes and style tokens.
- `scr/component/factory.lua` contains reusable UI instance helpers and color utilities.
- `scr/window/config.lua` normalizes public window config aliases.

Keep public APIs compatible with existing Orion scripts. New component work should go under `scr/component`, window behavior under `scr/window`, and theme or token changes under `scr/theme`.
