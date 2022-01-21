class Entity {
    public static var ALL : Array<Entity> = [];
    public static var GC : Array<Entity> = [];

	// Various getters to access all important stuff easily
	public var app(get,never) : App; inline function get_app() return App.ME;
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;
	public var level(get,never) : Level; inline function get_level() return Game.ME.level;
	public var destroyed(default,null) = false;
	public var ftime(get,never) : Float; inline function get_ftime() return game.ftime;
	public var camera(get,never) : Camera; inline function get_camera() return game.camera;

	var tmod(get,never) : Float; inline function get_tmod() return Game.ME.tmod;
	var utmod(get,never) : Float; inline function get_utmod() return Game.ME.utmod;
	public var hud(get,never) : ui.Hud; inline function get_hud() return Game.ME.hud;

	/** Cooldowns **/
	public var cd : dn.Cooldown;

	/** Cooldowns, unaffected by slowmo (ie. always in realtime) **/
	public var ucd : dn.Cooldown;

	/** Temporary gameplay affects **/
	var affects : Map<Affect,Float> = new Map();

	/** Unique identifier **/
	public var uid(default,null) : Int;

	/** Grid X coordinate **/
    public var cx = 0;
	/** Grid Y coordinate **/
    public var cy = 0;
	/** Sub-grid X coordinate (from 0.0 to 1.0) **/
    public var xr = 0.5;
	/** Sub-grid Y coordinate (from 0.0 to 1.0) **/
    public var yr = 1.0;

	/** X velocity, in grid fractions **/
    public var dx = 0.;
	/** Y velocity, in grid fractions **/
	public var dy = 0.;

	/** Uncontrollable bump X velocity, usually applied by external factors (eg. a bumper in Sonic) **/
    public var bdx = 0.;
	/** Uncontrollable bump Y velocity, usually applied by external factors (eg. a bumper in Sonic) **/
	public var bdy = 0.;

	/** Last known X position of the attach point (in pixels), at the beginning of the latest fixedUpdate **/
	var lastFixedUpdateX = 0.;
	/** Last known Y position of the attach point (in pixels), at the beginning of the latest fixedUpdate **/
	var lastFixedUpdateY = 0.;

	/** If TRUE, the sprite display coordinates will be an interpolation between the last known position and the current one. This is useful if the gameplay happens in the `fixedUpdate()` (so at 30 FPS), but you still want the sprite position to move smoothly at 60 FPS or more. **/
	var interpolateSprPos = true;

	// Velocities + bump velocities
	public var dxTotal(get,never) : Float; inline function get_dxTotal() return dx+bdx;
	public var dyTotal(get,never) : Float; inline function get_dyTotal() return dy+bdy;

	/** Multiplier applied on each frame to normal X velocity **/
	public var frictX = 0.82;
	/** Multiplier applied on each frame to normal Y velocity **/
	public var frictY = 0.82;

	/** Sets both frictX/Y at the same time **/
	public var frict(never,set) : Float;
		inline function set_frict(v) return frictX = frictY = v;

	/** Multiplier applied on each frame to bump X velocity **/
	public var bumpFrictX = 0.93;
	/** Multiplier applied on each frame to bump Y velocity **/
	public var bumpFrictY = 0.93;

	/** Pixel width of entity **/
	public var wid(default,set) : Float = Const.GRID;
		inline function set_wid(v) { invalidateDebugBounds=true;  return wid=v; }

	/** Pixel height of entity **/
	public var hei(default,set) : Float = Const.GRID;
		inline function set_hei(v) { invalidateDebugBounds=true;  return hei=v; }

	/** Inner radius in pixels (ie. smallest value between width/height, then divided by 2) **/
	public var innerRadius(get,never) : Float;
		inline function get_innerRadius() return M.fmin(wid,hei)*0.5;

	/** "Large" radius in pixels (ie. biggest value between width/height, then divided by 2) **/
	public var largeRadius(get,never) : Float;
		inline function get_largeRadius() return M.fmax(wid,hei)*0.5;

	/** Horizontal direction, can only be -1 or 1 **/
	public var dir(default,set) = 1;

	/** Current sprite X **/
	public var sprX(get,never) : Float;
		inline function get_sprX() {
			return interpolateSprPos
				? M.lerp( lastFixedUpdateX, (cx+xr)*Const.GRID, game.getFixedUpdateAccuRatio() )
				: (cx+xr)*Const.GRID;
		}

	/** Current sprite Y **/
	public var sprY(get,never) : Float;
		inline function get_sprY() {
			return interpolateSprPos
				? M.lerp( lastFixedUpdateY, (cy+yr)*Const.GRID, game.getFixedUpdateAccuRatio() )
				: (cy+yr)*Const.GRID;
		}

	public var sprScaleX = 1.0;
	public var sprScaleY = 1.0;

	
	var sprSquashX = 1.0;
	var sprSquashY = 1.0;

	public var entityVisible = true;

	public var life(default,null)    : Int;
	public var maxLife(default,null) : Int;
	/** Last source of damage if it was an Entity **/
	public var lastDmgSource(default,null) : Null<Entity>;

	/** Horizontal direction (left=-1 or right=1): from "last source of damage" to "this" **/
	public var lastHitDirFromSource(get,never) : Int;
	inline function get_lastHitDirFromSource() return lastDmgSource==null ? -dir : -dirTo(lastDmgSource);

	/** Horizontal direction (left=-1 or right=1): from "this" to "last source of damage" **/
	public var lastHitDirToSource(get,never) : Int;
		inline function get_lastHitDirToSource() return lastDmgSource==null ? dir : dirTo(lastDmgSource);

	
    public var spr : HSprite;

	
	public var baseColor : h3d.Vector;
	var blinkColor : h3d.Vector;

	/** Color matrix transformation applied to sprite **/
	public var colorMatrix : h3d.Matrix;

	var shakePowX = 0.;
	var shakePowY = 0.;

	// Debug stuff
	var debugLabel : Null<h2d.Text>;
	var debugBounds : Null<h2d.Graphics>;
	var invalidateDebugBounds = false;

	public var pivotX(default,set) : Float = 0.5;
	public var pivotY(default,set) : Float = 1;

	public var attachX(get,never) : Float; inline function get_attachX() return (cx+xr)*Const.GRID;
	public var attachY(get,never) : Float; inline function get_attachY() return (cy+yr)*Const.GRID;

	public var prevFrameattachX(default,null) : Float = -Const.INFINITE;
	public var prevFrameattachY(default,null) : Float = -Const.INFINITE;

	// Various coordinates getters, for easier gameplay coding

	//Bounding box getters//
	public var left(get,never) : Float; inline function get_left() return attachX + (0-pivotX) * wid;
	public var right(get,never) : Float; inline function get_right() return attachX + (1-pivotX) * wid;
	public var top(get,never) : Float; inline function get_top() return attachY + (0-pivotY) * hei;
	public var bottom(get,never) : Float; inline function get_bottom() return attachY + (1-pivotY) * hei;

	// Bounding box center//
	public var centerX(get,never) : Float; inline function get_centerX() return attachX + (0.5-pivotX) * wid;
	public var centerY(get,never) : Float; inline function get_centerY() return attachY + (0.5-pivotY) * hei;

	//Position on screen (ie. absolute)//
	public var screenAttachX(get,never) : Float;
		inline function get_screenAttachX() return game!=null && !game.destroyed ? sprX*Const.SCALE + game.scroller.x : sprX*Const.SCALE;

	public var screenAttachY(get,never) : Float;
		inline function get_screenAttachY() return game!=null && !game.destroyed ? sprY*Const.SCALE + game.scroller.y : sprY*Const.SCALE;


	var actions : Array<{ id:String, cb:Void->Void, t:Float }> = [];


    public function new(x:Int, y:Int) {
        uid = Const.makeUniqueId();
		ALL.push(this);

		cd = new dn.Cooldown(Const.FPS);
		ucd = new dn.Cooldown(Const.FPS);
        setPosCase(x,y);
		initLife(1);

        spr = new HSprite(Assets.tiles);
		Game.ME.scroller.add(spr, Const.DP_MAIN);
		spr.colorAdd = new h3d.Vector();
		baseColor = new h3d.Vector();
		blinkColor = new h3d.Vector();
		spr.colorMatrix = colorMatrix = h3d.Matrix.I();
		spr.setCenterRatio(pivotX, pivotY);

		if( ui.Console.ME.hasFlag("bounds") )
			enableDebugBounds();
    }

	function set_pivotX(v) {
		pivotX = M.fclamp(v,0,1);
		if( spr!=null )
			spr.setCenterRatio(pivotX, pivotY);
		return pivotX;
	}

	function set_pivotY(v) {
		pivotY = M.fclamp(v,0,1);
		if( spr!=null )
			spr.setCenterRatio(pivotX, pivotY);
		return pivotY;
	}

	/** Initialize current and max hit points **/
	public function initLife(v) {
		life = maxLife = v;
	}

	/** Inflict damage **/
	public function hit(dmg:Int, from:Null<Entity>) {
		if( !isAlive() || dmg<=0 )
			return;

		life = M.iclamp(life-dmg, 0, maxLife);
		lastDmgSource = from;
		onDamage(dmg, from);
		if( life<=0 )
			onDie();
	}

	/** Kill instantly **/
	public function kill(by:Null<Entity>) {
		if( isAlive() )
			hit(life,by);
	}

	function onDamage(dmg:Int, from:Entity) {}

	function onDie() {
		destroy();
	}

	inline function set_dir(v) {
		return dir = v>0 ? 1 : v<0 ? -1 : dir;
	}

	/** Return TRUE if current entity wasn't destroyed or killed **/
	public inline function isAlive() {
		return !destroyed && life>0;
	}

	/** Move entity to grid coordinates **/
	public function setPosCase(x:Int, y:Int) {
		cx = x;
		cy = y;
		xr = 0.5;
		yr = 1;
		onPosManuallyChanged();
	}

	/** Move entity to pixel coordinates **/
	public function setPosPixel(x:Float, y:Float) {
		cx = Std.int(x/Const.GRID);
		cy = Std.int(y/Const.GRID);
		xr = (x-cx*Const.GRID)/Const.GRID;
		yr = (y-cy*Const.GRID)/Const.GRID;
		onPosManuallyChanged();
	}

	/** Should be called when you manually modify entity coordinates **/
	function onPosManuallyChanged() {
		if( M.dist(attachX,attachY,prevFrameattachX,prevFrameattachY) > Const.GRID*2 ) {
			prevFrameattachX = attachX;
			prevFrameattachY = attachY;
		}
		updateLastFixedUpdatePos();
	}

	/** Quickly set X/Y pivots. If Y is omitted, it will be equal to X. **/
	public function setPivots(x:Float, ?y:Float) {
		pivotX = x;
		pivotY = y!=null ? y : x;
	}

	/** Return TRUE if the Entity *center point* is in screen bounds (default padding is +32px) **/
	public inline function isOnScreenCenter(padding=32) {
		return camera.isOnScreen( centerX, centerY, padding + M.fmax(wid*0.5, hei*0.5) );
	}

	/** Return TRUE if the Entity rectangle is in screen bounds (default padding is +32px) **/
	public inline function isOnScreenBounds(padding=32) {
		return camera.isOnScreenRect( left,top, wid, hei, padding );
	}

	/** Apply a bump/kick force to entity **/
	public function bump(x:Float,y:Float) {
		bdx += x;
		bdy += y;
	}

	/** Reset velocities to zero **/
	public function cancelVelocities() {
		dx = bdx = 0;
		dy = bdy = 0;
	}

	public function is<T:Entity>(c:Class<T>) return Std.isOfType(this, c);
	public function as<T:Entity>(c:Class<T>) : T return Std.downcast(this, c);

	/** Return a random Float value in range [min,max]. If `sign` is TRUE, returned value might be multiplied by -1 randomly. **/
	public inline function rnd(min,max,?sign) return Lib.rnd(min,max,sign);
	/** Return a random Integer value in range [min,max]. If `sign` is TRUE, returned value might be multiplied by -1 randomly. **/
	public inline function irnd(min,max,?sign) return Lib.irnd(min,max,sign);

	/** Truncate a float value using given `precision` **/
	public inline function pretty(value:Float,?precision=1) return M.pretty(value,precision);

	public inline function dirTo(e:Entity) return e.centerX<centerX ? -1 : 1;
	public inline function dirToAng() return dir==1 ? 0. : M.PI;
	public inline function getMoveAng() return Math.atan2(dyTotal,dxTotal);

	/** Return a distance (in grid cells) from this to something **/
	public inline function distCase(?e:Entity, ?tcx:Int, ?tcy:Int, ?txr=0.5, ?tyr=0.5) {
		if( e!=null )
			return M.dist(cx+xr, cy+yr, e.cx+e.xr, e.cy+e.yr);
		else
			return M.dist(cx+xr, cy+yr, tcx+txr, tcy+tyr);
	}

	/** Return a distance (in pixels) from this to something **/
	public inline function distPx(?e:Entity, ?x:Float, ?y:Float) {
		if( e!=null )
			return M.dist(attachX, attachY, e.attachX, e.attachY);
		else
			return return M.dist(attachX, attachY, x, y);
	}

	function canSeeThrough(cx:Int, cy:Int) {
		return !level.hasCollision(cx,cy) || this.cx==cx && this.cy==cy;
	}

	/** Check if the grid-based line between this and given target isn't blocked by some obstacle **/
	public inline function sightCheck(?e:Entity, ?tcx:Int, ?tcy:Int) {
		if( e!=this )
			return dn.Bresenham.checkThinLine(cx, cy, e.cx, e.cy, canSeeThrough);
		else
			return dn.Bresenham.checkThinLine(cx, cy, tcx, tcy, canSeeThrough);
	}

	/** Create a LPoint instance from current coordinates **/
	public inline function createPoint() return LPoint.fromCase(cx+xr,cy+yr);

	/** Create a LRect instance from current entity bounds **/
	public inline function createRect() return tools.LRect.fromPixels( Std.int(left), Std.int(top), Std.int(wid), Std.int(hei) );

    public final function destroy() {
        if( !destroyed ) {
            destroyed = true;
            GC.push(this);
        }
    }

    public function dispose() {
        ALL.remove(this);

		baseColor = null;
		blinkColor = null;
		colorMatrix = null;

		spr.remove();
		spr = null;

		if( debugLabel!=null ) {
			debugLabel.remove();
			debugLabel = null;
		}

		if( debugBounds!=null ) {
			debugBounds.remove();
			debugBounds = null;
		}

		cd.destroy();
		cd = null;
    }


	/** Print some numeric value below entity **/
	public inline function debugFloat(v:Float, ?c=0xffffff) {
		debug( pretty(v), c );
	}


	/** Print some value below entity **/
	public inline function debug(?v:Dynamic, ?c=0xffffff) {
		#if debug
		if( v==null && debugLabel!=null ) {
			debugLabel.remove();
			debugLabel = null;
		}
		if( v!=null ) {
			if( debugLabel==null ) {
				debugLabel = new h2d.Text(Assets.fontPixel, Game.ME.scroller);
				debugLabel.filter = new dn.heaps.filter.PixelOutline();
			}
			debugLabel.text = Std.string(v);
			debugLabel.textColor = c;
		}
		#end
	}

	/** Hide entity debug bounds **/
	public function disableDebugBounds() {
		if( debugBounds!=null ) {
			debugBounds.remove();
			debugBounds = null;
		}
	}


	/** Show entity debug bounds (position and width/height). Use the `/bounds` command in Console to enable them. **/
	public function enableDebugBounds() {
		if( debugBounds==null ) {
			debugBounds = new h2d.Graphics();
			game.scroller.add(debugBounds, Const.DP_TOP);
		}
		invalidateDebugBounds = true;
	}

	function renderDebugBounds() {
		var c = Color.makeColorHsl((uid%20)/20, 1, 1);
		debugBounds.clear();

		// Bounds rect
		debugBounds.lineStyle(1, c, 0.5);
		debugBounds.drawRect(left-attachX, top-attachY, wid, hei);

		// Attach point
		debugBounds.lineStyle(0);
		debugBounds.beginFill(c,0.8);
		debugBounds.drawRect(-1, -1, 3, 3);
		debugBounds.endFill();

		// Center
		debugBounds.lineStyle(1, c, 0.3);
		debugBounds.drawCircle(centerX-attachX, centerY-attachY, 3);
	}

	/** Wait for `sec` seconds, then runs provided callback. **/
	function chargeAction(id:String, sec:Float, cb:Void->Void) {
		if( !isAlive() )
			return;

		if( isChargingAction(id) )
			cancelAction(id);
		if( sec<=0 )
			cb();
		else
			actions.push({ id:id, cb:cb, t:sec});
	}

	/** If id is null, return TRUE if any action is charging. If id is provided, return TRUE if this specific action is charging nokw. **/
	public function isChargingAction(?id:String) {
		if( !isAlive() )
			return false;

		if( id==null )
			return actions.length>0;

		for(a in actions)
			if( a.id==id )
				return true;

		return false;
	}

	public function cancelAction(?id:String) {
		if( !isAlive() )
			return;

		if( id==null )
			actions = [];
		else {
			var i = 0;
			while( i<actions.length ) {
				if( actions[i].id==id )
					actions.splice(i,1);
				else
					i++;
			}
		}
	}

	/** Action management loop **/
	function updateActions() {
		if( !isAlive() )
			return;

		var i = 0;
		while( i<actions.length ) {
			var a = actions[i];
			a.t -= tmod/Const.FPS;
			if( a.t<=0 ) {
				actions.splice(i,1);
				if( isAlive() )
					a.cb();
			}
			else
				i++;
		}
	}


	public inline function hasAffect(k:Affect) {
		return isAlive() && affects.exists(k) && affects.get(k)>0;
	}

	public inline function getAffectDurationS(k:Affect) {
		return hasAffect(k) ? affects.get(k) : 0.;
	}

	/** Add an Affect. If `allowLower` is TRUE, it is possible to override an existing Affect with a shorter duration. **/
	public function setAffectS(k:Affect, t:Float, ?allowLower=false) {
		if( !isAlive() || affects.exists(k) && affects.get(k)>t && !allowLower )
			return;

		if( t<=0 )
			clearAffect(k);
		else {
			var isNew = !hasAffect(k);
			affects.set(k,t);
			if( isNew )
				onAffectStart(k);
		}
	}

	/** Multiply an Affect duration by a factor `f` **/
	public function mulAffectS(k:Affect, f:Float) {
		if( hasAffect(k) )
			setAffectS(k, getAffectDurationS(k)*f, true);
	}

	public function clearAffect(k:Affect) {
		if( hasAffect(k) ) {
			affects.remove(k);
			onAffectEnd(k);
		}
	}

	/** Affects update loop **/
	function updateAffects() {
		if( !isAlive() )
			return;

		for(k in affects.keys()) {
			var t = affects.get(k);
			t-=1/Const.FPS * tmod;
			if( t<=0 )
				clearAffect(k);
			else
				affects.set(k,t);
		}
	}

	function onAffectStart(k:Affect) {}
	function onAffectEnd(k:Affect) {}

	/** Return TRUE if the entity is active and has no status affect that prevents actions. **/
	public function isConscious() {
		return !hasAffect(Stun) && isAlive();
	}

	/** Blink `spr` briefly (eg. when damaged by something) **/
	public function blink(c:UInt) {
		blinkColor.setColor(c);
		cd.setS("keepBlink",0.06);
	}

	public function shakeS(xPow:Float, yPow:Float, t:Float) {
		cd.setS("shaking", t, true);
		shakePowX = xPow;
		shakePowY = yPow;
	}

	/** Briefly squash sprite on X (Y changes accordingly). "1.0" means no distorsion. **/
	public function setSquashX(scaleX:Float) {
		sprSquashX = scaleX;
		sprSquashY = 2-scaleX;
	}

	/** Briefly squash sprite on Y (X changes accordingly). "1.0" means no distorsion. **/
	public function setSquashY(scaleY:Float) {
		sprSquashX = 2-scaleY;
		sprSquashY = scaleY;
	}


	/**
		"Beginning of the frame" loop, called before any other Entity update loop
	**/
    public function preUpdate() {
		ucd.update(utmod);
		cd.update(tmod);
		updateAffects();
		updateActions();


		#if debug
		// Display the list of active "affects" (with `/set affect` in console)
		if( ui.Console.ME.hasFlag("affect") ) {
			var all = [];
			for(k in affects.keys())
				all.push( k+"=>"+M.pretty( getAffectDurationS(k) , 1) );
			debug(all);
		}

		// Show bounds (with `/bounds` in console)
		if( ui.Console.ME.hasFlag("bounds") && debugBounds==null )
			enableDebugBounds();

		// Hide bounds
		if( !ui.Console.ME.hasFlag("bounds") && debugBounds!=null )
			disableDebugBounds();
		#end

    }

	/**
		Post-update loop, which is guaranteed to happen AFTER any preUpdate/update. This is usually where render and display is updated
	**/
    public function postUpdate() {
		spr.x = sprX;
		spr.y = sprY;
        spr.scaleX = dir*sprScaleX * sprSquashX;
        spr.scaleY = sprScaleY * sprSquashY;
		spr.visible = entityVisible;

		sprSquashX += (1-sprSquashX) * M.fmin(1, 0.2*tmod);
		sprSquashY += (1-sprSquashY) * M.fmin(1, 0.2*tmod);

		if( cd.has("shaking") ) {
			spr.x += Math.cos(ftime*1.1)*shakePowX * cd.getRatio("shaking");
			spr.y += Math.sin(0.3+ftime*1.7)*shakePowY * cd.getRatio("shaking");
		}

		// Blink
		if( !cd.has("keepBlink") ) {
			blinkColor.r*=Math.pow(0.60, tmod);
			blinkColor.g*=Math.pow(0.55, tmod);
			blinkColor.b*=Math.pow(0.50, tmod);
		}

		// Color adds
		spr.colorAdd.load(baseColor);
		spr.colorAdd.r += blinkColor.r;
		spr.colorAdd.g += blinkColor.g;
		spr.colorAdd.b += blinkColor.b;

		// Debug label
		if( debugLabel!=null ) {
			debugLabel.x = Std.int(attachX - debugLabel.textWidth*0.5);
			debugLabel.y = Std.int(attachY+1);
		}

		// Debug bounds
		if( debugBounds!=null ) {
			if( invalidateDebugBounds ) {
				invalidateDebugBounds = false;
				renderDebugBounds();
			}
			debugBounds.x = Std.int(attachX);
			debugBounds.y = Std.int(attachY);
		}
	}

	/**
		Loop that runs at the absolute end of the frame
	**/
	public function finalUpdate() {
		prevFrameattachX = attachX;
		prevFrameattachY = attachY;
	}


	final function updateLastFixedUpdatePos() {
		lastFixedUpdateX = attachX;
		lastFixedUpdateY = attachY;
	}



	/** Called at the beginning of each X movement step **/
	function onPreStepX() {
	}

	/** Called at the beginning of each Y movement step **/
	function onPreStepY() {
	}


	/**
		Main loop, but it only runs at a "guaranteed" 30 fps (so it might not be called during some frames, if the app runs at 60fps). This is usually where most gameplay elements affecting physics should occur, to ensure these will not depend on FPS at all.
	**/
	public function fixedUpdate() {
		updateLastFixedUpdatePos();

		/*
			Stepping: any movement greater than 33% of grid size (ie. 0.33) will increase the number of `steps` here. These steps will break down the full movement into smaller iterations to avoid jumping over grid collisions.
		*/
		var steps = M.ceil( ( M.fabs(dxTotal) + M.fabs(dyTotal) ) / 0.33 );
		if( steps>0 ) {
			var n = 0;
			while ( n<steps ) {
				// X movement
				xr += dxTotal / steps;
				
				if( dxTotal!=0 )
					onPreStepX(); // <---- Add X collisions checks and physics in here

				while( xr>1 ) { xr--; cx++; }
				while( xr<0 ) { xr++; cx--; }


				// Y movement
				yr += dyTotal / steps;

				if( dyTotal!=0 )
					onPreStepY(); // <---- Add Y collisions checks and physics in here

				while( yr>1 ) { yr--; cy++; }
				while( yr<0 ) { yr++; cy--; }

				n++;
			}
		}

		// X frictions
		dx *= frictX;
		bdx *= bumpFrictX;
		if( M.fabs(dx) <= 0.0005 ) dx = 0;
		if( M.fabs(bdx) <= 0.0005 ) bdx = 0;

		// Y frictions
		dy *= frictY;
		bdy *= bumpFrictY;
		if( M.fabs(dy) <= 0.0005 ) dy = 0;
		if( M.fabs(bdy) <= 0.0005 ) bdy = 0;
	}


	/**
		Main loop running at full FPS
	**/
    public function update() {
    }
}