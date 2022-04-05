package tools;

class LRect {
	var topLeft : LPoint;
	var bottomRight : LPoint;

	/** Pixel based left coordinate **/
	public var pxLeft(get,set) : Int;
	/** Pixel based top coordinate **/
	public var pxTop(get,set) : Int;
	/** Pixel based right coordinate **/
	public var pxRight(get,set) : Int;
	/** Pixel based bottom coordinate **/
	public var pxBottom(get,set) : Int;
	/** Pixel based width **/
	public var pxWid(get,set) : Int;
	/** Pixel based height **/
	public var pxHei(get,set) : Int;

	/** Grid based left coordinate **/
	public var cLeft(get,set) : Int;
	/** Grid based top coordinate **/
	public var cTop(get,set) : Int;
	/** Grid based right coordinate **/
	public var cRight(get,set) : Int;
	/** Grid based bottom coordinate **/
	public var cBottom(get,set) : Int;
	/** Grid based width **/
	public var cWid(get,set) : Int;
	/** Grid based height **/
	public var cHei(get,set) : Int;

	private inline function new() {
		topLeft = LPoint.fromPixels(0,0);
		bottomRight = LPoint.fromPixels(0,0);
	}

	@:keep
	public function toString() : String {
		return 'LRect<px=$pxLeft,$pxTop ${pxWid}x$pxHei / grid=$cLeft,$cTop ${cWid}x$cHei>';
	}

	/**
		Create a LRect using pixel coordinates and dimensions.
	**/
	public static inline function fromPixels(x:Int, y:Int, w:Int, h:Int) {
		var r = new LRect();
		r.topLeft.setLevelPixel(x,y);
		r.bottomRight.setLevelPixel(x+M.iabs(w)-1, y+M.iabs(h)-1);
		return r;
	}


	/**
		Create a LRect using grid-based coordinates and dimensions.
	**/
	public static inline function fromCase(cx:Int, cy:Int, w:Int, h:Int) {
		var r = new LRect();
		r.topLeft.setLevelCase(cx,cy, 0,0);
		r.bottomRight.setLevelCase(cx+M.iabs(w)-1, cy+M.iabs(h)-1, 0.999, 0.999);
		return r;
	}


	/** Swap coordinates if needed **/
	inline function normalize() {
		if( topLeft.levelX > bottomRight.levelX ) {
			var swp = topLeft.levelX;
			topLeft.levelX = bottomRight.levelX;
			bottomRight.levelX = swp;
		}

		if( topLeft.levelY > bottomRight.levelY ) {
			var swp = topLeft.levelY;
			topLeft.levelY = bottomRight.levelY;
			bottomRight.levelY = swp;
		}
	}



	inline function get_pxLeft() return topLeft.levelXi;
	inline function set_pxLeft(v:Int) { topLeft.levelX = v; normalize(); return v; }

	inline function get_pxTop() return topLeft.levelYi;
	inline function set_pxTop(v:Int) { topLeft.levelY = v; normalize(); return v; }

	inline function get_pxBottom() return bottomRight.levelYi;
	inline function set_pxBottom(v:Int) { bottomRight.levelY = v; normalize(); return v; }

	inline function get_pxRight() return bottomRight.levelXi;
	inline function set_pxRight(v:Int) { bottomRight.levelX = v; normalize(); return v; }

	inline function get_pxWid() return bottomRight.levelXi - topLeft.levelXi + 1;
	inline function set_pxWid(v) { bottomRight.levelX = topLeft.levelXi + v; normalize(); return v; }

	inline function get_pxHei() return bottomRight.levelYi - topLeft.levelYi + 1;
	inline function set_pxHei(v) { bottomRight.levelY = topLeft.levelYi + v; normalize(); return v; }



	inline function get_cLeft() return topLeft.cx;
	inline function set_cLeft(v:Int) { topLeft.cx = v; topLeft.xr = 0; normalize(); return v; }

	inline function get_cTop() return topLeft.cy;
	inline function set_cTop(v:Int) { topLeft.cy = v; topLeft.yr = 0; normalize(); return v; }

	inline function get_cRight() return bottomRight.cx;
	inline function set_cRight(v:Int) { bottomRight.cx = v; bottomRight.xr = 0.999; normalize(); return v; }

	inline function get_cBottom() return bottomRight.cy;
	inline function set_cBottom(v:Int) { bottomRight.cy = v; bottomRight.yr = 0.999; normalize(); return v; }

	inline function get_cWid() return bottomRight.cx - topLeft.cx + 1;
	inline function set_cWid(v:Int) { bottomRight.cx = topLeft.cx + v-1; bottomRight.xr = 0.999; normalize(); return v; }

	inline function get_cHei() return bottomRight.cy - topLeft.cy + 1;
	inline function set_cHei(v:Int) { bottomRight.cy = topLeft.cy + v-1; bottomRight.yr = 0.999; normalize(); return v; }
}
