import mt.MLib;
import mt.deepnight.Lib;
import mt.heaps.slib.*;

class Entity {
    public static var ALL : Array<Entity> = [];
    public static var GC : Array<Entity> = [];

	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;
	public var destroyed(default,null) = false;
	public var ftime(get,never) : Float; inline function get_ftime() return game.ftime;
	public var cd : mt.Cooldown;
	public var tmod : Float;

	public var uid : Int;
    public var cx = 0;
    public var cy = 0;
    public var xr = 0.5;
    public var yr = 1.0;

    public var dx = 0.;
    public var dy = 0.;
	public var frict = 0.82;
	public var gravity = 0.024;
	public var hasGravity = true;
	public var weight = 1.;
	public var hei : Float = Const.GRID;
	public var radius = Const.GRID*0.5;
	public var lifter = false;

	public var dir(default,set) = 1;
	public var hasColl = true;
	public var isAffectBySlowMo = true;
	public var lastHitDir = 0;
	public var sprScaleX = 1.0;
	public var sprScaleY = 1.0;

    public var spr : HSprite;

	public var footX(get,never) : Float; inline function get_footX() return (cx+xr)*Const.GRID;
	public var footY(get,never) : Float; inline function get_footY() return (cy+yr)*Const.GRID;
	public var headX(get,never) : Float; inline function get_headX() return (cx+xr)*Const.GRID;
	public var headY(get,never) : Float; inline function get_headY() return (cy+yr)*Const.GRID-hei;
	public var centerX(get,never) : Float; inline function get_centerX() return footX;
	public var centerY(get,never) : Float; inline function get_centerY() return footY-hei*0.5;

    public function new(x:Int, y:Int) {
        uid = Const.NEXT_UNIQ;
        ALL.push(this);

		cd = new mt.Cooldown(Const.FPS);
        setPosCase(x,y);

        spr = new HSprite();
        Game.ME.root.add(spr, Const.DP_MAIN);
		spr.setCenterRatio(0.5,1);
    }

	inline function set_dir(v) {
		return dir = v>0 ? 1 : v<0 ? -1 : dir;
	}

	public inline function isAlive() {
		return !destroyed;
	}

	public function kill(by:Null<Entity>) {
		destroy();
	}

	public function setPosCase(x:Int, y:Int) {
		cx = x;
		cy = y;
		xr = 0.5;
		yr = 1;
	}

	public function setPosPixel(x:Float, y:Float) {
		cx = Std.int(x/Const.GRID);
		cy = Std.int(y/Const.GRID);
		xr = (x-cx*Const.GRID)/Const.GRID;
		yr = (y-cy*Const.GRID)/Const.GRID;
	}

	public function is<T:Entity>(c:Class<T>) return Std.is(this, c);
	public function as<T:Entity>(c:Class<T>) : T return Std.instance(this, c);

	public inline function rnd(min,max,?sign) return Lib.rnd(min,max,sign);
	public inline function irnd(min,max,?sign) return Lib.irnd(min,max,sign);
	public inline function pretty(v,?p=1) return Lib.prettyFloat(v,p);

	public inline function dirTo(e:Entity) return e.centerX<centerX ? -1 : 1;

	public inline function distCase(e:Entity) {
		return Lib.distance(cx+xr, cy+yr, e.cx+e.xr, e.cy+e.yr);
	}

	public inline function distPx(e:Entity) {
		return Lib.distance(footX, footY, e.footX, e.footY);
	}

	public inline function distPxFree(x:Float, y:Float) {
		return Lib.distance(footX, footY, x, y);
	}

    public inline function destroy() {
        if( !destroyed ) {
            destroyed = true;
            GC.push(this);
        }
    }

    public function dispose() {
        ALL.remove(this);

		spr.remove();
		spr = null;

		cd.destroy();
		cd = null;
    }

    public function preUpdate(tmod:Float) {
        this.tmod = tmod;
		cd.update(tmod);
    }

    public function postUpdate() {
        spr.x = (cx+xr)*Const.GRID;
        spr.y = (cy+yr)*Const.GRID;
        spr.scaleX = dir*sprScaleX;
        spr.scaleY = sprScaleY;
    }


    public function update() {
		// X
		var steps = MLib.ceil( MLib.fabs(dx*tmod) );
		var step = dx*tmod / steps;
		while( steps>0 ) {
			xr+=step;
			while( xr>1 ) { xr--; cx++; }
			while( xr<0 ) { xr++; cx--; }
			steps--;
		}
		dx*=Math.pow(frict,tmod);
		if( MLib.fabs(dx)<=0.0005*tmod )
			dx = 0;

		// Y
		var steps = MLib.ceil( MLib.fabs(dy*tmod) );
		var step = dy*tmod / steps;
		while( steps>0 ) {
			yr+=step;
			while( yr>1 ) { yr--; cy++; }
			while( yr<0 ) { yr++; cy--; }
			steps--;
		}
		dy*=Math.pow(frict,tmod);
		if( MLib.fabs(dy)<=0.0005*tmod )
			dy = 0;
    }
}