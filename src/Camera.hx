class Camera extends dn.Process {
	public var target : Null<Entity>;
	public var pos : LPoint;
	public var dx : Float;
	public var dy : Float;
	public var wid(get,never) : Int;
	public var hei(get,never) : Int;
	var bumpOffX = 0.;
	var bumpOffY = 0.;

	public function new() {
		super(Game.ME);
		pos = LPoint.fromCase(0,0);
		dx = dy = 0;
	}

	function get_wid() {
		return M.ceil( Game.ME.w() / Const.SCALE );
	}

	function get_hei() {
		return M.ceil( Game.ME.h() / Const.SCALE );
	}

	public function trackTarget(e:Entity, immediate:Bool) {
		target = e;
		if( immediate )
			recenter();
	}

	public inline function stopTracking() {
		target = null;
	}

	public function recenter() {
		if( target!=null ) {
			pos.levelX = target.centerX;
			pos.levelY = target.centerY;
		}
	}

	public inline function scrollerToGlobalX(v:Float) return v*Const.SCALE + Game.ME.scroller.x;
	public inline function scrollerToGlobalY(v:Float) return v*Const.SCALE + Game.ME.scroller.y;

	var shakePower = 1.0;
	public function shakeS(t:Float, ?pow=1.0) {
		cd.setS("shaking", t, false);
		shakePower = pow;
	}

	override function update() {
		super.update();

		// Follow target entity
		if( target!=null ) {
			var s = 0.006;
			var deadZone = 5;
			var tx = target.footX;
			var ty = target.footY;

			var d = pos.distPx(tx,ty);
			// var d = M.dist(x,y, tx, ty);
			if( d>=deadZone ) {
				var a = pos.angTo(tx,ty);
				dx += Math.cos(a) * (d-deadZone) * s * tmod;
				dy += Math.sin(a) * (d-deadZone) * s * tmod;
			}
		}

		var frict = 0.89;
		pos.levelX += dx*tmod;
		dx *= Math.pow(frict,tmod);

		pos.levelY += dy*tmod;
		dy *= Math.pow(frict,tmod);
	}

	public inline function bumpAng(a, dist) {
		bumpOffX+=Math.cos(a)*dist;
		bumpOffY+=Math.sin(a)*dist;
	}

	public inline function bump(x,y) {
		bumpOffX+=x;
		bumpOffY+=y;
	}


	override function postUpdate() {
		super.postUpdate();

		if( !ui.Console.ME.hasFlag("scroll") ) {
			var level = Game.ME.level;
			var scroller = Game.ME.scroller;

			// Update scroller
			if( wid<level.wid*Const.GRID)
				scroller.x = -pos.levelX + wid*0.5;
			else
				scroller.x = wid*0.5 - level.wid*0.5*Const.GRID;
			if( hei<level.hei*Const.GRID)
				scroller.y = -pos.levelY + hei*0.5;
			else
				scroller.y = hei*0.5 - level.hei*0.5*Const.GRID;

			// Clamp
			if( wid<level.wid*Const.GRID)
				scroller.x = M.fclamp(scroller.x, wid-level.wid*Const.GRID, 0);
			if( hei<level.hei*Const.GRID)
				scroller.y = M.fclamp(scroller.y, hei-level.hei*Const.GRID, 0);

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
	}
}