# About

Base structure for my games, using **Heaps** framework (https://heaps.io) and **Haxe** language (https://haxe.org).

# Usage

## Fork

Just fork it, feel free to adapt to your own usage (see LICENSE)

## Alternative way to "fork"

This method is mostly for my own usage, as GitHub doesn't allow me to fork my own projects.

- Make a **new repo** on GitHub (**WARNING**: do not add any license or don't commit anything in it for now)
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
- **Camera**: a basic camera which can optionaly track an Entity (say, the player)
- **Fx**: a simple particle system
- **Lang**: a neat way to automatically extract your texts directly from your code to generate PO files compatible with the popular GetText translation ecosystem (https://en.wikipedia.org/wiki/Gettext). To use it, just use calls like: `Lang._("Some translatable sentence");` in your code somewhere. You can then run `haxe langParser.hxml` from the command line to update your POT file (this script will extract all `Lang._("something")` calls). The "classic" way to do things is to write "dev English" sentences in your code, then use this "dev English" to kind-of translate to "proper English" (which will be used in the release version of your game), or translated to "proper whatever-language" you might want.
- **Const**: contains a set of constant values I use to tweak my game, like the standard FPS, your starting health points or stuff like that.
- **Assets**: a single class to access assets like tilesets or sounds. All your assets (art, sound, other data files) that are meant to be loaded/used by the game should be put in the **res/** folder. You can access them in your code using the `hxd.Res.myAsset` API.

# A quick guide to installing Haxe

## Getting all the necessary files

 - **Haxe compiler**: https://haxe.org/download/list/ (latest stable or RC, unzip the files in a folder somewhere on your harddrive, like `c:\haxeTools\haxe`)
 - **NekoVM**: https://nekovm.org/download/ (unzip all files in another folder, ie. `c:\haxeTools\neko`)
 - **HashLink**: https://hashlink.haxe.org/#download (unzip the files in a separate folder, somewhere else, like `c:\haxeTools\hl`)
 - Add *Haxe* folder (eg. `c:\haxeTools\haxe`) to the **PATH** environment variable
 - Add *Neko* folder (eg. `c:\haxeTools\neko`) to the **PATH** environment variable
 - Add *HashLink* folder (eg. `c:\haxeTools\hl`) to the **PATH** environment variable
 
## Does it work?
Open a command line and type:
 - `haxe`: you should see the Haxe command help
 - `neko`: you should see the Neko help
 - `hl`: you should see the Hashlink help

## Installing important haxe libs

- Open a command line
- Run the following commands:
    - **`haxelib setup`** (when prompted, point to a /lib folder in your Haxe folder, ie. `c:\haxeTools\haxe\lib`)
    - `haxelib install hldx`
    - `haxelib install hlsdl`
    - `haxelib install format`
    - `haxelib install castle`
    - `haxelib install heaps`
    - `haxelib install deepnightLibs`
    - `haxelib install redistHelper`

- Optionaly, you may need the following:
    - For OGMO3 level editor: `haxelib install heapsOgmo`
    - For Tiled level editor: `haxelib install heapsTiled`
    
## Does it work?

 - Open a command line
 - run `haxelib list`
 - you should get a listing of all the libs previously installed.
 - well done!
