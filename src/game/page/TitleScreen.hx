package page;

import dn.heaps.HParticle;

class TitleScreen extends AppChildProcess {
	var ca : ControllerAccess<GameAction>;
	var bgCol : h2d.Bitmap;
	var bg : h2d.Bitmap;
	var box : h2d.Bitmap;
	var logo : h2d.Bitmap;
	var pressStart : h2d.Text;
	var cm : dn.Cinematic;

	var pool : dn.heaps.HParticle.ParticlePool;
	var fxAdd : h2d.SpriteBatch;
	var fxNormal : h2d.SpriteBatch;
	var upscale = 1.;

	public function new() {
		super();

		fadeIn();

		pool = new dn.heaps.HParticle.ParticlePool(Assets.tiles.tile, 2048, Const.FPS);

		cm = new dn.Cinematic(Const.FPS);
		ca = App.ME.controller.createAccess();

		bgCol = new h2d.Bitmap( h2d.Tile.fromColor(Col.inlineHex("#24223d")) );
		root.add(bgCol, Const.DP_MAIN);

		bg = new h2d.Bitmap( hxd.Res.atlas.title.bg.toTile() );
		root.add(bg, Const.DP_MAIN);
		bg.tile.setCenterRatio();

		box = new h2d.Bitmap( hxd.Res.atlas.title.box.toTile() );
		box.tile.setCenterRatio();
		root.add(box, Const.DP_MAIN);

		logo = new h2d.Bitmap( hxd.Res.atlas.title.logo.toTile() );
		logo.tile.setCenterRatio();
		root.add(logo, Const.DP_MAIN);

		fxNormal = new h2d.SpriteBatch(Assets.tiles.tile);
		root.add(fxNormal, Const.DP_FX_FRONT);
		fxNormal.hasRotationScale = true;

		fxAdd = new h2d.SpriteBatch(Assets.tiles.tile);
		root.add(fxAdd, Const.DP_FX_FRONT);
		fxAdd.blendMode = Add;
		fxAdd.hasRotationScale = true;

		pressStart = new h2d.Text(Assets.fontPixel);
		root.add(pressStart, Const.DP_FX_FRONT);
		pressStart.text = "Press any key";

		run();
	}

	var ready = true;
	function run() {
		onResize();
		var s = upscale;
		pressStart.alpha = 0;
		bg.scale(0.94);
		bg.alpha = 0;
		box.alpha = 0;
		box.colorAdd = new h3d.Vector();
		box.colorAdd.r = 0.5;
		box.colorAdd.g = 1;
		box.colorAdd.b = 1;
		logo.colorAdd = new h3d.Vector();
		logo.colorAdd.r = 0;
		logo.colorAdd.g = -1;
		logo.colorAdd.b = -1;
		logo.alpha = 0;
		var appearSfx = S.exp02();
		cm.create({
			700;
			tw.createS(bg.scaleX, s, 1);
			tw.createS(bg.scaleY, s, 1);
			tw.createS(bg.alpha, 1, 1);
			700;
			box.alpha = 1;
			box.scale(2);
			150 >> shake(0.4);
			150 >> appearSfx.play(1);
			tw.createS(box.scaleX, s, 0.15);
			tw.createS(box.scaleY, s, 0.15);
			tw.createS(box.colorAdd.r, 0, 0.5);
			tw.createS(box.colorAdd.g, 0, 0.2);
			tw.createS(box.colorAdd.b, 0, 0.4);
			200;
			tw.createS(logo.alpha, 1, 0.3);
			tw.createS(pressStart.alpha, 1, 1);
			200;
			ready = true;
			tw.createS(logo.colorAdd.r, 0, 0.5);
			tw.createS(logo.colorAdd.g, 0, 0.2);
			tw.createS(logo.colorAdd.b, 0, 0.4);
		});
	}

	function shake(t) {
		cd.setS("shake",t);
	}

	override function preUpdate() {
		super.preUpdate();
		cm.update(tmod);
		pool.update(tmod);
	}

	override function onResize() {
		super.onResize();

		bgCol.scaleX = w();
		bgCol.scaleY = h();

		upscale = dn.heaps.Scaler.bestFit_i(box.tile.height, box.tile.height); // only height matters
		box.setScale(upscale);
		bg.setScale(upscale);
		logo.setScale(upscale);

		fxAdd.setScale(upscale);
		fxNormal.setScale(upscale);

		pressStart.setScale(upscale);
		pressStart.setPosition( Std.int( w()*0.5-pressStart.textWidth*0.5*pressStart.scaleX ), Std.int( h()*0.82-pressStart.textHeight*0.5*pressStart.scaleY ) );

		box.setPosition( Std.int( w()*0.5 ), Std.int( h()*0.5 ) );
		bg.setPosition( Std.int( w()*0.5 ), Std.int( h()*0.5 ) );
		logo.setPosition( Std.int( w()*0.5 ), Std.int( h()*0.5 ) );
	}

