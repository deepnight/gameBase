# GameBase changelog

## 2.0

- General:
	- **The official gameBase version is now the former "advanced" branch version. A "minimalistic" version might be added to a separate branch in the future.**
	- **Debug Drone**: press `CTRL-SHIFT-D` to spawn a debug Drone. Use arrows to fly around and quickly explore your current level. You can also type `/drone` in console.
	- Full **LDtk** integration (https://ldtk.io), with hot-reloading support.
	- Added many comments everywhere.
	- Moved all source code to various `src/` subfolders
	- Moved all game related classes to the `gm` package
	- Moved all assets related classes to the `assets` package
	- Added `/fps` command to console to display FPS chart over time.
	- Fixed various FPS values issues
	- Added various debug commands to console. Open it up with `²` key, and type: `/help`
	- Better "active" level management, through `startLevel()` method
	- Cleaned up Main class
	- Renamed Main class to App
	- Renamed Data class to CastleDb
	- Replaced pixel perfect filters with a more optimized one (now using `Nothing` filter)
	- Added many comments and docs everywhere
	- Added XML doc generation for future proper doc
	- Removed SWF target (see you space cowboy)
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