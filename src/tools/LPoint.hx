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

	/** Level X coord **/
	public var levelX(get,set) : Float;
		inline function get_levelX() return (cx+xr)*Const.GRID;
		inline function set_levelX(v:Float) {
			setLevelPixelX(v);
			return levelX;
		}

	/** Level Y coord **/
	public var levelY(get,set) : Float;
		inline function get_levelY() return (cy+yr)*Const.GRID;
		inline function set_levelY(v:Float) {
			setLevelPixelY(v);
			return levelY;
		}

	/** Level pixel X coord **/
	public var pixelX(get,set) : Int;
		inline function get_pixelX() return Std.int(levelX);
		inline function set_pixelX(v:Int) {
			setLevelPixelX(v);
			return pixelX;
		}

	/** Level pixel Y coord **/
	public var pixelY(get,set) : Int;
		inline function get_pixelY() return Std.int(levelY);
		inline function set_pixelY(v:Int) {
			setLevelPixelY(v);
			return pixelY;
		}

	/** Global screen X coord **/
	public var globalX(get,never) : Float;
		inline function get_globalX() : Float {
			if( Game.ME==null || Game.ME.destroyed )
				return -1;
			else
				return levelX * Const.SCALE + Game.ME.scroller.x;
		}

	/** Global screen Y coord **/
	public var globalY(get,never) : Float;
		inline function get_globalY() : Float {
			if( Game.ME==null || Game.ME.destroyed )
				return -1;
			else
				return levelY * Const.SCALE + Game.ME.scroller.y;
		}



	private inline function new() {
		cx = cy = 0;
		xr = yr = 0;
	}

	@:keep
	public function toString() : String {
		return 'LPoint<${M.pretty(cxf)},${M.pretty(cyf)} / $pixelX,$pixelY>';
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

	/** Init using level grid coords **/
	public inline function setLevelCase(x,y,?xr=0.5,?yr=0.5) {
		this.cx = x;
		this.cy = y;
		this.xr = xr;
		this.yr = yr;
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
	public inline function distCase(?e:Entity, ?pt:LPoint, ?cx=0, ?cy=0, ?xr=0.5, ?yr=0.5) {
		if( e!=null )
			return M.dist(this.cx+this.xr, this.cy+this.yr, e.cx+e.xr, e.cy+e.yr);
		else if( pt!=null )
			return M.dist(this.cx+this.xr, this.cy+this.yr, pt.cx+pt.xr, pt.cy+pt.yr);
		else
			return M.dist(this.cx+this.xr, this.cy+this.yr, cx+xr, cy+yr);
	}

	/** Return distance to something else, in level pixels **/
	public inline function distPx(?e:Entity, ?pt:LPoint, ?x=0., ?y=0.) {
		if( e!=null )
			return M.dist(levelX, levelY, e.footX, e.footY);
		else if( pt!=null )
			return M.dist(levelX, levelY, pt.levelX, pt.levelY);
		else
			return M.dist(levelX, levelY, x, y);
	}
	/** Return distance to something else, in level pixels **/
	public inline function angTo(?e:Entity, ?pt:LPoint, ?x=0., ?y=0.) {
		if( e!=null )
			return Math.atan2((e.cy+e.yr)-cyf, (e.cx+e.xr)-cxf );
		else if( pt!=null )
			return Math.atan2(pt.cyf-cyf, pt.cxf-cxf);
		else
			return Math.atan2(y-levelY, x-levelX);
	}
}