	inline function allocAdd(id:String, x:Float, y:Float) : HParticle {
		return pool.alloc( fxAdd, Assets.tiles.getTile(id), x, y );
	}
	inline function allocNormal(id:String, x:Float, y:Float) : HParticle {
		return pool.alloc( fxNormal, Assets.tiles.getTile(id), x, y );
	}
	override function postUpdate() {
		super.postUpdate();

		if( cd.has("shake") ) {
			var r = cd.getRatio("shake");
			root.y = Math.sin(ftime*10)*r*2*Const.SCALE;
		}
		else
			root.y = 0;

		pressStart.visible = Std.int( stime/0.25 ) % 2 == 0;

		if( ready && !cd.hasSetS("fx",0.03) ) {
			var w = w()/upscale;
			var h = h()/upscale;
			// Black smoke
			for(i in 0...4) {
				var xr = rnd(0,1);
				var p = allocNormal(R.pct(70)?D.tiles.fxDirt:D.tiles.fxSmoke, w*xr, h+rnd(0,10,true)-rnd(0,xr*70) );
				p.setFadeS(rnd(0.1, 0.35), 1, rnd(1,2) );
				p.colorize( Assets.dark() );
				p.rotation = R.fullCircle();
				p.setScale(rnd(3,4,true));
				p.gy = -R.around(0.02);
				p.gx = rnd(0, 0.01);
				p.frict = R.aroundBO(0.9, 5);
				p.lifeS = rnd(1,3);
			}
			for(i in 0...1) {
				var xr = rnd(0,1);
				var p = allocAdd(D.tiles.fxSmoke, w*xr, h+30-rnd(0,40,true)-rnd(0,xr*50) );
				p.setFadeS(rnd(0.04, 0.10), 1, rnd(1,2) );
				p.colorize( Assets.blue() );
				p.rotation = R.fullCircle();
				p.setScale(rnd(2,3,true));
				p.gy = -R.around(0.01);
				p.gx = rnd(0, 0.01);
				p.frict = R.aroundBO(0.9, 5);
				p.lifeS = rnd(1,2);
			}
			for(i in 0...4) {
				var p = allocAdd(D.tiles.pixel, rnd(0,w*0.8), rnd(0,h*0.7) );
				p.setFadeS(rnd(0.2, 0.5), 1, rnd(1,2) );
				p.colorAnimS( Col.inlineHex("#ff6900"), Assets.dark(), rnd(1,3) );
				p.alphaFlicker = rnd(0.2,0.5);
				p.setScale(irnd(1,2));
				p.dr = rnd(0,0.1,true);
				p.gx = rnd(0, 0.03);
				p.gy = rnd(-0.02, 0.08);
				p.dx = rnd(0,1);
				// p.dy = rnd(0,1,true);
				p.frict = R.aroundBO(0.98, 5);
				p.lifeS = rnd(1,2);
			}
		}
	}

	function skip() {
		S.__samsterbirdies__sword_draw_unsheathe(1);
		shake(0.1);
		box.colorAdd.r = box.colorAdd.g = box.colorAdd.b = 1;
		logo.colorAdd.r = logo.colorAdd.g = logo.colorAdd.b = 1;

		var s = 0.2*upscale;
		createChildProcess( (p)->{
			box.colorAdd.r *= 0.93;
			box.colorAdd.g *= 0.7;
			box.colorAdd.b *= 0.7;

			logo.colorAdd.r *= 0.99;
			logo.colorAdd.g *= 0.94;
			logo.colorAdd.b *= 0.94;

			box.setScale(upscale+s);
			logo.setScale(upscale+s);
			s*=0.9;
		});

		fadeOut( 1, ()->{
			App.ME.startGame();
			destroy();
		});
	}

	override function onDispose() {
		super.onDispose();
		ca.dispose();
	}

	override function update() {
		super.update();

		if( ca.isKeyboardPressed(K.ESCAPE) ) {
			App.ME.exit();
		}
		else if( ca.anyStandardContinuePressed() ) {
			ca.lock();
			skip();
		}

		#if debug
		if( ca.isKeyboardPressed(K.R) )
			run();
		#end
	}
}