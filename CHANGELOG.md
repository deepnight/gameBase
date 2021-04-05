# GameBase changelog

## 2.0

- General:
	- Moved all game related classes to the `gm/` package
	- Moved all assets related classes to the `assets/` package
	- **Debug Drone**: press `CTRL-SHIFT-D` to add a debug Drone. Use arrows to fly it around and quickly explore your level.
	- Full **LDtk** integration (https://ldtk.io), with hot-reloading support.
	- The official gameBase version is now the former "advanced" branch version. Merged `advancedBranch` with `master`. A "minimalistic" version might be added to a separate branch in the future.
	- Fixed various FPS values issues
	- Added various debug commands to console. Open it up with `²` key, and type: `/help`
	- Better "active" level management, through `startLevel()` method
	- Cleaned up Main class
	- Replaced pixel perfect filters with a more optimized one (now using `Nothing` filter)
	- Added many comments and docs everywhere
	- Added this CHANGELOG ;)

- Entity:
	- All entities now have a proper width/height and a pivotX/Y factor
	- Separated bump X/Y frictions
	- Fixed X/Y squash frictions (forgot to use tmod)
	- Added a `sightCheck` methods using Bresenham algorithm
	- Added `isAlive()` (ie. quick check to both `destroyed` flag and `life>0` check)
	- Added `.exists()` to Game and Main

- Camera:
	- Cleanup & rework
	- Added zoom support
	- Camera slows down when reaching levels bounds
	- Camera no longer clamps to level bounds by default
	- Added isOnScreen(x,y)

- UI:
	- Added basic notifications to HUD
	- Added debug text field to HUD