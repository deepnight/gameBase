class Camera extends GameProcess {
	public static var MIN_ZOOM : Float = 1.0;
	public static var MAX_ZOOM : Float = 10;


	/** Camera focus coord in level pixels. This is the raw camera location: the actual camera location might be clamped to level bounds. **/
	public var rawFocus : LPoint;

	/** This is equal to rawFocus if `clampToLevelBounds` is disabled **/
	var clampedFocus : LPoint;

	var target : Null<Entity>;
	public var targetOffX = 0.;
	public var targetOffY = 0.;

	/** Width of viewport in level pixels **/
	public var pxWid(get,never) : Int;

	/** Height of viewport in level pixels **/
	public var pxHei(get,never) : Int;

	public var cWid(get,never) : Int;  inline function get_cWid() return M.ceil(pxWid/Const.GRID);
	public var cHei(get,never) : Int;  inline function get_cHei() return M.ceil(pxHei/Const.GRID);

	/** Horizontal camera dead-zone in percentage of viewport width **/
	public var deadZonePctX = 0.04;

	/** Verticakl camera dead-zone in percentage of viewport height **/
	public var deadZonePctY = 0.10;

	var baseFrict = 0.89;
	var dx = 0.;
	var dy = 0.;
	var dz = 0.;
	var bumpOffX = 0.;
	var bumpOffY = 0.;
	var bumpFrict = 0.85;
	var bumpZoomFactor = 0.;

	/** Actual zoom value without modifiers **/
	var baseZoom = 1.0;
	var zoomSpeed = 0.0014;
	var zoomFrict = 0.9;

	/** Current zoom factor, including all modifiers **/
	public var zoom(get,never) : Float;

	/** Target base zoom value **/
	public var targetZoom(default,set) = 1.0;

	/** Speed multiplier when camera is tracking a target **/
	var trackingSpeed = 1.0;

	/** If TRUE (default), the camera will try to stay inside level bounds. It cannot be done if level is smaller than actual viewport. In such case, the camera will be centered. **/
	public var clampToLevelBounds = false;
	var brakeDistNearBounds = 0.1;


	/** Camera bound coords in level pixels **/
	public var pxLeft(get,never) : Int;  inline function get_pxLeft() return Std.int( clampedFocus.levelX - pxWid*0.5 );
	public var pxRight(get,never) : Int;  inline function get_pxRight() return Std.int( pxLeft + (pxWid - 1) );
	public var pxTop(get,never) : Int;  inline function get_pxTop() return Std.int( clampedFocus.levelY-pxHei*0.5 );
	public var pxBottom(get,never) : Int;  inline function get_pxBottom() return pxTop + pxHei - 1;

	/** Center X in pixels **/
	public var centerX(get,never) : Int;  inline function get_centerX() return Std.int( (pxLeft+pxRight) * 0.5 );

	/** Center Y in pixels **/
	public var centerY(get,never) : Int;  inline function get_centerY() return Std.int( (pxTop+pxBottom) * 0.5 );

	/** Camera bound coords in grid cells **/
	public var cLeft(get,never) : Int;  inline function get_cLeft() return Std.int( pxLeft/Const.GRID );
	public var cRight(get,never) : Int;  inline function get_cRight() return M.ceil( pxRight/Const.GRID );
	public var cTop(get,never) : Int;  inline function get_cTop() return Std.int( pxTop/Const.GRID );
	public var cBottom(get,never) : Int;  inline function get_cBottom() return M.ceil( pxBottom/Const.GRID );

	// Debugging
	var invalidateDebugBounds = false;
	var debugBounds : Null<h2d.Graphics>;


	public function new() {
		super();
		rawFocus = LPoint.fromCase(0,0);
		clampedFocus = LPoint.fromCase(0,0);
		dx = dy = 0;
	}

	@:keep
	override function toString() {
		return 'Camera@${Std.int(rawFocus.levelX)},${Std.int(rawFocus.levelY)}';
	}

	inline function get_zoom() {
		return baseZoom + bumpZoomFactor;
	}


	inline function set_targetZoom(v) {
		return targetZoom = M.fclamp(v, MIN_ZOOM, MAX_ZOOM);
	}

	/** Smoothly change zoom within MIN/MAX bounds **/
	public inline function zoomTo(v:Float) {
		targetZoom = v;
	}

	/** Force zoom immediately to given value **/
	public function forceZoom(v) {
		baseZoom = targetZoom = M.fclamp(v, MIN_ZOOM, MAX_ZOOM);
		dz = 0;
	}

	public inline function bumpZoom(z:Float) {
		bumpZoomFactor = z;
	}

	function get_pxWid() {
		return M.ceil( Game.ME.w() / Const.SCALE / zoom );
	}

	function get_pxHei() {
		return M.ceil( Game.ME.h() / Const.SCALE / zoom );
	}


	/**
		Return TRUE if given coords are in current camera bounds. Padding is *added* to the screen bounds (it can be negative to *shrink* these bounds).
	**/
	public inline function isOnScreen(levelX:Float, levelY: Float, padding=0.) {
		return levelX>=pxLeft-padding && levelX<=pxRight+padding && levelY>=pxTop-padding && levelY<=pxBottom+padding;
	}

	/**
		Return TRUE if given rectangle is partially inside current camera bounds. Padding is *added* to the screen bounds (it can be negative to *shrink* these bounds).
	**/
	public inline function isOnScreenRect(x:Float, y:Float, wid:Float, hei:Float, padding=0.) {
		return Lib.rectangleOverlaps(
			pxLeft-padding, pxTop-padding, pxWid+padding*2, pxHei+padding*2,
			x, y, wid, hei
		);
	}

	/**
		Return TRUE if given grid coords are in current camera bounds. Padding is *added* to the screen bounds (it can be negative to *shrink* these bounds).
	**/
	public inline function isOnScreenCase(cx:Int, cy:Int, padding=32) {
		return cx*Const.GRID>=pxLeft-padding && (cx+1)*Const.GRID<=pxRight+padding
			&& cy*Const.GRID>=pxTop-padding && (cy+1)*Const.GRID<=pxBottom+padding;
	}


	/**
		Enable auto tracking on given Entity. If `immediate` is true, the camera is immediately positioned over the Entity, otherwise it just moves to it.
	**/
	public function trackEntity(e:Entity, immediate:Bool, speed=1.0) {
		target = e;
		setTrackingSpeed(speed);
		if( immediate || rawFocus.levelX==0 && rawFocus.levelY==0 )
			centerOnTarget();
	}

	public inline function setTrackingSpeed(spd:Float) {
		trackingSpeed = M.fclamp(spd, 0.01, 10);
	}

	public inline function stopTracking() {
		target = null;
	}

	public function centerOnTarget() {
		if( target!=null ) {
			rawFocus.levelX = target.centerX + targetOffX;
			rawFocus.levelY = target.centerY + targetOffY;
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
		bumpOffX *= Math.pow(bumpFrict, tmod);
		bumpOffY *= Math.pow(bumpFrict, tmod);

		// Bump
		scroller.x -= bumpOffX;
		scroller.y -= bumpOffY;

		// Shakes
		if( cd.has("shaking") ) {
			scroller.x += Math.cos(ftime*1.1)*2.5*shakePower * cd.getRatio("shaking");
			scroller.y += Math.sin(0.3+ftime*1.7)*2.5*shakePower * cd.getRatio("shaking");
		}

		// Scaling
		scroller.x*=Const.SCALE*zoom;
		scroller.y*=Const.SCALE*zoom;

		// Rounding
		scroller.x = M.round(scroller.x);
		scroller.y = M.round(scroller.y);

		// Zoom
		scroller.setScale(Const.SCALE * zoom);
	}


	/** Hide camera debug bounds **/
	public function disableDebugBounds() {
		if( debugBounds!=null ) {
			debugBounds.remove();
			debugBounds = null;
		}
	}

	/** Show camera debug bounds **/
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

		// Debug bounds
		if( ui.Console.ME.hasFlag("cam") && debugBounds==null )
			enableDebugBounds();
		else if( !ui.Console.ME.hasFlag("cam") && debugBounds!=null )
			disableDebugBounds();

		if( debugBounds!=null ) {
			if( invalidateDebugBounds ) {
				renderDebugBounds();
				invalidateDebugBounds = false;
			}
			debugBounds.setPosition(pxLeft,pxTop);
		}
	}


	override function update() {
		super.update();

		final level = Game.ME.level;


		// Zoom movement
		var tz = targetZoom;

		if( tz!=baseZoom ) {
			if( tz>baseZoom)
				dz+=zoomSpeed;
			else
				dz-=zoomSpeed;
		}
		else
			dz = 0;

		var prevZoom = baseZoom;
		baseZoom+=dz*tmod;

		bumpZoomFactor *= Math.pow(0.9, tmod);
		dz*=Math.pow(zoomFrict, tmod);
		if( M.fabs(tz-baseZoom)<=0.05*tmod )
			dz*=Math.pow(0.8,tmod);

		// Reached target zoom
		if( prevZoom<tz && baseZoom>=tz || prevZoom>tz && baseZoom<=tz ) {
			baseZoom = tz;
			dz = 0;
		}


		// Follow target entity
		if( target!=null ) {
			var spdX = 0.015*trackingSpeed*zoom;
			var spdY = 0.023*trackingSpeed*zoom;
			var tx = target.centerX + targetOffX;
			var ty = target.centerY + targetOffY;

			var a = rawFocus.angTo(tx,ty);
			var distX = M.fabs( tx - rawFocus.levelX );
			if( distX>=deadZonePctX*pxWid )
				dx += Math.cos(a) * (0.8*distX-deadZonePctX*pxWid) * spdX * tmod;

			var distY = M.fabs( ty - rawFocus.levelY );
			if( distY>=deadZonePctY*pxHei)
				dy += Math.sin(a) * (0.8*distY-deadZonePctY*pxHei) * spdY * tmod;
		}

		// Compute frictions
		var frictX = baseFrict - trackingSpeed*zoom*0.027*baseFrict;
		var frictY = frictX;
		if( clampToLevelBounds ) {
			// "Brake" when approaching bounds
			final brakeDist = brakeDistNearBounds * pxWid;
			if( dx<=0 ) {
				final brakeRatio = 1-M.fclamp( ( rawFocus.levelX - pxWid*0.5 ) / brakeDist, 0, 1 );
				frictX *= 1 - 1*brakeRatio;
			}
			else if( dx>0 ) {
				final brakeRatio = 1-M.fclamp( ( (level.pxWid-pxWid*0.5) - rawFocus.levelX ) / brakeDist, 0, 1 );
				frictX *= 1 - 0.9*brakeRatio;
			}

			final brakeDist = brakeDistNearBounds * pxHei;
			if( dy<0 ) {
				final brakeRatio = 1-M.fclamp( ( rawFocus.levelY - pxHei*0.5 ) / brakeDist, 0, 1 );
				frictY *= 1 - 0.9*brakeRatio;
			}
			else if( dy>0 ) {
				final brakeRatio = 1-M.fclamp( ( (level.pxHei-pxHei*0.5) - rawFocus.levelY ) / brakeDist, 0, 1 );
				frictY *= 1 - 0.9*brakeRatio;
			}
		}

		// Apply velocities
		rawFocus.levelX += dx*tmod;
		dx *= Math.pow(frictX,tmod);
		rawFocus.levelY += dy*tmod;
		dy *= Math.pow(frictY,tmod);


		// Bounds clamping
		if( clampToLevelBounds ) {
			// X
			if( level.pxWid < pxWid)
				clampedFocus.levelX = level.pxWid*0.5; // centered small level
			else
				clampedFocus.levelX = M.fclamp( rawFocus.levelX, pxWid*0.5, level.pxWid-pxWid*0.5 );

			// Y
			if( level.pxHei < pxHei)
				clampedFocus.levelY = level.pxHei*0.5; // centered small level
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