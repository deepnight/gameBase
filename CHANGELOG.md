# GameBase changelog

## 2.0

- General:
	- Full **LDtk** integration (https://ldtk.io)
	- The official gameBase version is now the former "advanced" branch version. Merged `advancedBranch` with `master`. A "minimalistic" version will be added to a branch later.
	- Fixed various FPS values issues
	- Added various debug commands to console. Open it up with `²` key, and type: `/help`
	- Better "active" level management, through `startLevel()` method
	- Cleaned up Main class
	- Replaced pixel perfect filters with a more optimized one (now using `Nothing` filter)
	- Added LDtk file hot-reloading
	- Added many comments everywhere
	- Added this CHANGELOG ;)

- Entity:
	- All entities now have a proper width/height and a pivotX/Y factor
	- Separated bump X/Y frictions
	- Fixed X/Y squash frictions (forgot to use tmod)
	- Added a `sightCheck` methods using Bresenham algorithm
	- Added `isAlive()` (ie. quick check to both `destroyed` flag and `life>0` check)

- Camera:
	- Cleanup & rework
	- Added zoom support
	- Camera slows down when reaching levels bounds
	- Camera no longer clamps to level bounds by default
	- Added isOnScreen(x,y)

- UI:
	- Added basic notifications to HUD
	- Added debug text field to HUD