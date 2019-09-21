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

	public function new(x,y, ?xr=0.5, ?yr=0.5) {
		cx = x;
		cy = y;
		this.xr = xr;
		this.yr = yr;
	}

	public function set(x,y,?xr=0.5,?yr=0.5) {
		this.cx = x;
		this.cy = y;
		this.xr = xr;
		this.yr = yr;
	}

	public inline function distCase(?e:Entity, ?pt:CPoint, ?cx=0, ?cy=0, ?xr=0.5, ?yr=0.5) {
		if( e!=null )
			return M.dist(cx+xr, cy+yr, e.cx+e.xr, e.cy+e.yr);
		else if( pt!=null )
			return M.dist(cx+xr, cy+yr, pt.cx+pt.xr, pt.cy+pt.yr);
		else
			return M.dist(this.cx+this.xr, this.cy+this.yr, cx+xr, cy+yr);
	}

	public inline function distPx(?e:Entity, ?pt:CPoint, ?x=0., ?y=0.) {
		if( e!=null )
			return M.dist(footX, footY, e.footX, e.footY);
		else if( pt!=null )
			return M.dist(footX, footY, pt.footX, pt.footY);
		else
			return M.dist(footX, footY, x, y);
	}
}
