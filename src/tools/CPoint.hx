package tools;

class CPoint {
	public var cx : Int;
	public var cy : Int;
	public var xr : Float;
	public var yr : Float;

	public var footX(get,never) : Float; inline function get_footX() return (cx+xr)*Const.GRID;
	public var footY(get,never) : Float; inline function get_footY() return (cy+yr)*Const.GRID;
	public var centerX(get,never) : Float; inline function get_centerX() return footX;
	public var centerY(get,never) : Float; inline function get_centerY() return footY-Const.GRID*0.5;

	public function new(x,y, ?xr=0.5, ?yr=1.0) {
		cx = x;
		cy = y;
		this.xr = xr;
		this.yr = yr;
	}

	public function set(x,y,?xr=0.5,?yr=1.0) {
		this.cx = x;
		this.cy = y;
		this.xr = xr;
		this.yr = yr;
	}

	public inline function distCase(e:Entity) {
		return Lib.distance(cx+xr, cy+yr, e.cx+e.xr, e.cy+e.yr);
	}

	public inline function distCasePt(pt:CPoint) {
		return Lib.distance(cx+xr, cy+yr, pt.cx+pt.xr, pt.cy+pt.yr);
	}

	public inline function distPx(e:Entity) {
		return Lib.distance(footX, footY, e.footX, e.footY);
	}
}
