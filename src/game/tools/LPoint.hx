package tools;

class LPoint {
	/** Grid based X **/
	public var cx : Int;

	/** Grid based Y **/
	public var cy : Int;

	/** X-ratio (0-1) in current grid cell **/
	public var xr : Float;

	/** Y-ratio (0-1) in current grid cell **/
	public var yr : Float;



	/** Grid based X, including sub grid cell ratio **/
	public var cxf(get,never) : Float;
		inline function get_cxf() return cx+xr;

	/** Grid based Y, including sub grid cell ratio **/
	public var cyf(get,never) : Float;
		inline function get_cyf() return cy+yr;



	/** Level X pixel coord **/
	public var levelX(get,set) : Float;
		inline function get_levelX() return (cx+xr)*Const.GRID;
		inline function set_levelX(v:Float) {
			setLevelPixelX(v);
			return levelX;
		}

	/** Level Y pixel coord **/
	public var levelY(get,set) : Float;
		inline function get_levelY() return (cy+yr)*Const.GRID;
		inline function set_levelY(v:Float) {
			setLevelPixelY(v);
			return levelY;
		}



	/** Level X pixel coord (as Integer) **/
	public var levelXi(get,never) : Int;
		inline function get_levelXi() return Std.int(levelX);

	/** Level Y pixel coord **/
	public var levelYi(get,never) : Int;
		inline function get_levelYi() return Std.int(levelY);



	/** Screen X pixel coord **/
	public var screenX(get,never) : Float;
		inline function get_screenX() {
			return !Game.exists() ? -1. : levelX*Const.SCALE + Game.ME.scroller.x;
		}

	/** Screen Y pixel coord **/
	public var screenY(get,never) : Float;
		inline function get_screenY() {
			return !Game.exists() ? -1. : levelY*Const.SCALE + Game.ME.scroller.y;
		}



	private inline function new() {
		cx = cy = 0;
		xr = yr = 0;
	}

	@:keep
	public function toString() : String {
		return 'LPoint<${M.pretty(cxf)},${M.pretty(cyf)} / $levelXi,$levelYi>';
	}

	public static inline function fromCase(cx:Float, cy:Float) {
		return new LPoint().setLevelCase( Std.int(cx), Std.int(cy), cx%1, cy%1 );
	}

	public static inline function fromCaseCenter(cx:Int, cy:Int) {
		return new LPoint().setLevelCase(cx, cy, 0.5, 0.5);
	}

	public static inline function fromPixels(x:Float, y:Float) {
		return new LPoint().setLevelPixel(x,y);
	}

	public static inline function fromScreen(sx:Float, sy:Float) {
		return new LPoint().setScreen(sx,sy);
	}

	/** Init using level grid coords **/
	public inline function setLevelCase(x,y,?xr=0.5,?yr=0.5) {
		this.cx = x;
		this.cy = y;
		this.xr = xr;
		this.yr = yr;
		return this;
	}

	/** Init from screen coord **/
	public inline function setScreen(sx:Float, sy:Float) {
		setLevelPixel(
			( sx - Game.ME.scroller.x ) / Const.SCALE,
			( sy - Game.ME.scroller.y ) / Const.SCALE
		);
		return this;
	}

	/** Init using level pixels coords **/
	public inline function setLevelPixel(x:Float,y:Float) {
		setLevelPixelX(x);
		setLevelPixelY(y);
		return this;
	}

	inline function setLevelPixelX(x:Float) {
		cx = Std.int(x/Const.GRID);
		this.xr = ( x % Const.GRID ) / Const.GRID;
		return this;
	}

	inline function setLevelPixelY(y:Float) {
		cy = Std.int(y/Const.GRID);
		this.yr = ( y % Const.GRID ) / Const.GRID;
		return this;
	}

	/** Return distance to something else, in grid unit **/
	public inline function distCase(?e:Entity, ?pt:LPoint, ?tcx=0, ?tcy=0, ?txr=0.5, ?tyr=0.5) {
		if( e!=null )
			return M.dist(this.cx+this.xr, this.cy+this.yr, e.cx+e.xr, e.cy+e.yr);
		else if( pt!=null )
			return M.dist(this.cx+this.xr, this.cy+this.yr, pt.cx+pt.xr, pt.cy+pt.yr);
		else
			return M.dist(this.cx+this.xr, this.cy+this.yr, tcx+txr, tcy+tyr);
	}

	/** Distance to something else, in level pixels **/
	public inline function distPx(?e:Entity, ?pt:LPoint, ?lvlX=0., ?lvlY=0.) {
		if( e!=null )
			return M.dist(levelX, levelY, e.attachX, e.attachY);
		else if( pt!=null )
			return M.dist(levelX, levelY, pt.levelX, pt.levelY);
		else
			return M.dist(levelX, levelY, lvlX, lvlY);
	}

	/** Angle in radians to something else, in level pixels **/
	public inline function angTo(?e:Entity, ?pt:LPoint, ?lvlX=0., ?lvlY=0.) {
		if( e!=null )
			return Math.atan2((e.cy+e.yr)-cyf, (e.cx+e.xr)-cxf );
		else if( pt!=null )
			return Math.atan2(pt.cyf-cyf, pt.cxf-cxf);
		else
			return Math.atan2(lvlY-levelY, lvlX-levelX);
	}
}
