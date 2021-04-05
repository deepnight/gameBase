package gm;

class Entity {
    public static var ALL : Array<Entity> = [];
    public static var GC : Array<Entity> = [];

	// Various getters to access all important stuff easily
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

	// Uncontrollable bump velocities, usually applied by external
	// factors (think of a bumper in Sonic for example)
    public var bdx = 0.;
	public var bdy = 0.;

	// Velocities + bump velocities
	public var dxTotal(get,never) : Float; inline function get_dxTotal() return dx+bdx;
	public var dyTotal(get,never) : Float; inline function get_dyTotal() return dy+bdy;

	/** Multiplier applied on each frame to normal X velocity **/
	public var frictX = 0.82;
	/** Multiplier applied on each frame to normal Y velocity **/
	public var frictY = 0.82;

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

	/** Sprite X scaling **/
	public var sprScaleX = 1.0;
	/** Sprite Y scaling **/
	public var sprScaleY = 1.0;
	/** Sprite X squash & stretch scaling, which automatically comes back to 1 after a few frames **/
	var sprSquashX = 1.0;
	/** Sprite Y squash & stretch scaling, which automatically comes back to 1 after a few frames **/
	var sprSquashY = 1.0;

	/** Entity visibility **/
	public var entityVisible = true;

	// Hit points
	public var life(default,null) : Int;
	public var maxLife(default,null) : Int;
	public var lastDmgSource(default,null) : Null<Entity>;

	public var lastHitDirFromSource(get,never) : Int;
	inline function get_lastHitDirFromSource() return lastDmgSource==null ? -dir : -dirTo(lastDmgSource);

	public var lastHitDirToSource(get,never) : Int;
	inline function get_lastHitDirToSource() return lastDmgSource==null ? dir : dirTo(lastDmgSource);

	// Visual components
    public var spr : HSprite;
	public var baseColor : h3d.Vector;
	public var blinkColor : h3d.Vector;
	public var colorMatrix : h3d.Matrix;

	// Debug stuff
	var debugLabel : Null<h2d.Text>;
	var debugBounds : Null<h2d.Graphics>;
	var invalidateDebugBounds = false;

	/** Defines X alignment of entity at its attach point (0 to 1.0) **/
	public var pivotX(default,set) : Float = 0.5;
	/** Defines Y alignment of entity at its attach point (0 to 1.0) **/
	public var pivotY(default,set) : Float = 1;

	/** Entity attach X pixel coordinate **/
	public var attachX(get,never) : Float; inline function get_attachX() return (cx+xr)*Const.GRID;
	/** Entity attach Y pixel coordinate **/
	public var attachY(get,never) : Float; inline function get_attachY() return (cy+yr)*Const.GRID;

	// Coordinates getters, for easier gameplay coding
	public var left(get,never) : Float; inline function get_left() return attachX + (0-pivotX) * wid;
	public var right(get,never) : Float; inline function get_right() return attachX + (1-pivotX) * wid;
	public var top(get,never) : Float; inline function get_top() return attachY + (0-pivotY) * hei;
	public var bottom(get,never) : Float; inline function get_bottom() return attachY + (1-pivotY) * hei;
	public var centerX(get,never) : Float; inline function get_centerX() return attachX + (0.5-pivotX) * wid;
	public var centerY(get,never) : Float; inline function get_centerY() return attachY + (0.5-pivotY) * hei;
	public var prevFrameattachX : Float = -Const.INFINITE;
	public var prevFrameattachY : Float = -Const.INFINITE;

	var actions : Array<{ id:String, cb:Void->Void, t:Float }> = [];

