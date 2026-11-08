# DTlib v1.4.0-beta.5 — API69

## Changes

- Apply Apocalypse Industrial tokens to native notifications, 300px banners, textUI, menu/input chrome and progress.
- Redesign waypoint DUI as a diamond marker with destination and distance; retain custom colors, icons, images and world projection.
- Bundle Space Grotesk and waypoint Font Awesome locally with licenses.
- Default fresh configs to native notifications; retain external providers and beta 4 optimizations.

## Install

Download DTlib.zip. Back up DTlib, replace it with the fresh folder and merge custom settings. Set DTConfig.Adapters.notify = 'native' for API69 notifications. Merge waypoint color #d6bb58, dangerColor #ce6257 and NAVIGATION subtitle if desired. Restart DTlib and consumers or perform a scheduled server restart.

External provider UIs and the separate dialogue UI are not reskinned. DT_interact v1.0.0-beta.16 is distributed separately; its engine/source/ZIP is not included in this repository or asset.

## Validation

21 DTlib Python/Node suites and 2 React tests pass, plus TypeScript/Vite build. The separate companion passed 23 runtime and 9 React tests. Browser checks covered the compiled components at 1366x768, 1920x1080 and 2560x1440. No live FiveM resmon benchmark is claimed.
