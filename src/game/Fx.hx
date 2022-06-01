import h2d.Sprite;
import dn.heaps.HParticle;


class Fx extends GameProcess {
	var pool : ParticlePool;

	public var bg_add    : h2d.SpriteBatch;
	public var bg_normal    : h2d.SpriteBatch;
	public var main_add       : h2d.SpriteBatch;
	public var main_normal    : h2d.SpriteBatch;

	public function new() {
		super();

		pool = new ParticlePool(Assets.tiles.tile, 2048, Const.FPS);

		bg_add = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(bg_add, Const.DP_FX_BG);
		bg_add.blendMode = Add;
		bg_add.hasRotationScale = true;

		bg_normal = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(bg_normal, Const.DP_FX_BG);
		bg_normal.hasRotationScale = true;

		main_normal = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(main_normal, Const.DP_FX_FRONT);
		main_normal.hasRotationScale = true;

		main_add = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(main_add, Const.DP_FX_FRONT);
		main_add.blendMode = Add;
		main_add.hasRotationScale = true;
	}

	override public function onDispose() {
		super.onDispose();

		pool.dispose();
		bg_add.remove();
		bg_normal.remove();
		main_add.remove();
		main_normal.remove();
	}

	/** Clear all particles **/
	public function clear() {
		pool.clear();
	}

	/** Create a HParticle instance in the BG layer, using ADDITIVE blendmode **/
	public inline function allocBg_add(id,x,y) return pool.alloc(bg_add, Assets.tiles.getTileRandom(id), x, y);

	/** Create a HParticle instance in the BG layer, using NORMAL blendmode **/
	public inline function allocBg_normal(id,x,y) return pool.alloc(bg_normal, Assets.tiles.getTileRandom(id), x, y);

	/** Create a HParticle instance in the MAIN layer, using ADDITIVE blendmode **/
	public inline function allocMain_add(id,x,y) return pool.alloc( main_add, Assets.tiles.getTileRandom(id), x, y );

	/** Create a HParticle instance in the MAIN layer, using NORMAL blendmode **/
	public inline function allocMain_normal(id,x,y) return pool.alloc(main_normal, Assets.tiles.getTileRandom(id), x, y);


	public inline function markerEntity(e:Entity, c:Col=Pink, short=false) {
		#if debug
		if( e!=null && e.isAlive() )
			markerCase(e.cx, e.cy, short?0.03:3, c);
		#end
	}

	public inline function markerCase(cx:Int, cy:Int, sec=3.0, c:Col=Pink) {
		#if debug
		var p = allocMain_add(D.tiles.fxCircle15, (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.lifeS = sec;

		var p = allocMain_add(D.tiles.pixel, (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(2);
		p.lifeS = sec;
		#end
	}

	public inline function markerFree(x:Float, y:Float, sec=3.0, c:Col=Pink) {
		#if debug
		var p = allocMain_add(D.tiles.fxDot, x,y);
		p.setCenterRatio(0.5,0.5);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(3);
		p.lifeS = sec;
		#end
	}

	public inline function markerText(cx:Int, cy:Int, txt:String, t=1.0) {
		#if debug
		var tf = new h2d.Text(Assets.fontPixel, main_normal);
		tf.text = txt;

		var p = allocMain_add(D.tiles.fxCircle15, (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.colorize(0x0080FF);
		p.alpha = 0.6;
		p.lifeS = 0.3;
		p.fadeOutSpeed = 0.4;
		p.onKill = tf.remove;

		tf.setPosition(p.x-tf.textWidth*0.5, p.y-tf.textHeight*0.5);
		#end
	}

	inline function collides(p:HParticle, offX=0., offY=0.) {
		return level.hasCollision( Std.int((p.x+offX)/Const.GRID), Std.int((p.y+offY)/Const.GRID) );
	}

	public inline function flashBangS(c:Col, a:Float, t=0.1) {
		var e = new h2d.Bitmap(h2d.Tile.fromColor(c,1,1,a));
		game.root.add(e, Const.DP_FX_FRONT);
		e.scaleX = game.w();
		e.scaleY = game.h();
		e.blendMode = Add;
		game.tw.createS(e.alpha, 0, t).end( function() {
			e.remove();
		});
	}


	/**
		A small sample to demonstrate how basic particles work. This example produces a small explosion of yellow dots that will fall and slowly fade to purple.

		USAGE: fx.dotsExplosionExample(50,50, 0xffcc00)
	**/
	public inline function dotsExplosionExample(x:Float, y:Float, color:Col) {
		for(i in 0...80) {
			var p = allocMain_add( D.tiles.fxDot, x+rnd(0,3,true), y+rnd(0,3,true) );
			p.alpha = rnd(0.4,1);
			p.colorAnimS(color, 0x762087, rnd(0.6, 3)); // fade particle color from given color to some purple
			p.moveAwayFrom(x,y, rnd(1,3)); // move away from source
			p.frict = rnd(0.8, 0.9); // friction applied to velocities
			p.gy = rnd(0, 0.02); // gravity Y (added on each frame)
			p.lifeS = rnd(2,3); // life time in seconds
		}
	}


	override function update() {
		super.update();
		pool.update(game.tmod);
	}
}