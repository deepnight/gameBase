package tools;

/**
	A generic X/Y velocity utility class
**/
class Velocity {
	public var dx : Float;
	public var dy : Float;
	public var frictX : Float;
	public var frictY : Float;
	public var killThreshold = 0.0005;

	public var frict(never,set) : Float;
		inline function set_frict(v) return frictX = frictY = v;

	public var dirX(get,never) : Int; inline function get_dirX() return M.sign(dx);
	public var dirY(get,never) : Int; inline function get_dirY() return M.sign(dy);


	public inline function new(frict=0.9) {
		dx = dy = 0;
		this.frict = frict;
	}

	@:keep
	public inline function toString() {
		return 'Velocity(${M.pretty(dx,2)},${M.pretty(dy,2)})';
	}

	public inline function setFricts(x:Float, y:Float) {
		frictX = x;
		frictY = y;
	}

	public inline function mul(v:Float) {
		dx*=v;
		dy*=v;
	}

	public inline function clear() {
		dx = dy = 0;
	}

	public inline function add(x:Float, y:Float) {
		dx+=x;
		dy+=y;
	}

	public inline function addAng(ang:Float, v:Float) {
		dx += Math.cos(ang)*v;
		dy += Math.sin(ang)*v;
	}

	public inline function isZero() return dx==0 && dy==0;
	public inline function getAng() return Math.atan2(dy,dx);


	public inline function fixedUpdate() {
		dx*=frictX;
		dy*=frictY;

		if( M.fabs(dx)<=killThreshold )
			dx = 0;

		if( M.fabs(dy)<=killThreshold )
			dy = 0;
	}
}
