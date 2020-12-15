class Camera extends dn.Process {
	/** Camera focus coord in level pixels. This is the raw camera location: the displayed camera location might be clamped to level bounds. **/
	public var focus : LPoint;

	var target : Null<Entity>;

	/** Width of viewport in level pixels **/
	public var pxWid(get,never) : Int;

	/** Height of viewport in level pixels **/
	public var pxHei(get,never) : Int;

	var dx : Float;
	var dy : Float;
	var bumpOffX = 0.;
	var bumpOffY = 0.;

	/** If TRUE (default), the camera will try to stay inside level bounds. It cannot be done if level is smaller than actual viewport. In such case, the camera will be centered. **/
	public var clampToLevelBounds = true;

	/** Left camera bound in level pixels **/
	public var left(get,never) : Int;
		inline function get_left() return M.imax( M.floor( focus.levelX-pxWid*0.5 ), clampToLevelBounds ? 0 : -Const.INFINITE );

	/** Right camera bound in level pixels **/
	public var right(get,never) : Int;
		inline function get_right() return left + pxWid - 1;

	/** Upper camera bound in level pixels **/
	public var top(get,never) : Int;
		inline function get_top() return M.imax( M.floor( focus.levelY-pxHei*0.5 ), clampToLevelBounds ? 0 : -Const.INFINITE );

	/** Lower camera bound in level pixels **/
	public var bottom(get,never) : Int;
		inline function get_bottom() return top + pxHei - 1;


	public function new() {
		super(Game.ME);
		focus = LPoint.fromCase(0,0);
		dx = dy = 0;
		apply();
	}

	@:keep
	override function toString() {
		return 'Camera@${focus.levelX},${focus.levelY}';
	}

	function get_pxWid() {
		return M.ceil( Game.ME.w() / Const.SCALE );
	}

	function get_pxHei() {
		return M.ceil( Game.ME.h() / Const.SCALE );
	}

	public function trackEntity(e:Entity, immediate:Bool) {
		target = e;
		if( immediate )
			recenter();
	}

	public inline function stopTracking() {
		target = null;
	}

	public function recenter() {
		if( target!=null ) {
			focus.levelX = target.centerX;
			focus.levelY = target.centerY;
		}
	}

	public inline function levelToGlobalX(v:Float) return v*Const.SCALE + Game.ME.scroller.x;
	public inline function levelToGlobalY(v:Float) return v*Const.SCALE + Game.ME.scroller.y;

	var shakePower = 1.0;
	public function shakeS(t:Float, ?pow=1.0) {
		cd.setS("shaking", t, false);
		shakePower = pow;
	}

	public inline function bumpAng(a, dist) {
		bumpOffX+=Math.cos(a)*dist;
		bumpOffY+=Math.sin(a)*dist;
	}

	public inline function bump(x,y) {
		bumpOffX+=x;
		bumpOffY+=y;
	}


	/** Apply camera values to Game scroller **/
	function apply() {
		var level = Game.ME.level;
		var scroller = Game.ME.scroller;

		// Update scroller
		if( !clampToLevelBounds || pxWid<level.pxWid)
			scroller.x = -focus.levelX + pxWid*0.5;
		else
			scroller.x = pxWid*0.5 - level.pxWid*0.5;

		if( !clampToLevelBounds || pxHei<level.pxHei)
			scroller.y = -focus.levelY + pxHei*0.5;
		else
			scroller.y = pxHei*0.5 - level.pxHei*0.5;

		// Clamp
		if( clampToLevelBounds ) {
			if( pxWid<level.cWid*Const.GRID)
				scroller.x = M.fclamp(scroller.x, pxWid-level.pxWid, 0);
			if( pxHei<level.cHei*Const.GRID)
				scroller.y = M.fclamp(scroller.y, pxHei-level.pxHei, 0);
		}

		// Bumps friction
		bumpOffX *= Math.pow(0.75, tmod);
		bumpOffY *= Math.pow(0.75, tmod);

		// Bump
		scroller.x += bumpOffX;
		scroller.y += bumpOffY;

		// Shakes
		if( cd.has("shaking") ) {
			scroller.x += Math.cos(ftime*1.1)*2.5*shakePower * cd.getRatio("shaking");
			scroller.y += Math.sin(0.3+ftime*1.7)*2.5*shakePower * cd.getRatio("shaking");
		}

		// Scaling
		scroller.x*=Const.SCALE;
		scroller.y*=Const.SCALE;

		// Rounding
		scroller.x = M.round(scroller.x);
		scroller.y = M.round(scroller.y);
	}


	override function postUpdate() {
		super.postUpdate();

		if( !ui.Console.ME.hasFlag("scroll") )
			apply();
	}


	override function update() {
		super.update();

		// Follow target entity
		if( target!=null ) {
			var s = 0.006;
			var deadZone = 5;
			var tx = target.footX;
			var ty = target.footY;

			var d = focus.distPx(tx,ty);
			if( d>=deadZone ) {
				var a = focus.angTo(tx,ty);
				dx += Math.cos(a) * (d-deadZone) * s * tmod;
				dy += Math.sin(a) * (d-deadZone) * s * tmod;
			}
		}

		// Movements
		var frict = 0.89;
		focus.levelX += dx*tmod;
		dx *= Math.pow(frict,tmod);

		focus.levelY += dy*tmod;
		dy *= Math.pow(frict,tmod);
	}

}