    public function new(x:Int, y:Int) {
        uid = Const.NEXT_UNIQ;
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

	public function initLife(v) {
		life = maxLife = v;
	}

	public function hit(dmg:Int, from:Null<Entity>) {
		if( !isAlive() || dmg<=0 )
			return;

		life = M.iclamp(life-dmg, 0, maxLife);
		lastDmgSource = from;
		onDamage(dmg, from);
		if( life<=0 )
			onDie();
	}

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

	function onPosManuallyChanged() {
		if( M.dist(attachX,attachY,prevFrameattachX,prevFrameattachY) > Const.GRID*2 ) {
			prevFrameattachX = attachX;
			prevFrameattachY = attachY;
		}
	}

	/** Quickly set X/Y pivots. If Y is omitted, it will be equal to X. **/
	public function setPivots(x:Float, ?y:Float) {
		pivotX = x;
		pivotY = y!=null ? y : x;
	}


	public function bump(x:Float,y:Float) {
		bdx+=x;
		bdy+=y;
	}

	/** Reset velocities to zero **/
	public function cancelVelocities() {
		dx = bdx = 0;
		dy = bdy = 0;
	}

	public function is<T:Entity>(c:Class<T>) return Std.isOfType(this, c);
	public function as<T:Entity>(c:Class<T>) : T return Std.downcast(this, c);

	public inline function rnd(min,max,?sign) return Lib.rnd(min,max,sign);
	public inline function irnd(min,max,?sign) return Lib.irnd(min,max,sign);
	public inline function pretty(v,?p=1) return M.pretty(v,p);

	public inline function dirTo(e:Entity) return e.centerX<centerX ? -1 : 1;
	public inline function dirToAng() return dir==1 ? 0. : M.PI;
	public inline function getMoveAng() return Math.atan2(dyTotal,dxTotal);

	public inline function distCase(e:Entity) return M.dist(cx+xr, cy+yr, e.cx+e.xr, e.cy+e.yr);
	public inline function distCaseFree(tcx:Int, tcy:Int, ?txr=0.5, ?tyr=0.5) return M.dist(cx+xr, cy+yr, tcx+txr, tcy+tyr);

	public inline function distPx(e:Entity) return M.dist(attachX, attachY, e.attachX, e.attachY);
	public inline function distPxFree(x:Float, y:Float) return M.dist(attachX, attachY, x, y);

	function canSeeThrough(cx:Int, cy:Int) {
		return !level.hasCollision(cx,cy) || this.cx==cx && this.cy==cy;
	}

	public inline function sightCheckCase(tcx:Int, tcy:Int) {
		return dn.Bresenham.checkThinLine(cx,cy,tcx,tcy, canSeeThrough);
	}

	public inline function sightCheckEntity(e:Entity) {
		return dn.Bresenham.checkThinLine(cx,cy,e.cx,e.cy, canSeeThrough);
	}

	public inline function createPoint() return LPoint.fromCase(cx+xr,cy+yr);

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
			if( debugLabel==null )
				debugLabel = new h2d.Text(Assets.fontTiny, Game.ME.scroller);
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
		if( isChargingAction(id) )
			cancelAction(id);
		if( sec<=0 )
			cb();
		else
			actions.push({ id:id, cb:cb, t:sec});
	}

	/** If id is null, return TRUE if any action is charging. If id is provided, return TRUE if this specific action is charging nokw. **/
	public function isChargingAction(?id:String) {
		if( id==null )
			return actions.length>0;

		for(a in actions)
			if( a.id==id )
				return true;

		return false;
	}

	public function cancelAction(?id:String) {
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
		return affects.exists(k) && affects.get(k)>0;
	}

	public inline function getAffectDurationS(k:Affect) {
		return hasAffect(k) ? affects.get(k) : 0.;
	}

	/** Add an Affect. If `allowLower` is TRUE, it is possible to override an existing Affect with a shorter duration. **/
	public function setAffectS(k:Affect, t:Float, ?allowLower=false) {
		if( affects.exists(k) && affects.get(k)>t && !allowLower )
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

	/** "Beginning of the frame" loop **/
    public function preUpdate() {
		ucd.update(utmod);
		cd.update(tmod);
		updateAffects();
		updateActions();
    }

	/** Post-update loop, usually used for anything "render" related **/
    public function postUpdate() {
        spr.x = (cx+xr)*Const.GRID;
        spr.y = (cy+yr)*Const.GRID;
        spr.scaleX = dir*sprScaleX * sprSquashX;
        spr.scaleY = sprScaleY * sprSquashY;
		spr.visible = entityVisible;

		sprSquashX += (1-sprSquashX) * M.fmin(1, 0.2*tmod);
		sprSquashY += (1-sprSquashY) * M.fmin(1, 0.2*tmod);

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

	/** Loop that runs at the end of the frame **/
	public function finalUpdate() {
		prevFrameattachX = attachX;
		prevFrameattachY = attachY;
	}

	/** Main loop that only runs at 30 fps (so it might not be called during some frames) **/
	public function fixedUpdate() {}

	/** Main loop **/
    public function update() {
		// X
		var steps = M.ceil( M.fabs(dxTotal*tmod) );
		var step = dxTotal*tmod / steps;
		while( steps>0 ) {
			xr+=step;

			// [ add X collisions checks here ]

			while( xr>1 ) { xr--; cx++; }
			while( xr<0 ) { xr++; cx--; }
			steps--;
		}
		dx*=Math.pow(frictX,tmod);
		bdx*=Math.pow(bumpFrictX,tmod);
		if( M.fabs(dx)<=0.0005*tmod ) dx = 0;
		if( M.fabs(bdx)<=0.0005*tmod ) bdx = 0;

		// Y
		var steps = M.ceil( M.fabs(dyTotal*tmod) );
		var step = dyTotal*tmod / steps;
		while( steps>0 ) {
			yr+=step;

			// [ add Y collisions checks here ]

			while( yr>1 ) { yr--; cy++; }
			while( yr<0 ) { yr++; cy--; }
			steps--;
		}
		dy*=Math.pow(frictY,tmod);
		bdy*=Math.pow(bumpFrictX,tmod);
		if( M.fabs(dy)<=0.0005*tmod ) dy = 0;
		if( M.fabs(bdy)<=0.0005*tmod ) bdy = 0;


		#if debug
		if( ui.Console.ME.hasFlag("affect") ) {
			var all = [];
			for(k in affects.keys())
				all.push( k+"=>"+M.pretty( getAffectDurationS(k) , 1) );
			debug(all);
		}

		if( ui.Console.ME.hasFlag("bounds") && debugBounds==null )
			enableDebugBounds();

		if( !ui.Console.ME.hasFlag("bounds") && debugBounds!=null )
			disableDebugBounds();
		#end
    }
}