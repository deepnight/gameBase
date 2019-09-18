# About

Base structure for my games, using **Heaps** framework (https://heaps.io) and **Haxe** language (https://haxe.org).

# Usage

## Fork

Just fork it, feel free to adapt to your own usage (see LICENSE)

## Alternative way to "fork"

This method is mostly for my own usage, as GitHub doesn't allow me to fork my own projects.

- Make a **new repo** on GitHub
- **Clone it** somewhere
- on a command line:
  - `git remote add gameBase https://github.com/deepnight/gameBase.git`
  - `git pull gameBase master`
  - `git push origin master`

# Quick overview

The game uses the very simple "engine" described here: https://deepnight.net/tutorials/a-simple-platformer-engine-part-1-basics/
Even if it's simple, it's actually the exact same engine I used for making Dead Cells (https://dead-cells.com).

Everything starts in **Boot.hx**, in the method `main()`. From here, I instanciate a **Main**, which creates a **Game**.

The game has various elements:
- **Entities**: the base class for everything that moves in the game (player, enemies, bullets, items etc.). Everything except particles, see below.
- **Level**: your world, level, room or whatever is your environment. Some games might even have none of these.
- **Camera**: a basic camera which can optionaly tracks an Entity (say, the player)
- **Fx**: a simple particle system
- **Lang**: a neat way to automatically extract your texts directly from your code to generate PO files compatible with the popular GetText translation ecosystem (https://en.wikipedia.org/wiki/Gettext). The standard way to do things is to write "dev English" sentences in your code, then use this "dev English" to kind-of translate to "proper English" (which will be used in the release version of your game), or translated to "proper whatever-language" you might want.
- **Const**: contains a set of constant values I use to tweak my game, like the standard FPS, your starting health points or stuff like that.

All your assets (art, sound, other data files) that are meant to be loaded/used by the game should be put in the **res/** folder.