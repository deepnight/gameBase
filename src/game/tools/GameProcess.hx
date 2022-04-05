package tools;

class GameProcess extends dn.Process {
	public var app(get,never) : App; inline function get_app() return App.ME;
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.exists() ? Game.ME.fx : null;
	public var level(get,never) : Level; inline function get_level() return Game.exists() ? Game.ME.level : null;

	public function new() {
		super(Game.ME);
	}
}