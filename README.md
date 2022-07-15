# About

**A lightweight and simple base structure for games, using *[Heaps](https://heaps.io)* framework  and *[Haxe](https://haxe.org)* language.**

Latest release notes: [View changelog](CHANGELOG.md).

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/deepnight/gameBase/Test%20JS%20build)](https://github.com/deepnight/gameBase/actions)


# Install

## Legacy or master?

Two separate branches exist for GameBase:

 - `master`: latest GameBase version, actively maintained.
 - `legacy`: the previous Gamebase version. This one is much more minimalistic but it could be useful if you were looking for a very basic framework for Heaps+Haxe.

The following document will only refer to the `master` branch.

## Getting master

 1. Install **Haxe** and **Hashlink**: [Step-by-step tutorial](https://deepnight.net/tutorial/a-quick-guide-to-installing-haxe/)
 2. Install required libs by running the following command **in the root of the repo**: `haxe setup.hxml`

# Compile

From the command line, run either:

 - For **DirectX**: `haxe build.directx.hxml`
 - For **OpenGL**: `haxe build.opengl.hxml`
 - For **Javascript/WebGL**: `haxe build.js.hxml`

The `build.dev.hxml` is just a shortcut to one of the previous ones, with added `-debug` flag.

Run the result with either:

 - For **DirectX/OpenGL**: `hl bin\client.hl`
 - For **Javascript**: `start run_js.html`

# Full guide

An in-depth tutorial is available here: [Using gamebase to create a game](https://deepnight.net/tutorial/using-my-gamebase-to-create-a-heaps-game/). Please note that this tutorial still refers to the `legacy` branch, even though the general idea is the same in `master` branch.

For **localization support** (ie. translating your game texts), you may also check the [following guide](https://deepnight.net/tutorial/part-4-localize-texts-using-po-files/).

Any question? Join the [Official Deepnight Games discord](https://deepnight.net/go/discord).

# Cleanup for your own usage

You can safely remove the following files/folders from repo root:

- `.github/`
- `LICENSE`
- `README.md`
- `CHANGELOG.md`
