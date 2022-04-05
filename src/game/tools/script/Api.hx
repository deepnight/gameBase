package tools.script;

/**
	Everything in this class will be available in HScript execution context.
**/
@:keep
class Api {
	public var levelWid(get,never) : Int; inline function get_levelWid() return Game.ME.level.pxWid;
	public var levelHei(get,never) : Int; inline function get_levelHei() return Game.ME.level.pxHei;

	public function new() {}
}