class Camera extends dn.Process {
	/** Camera focus coord in level pixels. This is the raw camera location: the actual camera location might be clamped to level bounds. **/
	public var rawFocus : LPoint;

	/** This is equal to rawFocus if `clampToLevelBounds` is disabled **/
	var clampedFocus : LPoint;

	var target : Null<Entity>;

	/** Width of viewport in level pixels **/
	public var pxWid(get,never) : Int;

	/** Height of viewport in level pixels **/
	public var pxHei(get,never) : Int;

	var dx : Float;
	var dy : Float;
	var bumpOffX = 0.;
	var bumpOffY = 0.;

	/** Speed multiplier when camera is tracking a target **/
	var trackingSpeed = 1.0;

	/** If TRUE (default), the camera will try to stay inside level bounds. It cannot be done if level is smaller than actual viewport. In such case, the camera will be centered. **/
	public var clampToLevelBounds = false;

	/** Left camera bound in level pixels **/
	public var left(get,never) : Int;
		inline function get_left() return Std.int( clampedFocus.levelX-pxWid*0.5 );

	/** Right camera bound in level pixels **/
	public var right(get,never) : Int;
		inline function get_right() return left + pxWid - 1;

	/** Upper camera bound in level pixels **/
	public var top(get,never) : Int;
		inline function get_top() return Std.int( clampedFocus.levelY-pxHei*0.5 );

	/** Lower camera bound in level pixels **/
	public var bottom(get,never) : Int;
		inline function get_bottom() return top + pxHei - 1;

	public var centerX(get,never) : Int;
		inline function get_centerX() return Std.int( (left+right) * 0.5 );

	// Debugging
	var invalidateDebugBounds = false;
	var debugBounds : Null<h2d.Graphics>;


	public function new() {
		super(Game.ME);
		rawFocus = LPoint.fromCase(0,0);
		clampedFocus = LPoint.fromCase(0,0);
		dx = dy = 0;
	}

	@:keep
	override function toString() {
		return 'Camera@${rawFocus.levelX},${rawFocus.levelY}';
	}

	function get_pxWid() {
		return M.ceil( Game.ME.w() / Const.SCALE );
	}

	function get_pxHei() {
		return M.ceil( Game.ME.h() / Const.SCALE );
	}

	public inline function isOnScreen(levelX:Float, levelY: Float) {
		return levelX>=left && levelX<=right && levelY>=top && levelY<=bottom;
	}

	public function trackEntity(e:Entity, immediate:Bool, speed=1.0) {
		target = e;
		setTrackingSpeed(speed);
		if( immediate || rawFocus.levelX==0 && rawFocus.levelY==0 )
			recenter();
	}

	public inline function setTrackingSpeed(spd:Float) {
		trackingSpeed = M.fclamp(spd, 0.01, 10);
	}

	public inline function stopTracking() {
		target = null;
	}

	public function recenter() {
		if( target!=null ) {
			rawFocus.levelX = target.centerX;
			rawFocus.levelY = target.centerY;
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
		if( ui.Console.ME.hasFlag("scroll") )
			return;

		var level = Game.ME.level;
		var scroller = Game.ME.scroller;

		// Update scroller
		scroller.x = -clampedFocus.levelX + pxWid*0.5;
		scroller.y = -clampedFocus.levelY + pxHei*0.5;

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


	public function disableDebugBounds() {
		if( debugBounds!=null ) {
			debugBounds.remove();
			debugBounds = null;
		}
	}
	public function enableDebugBounds() {
		disableDebugBounds();
		debugBounds = new h2d.Graphics();
		Game.ME.scroller.add(debugBounds, Const.DP_TOP);
		invalidateDebugBounds = true;
	}

	function renderDebugBounds() {
		debugBounds.clear();

		debugBounds.lineStyle(2,0xff00ff);
		debugBounds.drawRect(0,0,pxWid,pxHei);

		debugBounds.moveTo(pxWid*0.5, 0);
		debugBounds.lineTo(pxWid*0.5, pxHei);

		debugBounds.moveTo(0, pxHei*0.5);
		debugBounds.lineTo(pxWid, pxHei*0.5);
	}


	override function onResize() {
		super.onResize();
		invalidateDebugBounds = true;
	}


	override function postUpdate() {
		super.postUpdate();

		apply();

		if( ui.Console.ME.hasFlag("cam") && debugBounds==null )
			enableDebugBounds();
		if( !ui.Console.ME.hasFlag("cam") && debugBounds!=null )
			disableDebugBounds();

		if( debugBounds!=null ) {
			if( invalidateDebugBounds ) {
				renderDebugBounds();
				invalidateDebugBounds = false;
			}
			debugBounds.setPosition(left,top);
		}
	}


	override function update() {
		super.update();

		// Follow target entity
		if( target!=null ) {
			var s = 0.006*trackingSpeed;
			var deadZone = 5;
			var tx = target.attachX;
			var ty = target.attachY;

			var d = rawFocus.distPx(tx,ty);
			if( d>=deadZone ) {
				var a = rawFocus.angTo(tx,ty);
				dx += Math.cos(a) * (d-deadZone) * s * tmod;
				dy += Math.sin(a) * (d-deadZone) * s * tmod;
			}
		}

		// Apply velocities
		var frict = 0.89 - trackingSpeed*0.03;
		rawFocus.levelX += dx*tmod;
		dx *= Math.pow(frict,tmod);

		rawFocus.levelY += dy*tmod;
		dy *= Math.pow(frict,tmod);

		// Bounds clamping
		if( clampToLevelBounds ) {
			final level = Game.ME.level;

			// X
			if( level.pxWid < pxWid)
				clampedFocus.levelX = level.pxWid*0.5; // small level
			else
				clampedFocus.levelX = M.fclamp( rawFocus.levelX, pxWid*0.5, level.pxWid-pxWid*0.5 );

			// Y
			if( level.pxHei < pxHei)
				clampedFocus.levelY = level.pxHei*0.5; // small level
			else
				clampedFocus.levelY = M.fclamp( rawFocus.levelY, pxHei*0.5, level.pxHei-pxHei*0.5 );
		}
		else {
			// No clamping
			clampedFocus.levelX = rawFocus.levelX;
			clampedFocus.levelY = rawFocus.levelY;
		}
	}

}