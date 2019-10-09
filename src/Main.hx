import Data;
import hxd.Key;

class Main extends dn.Process {
	public static var ME : Main;
	public var controller : dn.heaps.Controller;
	public var ca : dn.heaps.Controller.ControllerAccess;

	public function new(s:h2d.Scene) {
		super();
		ME = this;

        createRoot(s);
        root.filter = new h2d.filter.ColorMatrix(); // force rendering for pixel perfect

		// Engine settings
		hxd.Timer.wantedFPS = Const.FPS;
		engine.backgroundColor = 0xff<<24|0x111133;
        #if( hl && !debug )
        engine.fullScreen = true;
        #end

		// Resources
		#if debug
		hxd.Res.initLocal();
        #else
        hxd.Res.initEmbed({compressSounds:true});
        #end

        // Hot reloading
		#if debug
        hxd.res.Resource.LIVE_UPDATE = true;
        hxd.Res.data.watch(function() {
            delayer.cancelById("cdb");

            delayer.addS("cdb", function() {
            	Data.load( hxd.Res.data.entry.getBytes().toString() );
            	if( Game.ME!=null )
                    Game.ME.onCdbReload();
            }, 0.2);
        });
		#end

		// Assets & data init
		Lang.init("en");
		Assets.init();
		Data.load( hxd.Res.data.entry.getText() );

		// Console
		new ui.Console(Assets.fontTiny, s);

		// Game controller
		controller = new dn.heaps.Controller(s);
		ca = controller.createAccess("main");
		controller.bind(AXIS_LEFT_X_NEG, Key.LEFT, Key.Q, Key.A);
		controller.bind(AXIS_LEFT_X_POS, Key.RIGHT, Key.D);
		controller.bind(X, Key.SPACE, Key.F, Key.E);
		controller.bind(A, Key.UP, Key.Z, Key.W);
		controller.bind(B, Key.ENTER, Key.NUMPAD_ENTER);
		controller.bind(SELECT, Key.R);
		controller.bind(START, Key.N);

		// Start
		new dn.heaps.GameFocusHelper(Boot.ME.s2d, Assets.fontMedium);
		delayer.addF( startGame, 1 );

		// Enable fullscreen support (HL & JS targets)
		enableFullscreen(Key.F, true);
	}

	var fullscreenEnabled = false;
	public function enableFullscreen(?alternativeKey:Int, button:Bool) {
		if( fullscreenEnabled )
			return;

		fullscreenEnabled = true;

		#if js

		var elem = js.Browser.document.getElementById("webgl");

		if( button ) {
			var w = 24;
			var g = new h2d.Graphics(Boot.ME.s2d);
			g.alpha = 0.7;
			g.blendMode = None;
			g.beginFill(0x0,1);
			g.drawRect(0,0,w,w);
			g.endFill();

			g.lineStyle(2,0xffffff,1);
			g.moveTo(w*0.1, w*0.3);
			g.lineTo(w*0.1, w*0.1);
			g.lineTo(w*0.3, w*0.1);
			g.moveTo(w*0.1,w*0.1);
			g.lineTo(w*0.35, w*0.35);

			g.moveTo(w*0.7, w*0.1);
			g.lineTo(w*0.9, w*0.1);
			g.lineTo(w*0.9, w*0.3);
			g.moveTo(w*0.9,w*0.1);
			g.lineTo(w*0.65, w*0.35);

			g.moveTo(w*0.9, w*0.7);
			g.lineTo(w*0.9, w*0.9);
			g.lineTo(w*0.7, w*0.9);
			g.moveTo(w*0.9,w*0.9);
			g.lineTo(w*0.65, w*0.65);

			g.moveTo(w*0.1, w*0.7);
			g.lineTo(w*0.1, w*0.9);
			g.lineTo(w*0.3, w*0.9);
			g.moveTo(w*0.1,w*0.9);
			g.lineTo(w*0.35, w*0.65);

			elem.addEventListener( "click", function(e) {
				var x = e.pageX - elem.offsetLeft;
				var y = e.pageY - elem.offsetTop;
				if( !isFullscreen() && x>=g.x && x<g.x+w && y>=g.y && y<g.y+w )
					toggleFullscreen();
			});

			createChildProcess( function(_) {
				g.x = this.w()-w-2;
				g.y = 2;
				g.visible = !isFullscreen();
			});
		}

		elem.addEventListener("keydown",function(e) {
			if( alternativeKey!=null && e.keyCode==alternativeKey || e.keyCode==Key.ENTER && e.altKey )
				toggleFullscreen();
		});

		#elseif hl

		createChildProcess( function(_) {
			if( alternativeKey!=null && Key.isPressed(alternativeKey) )
				toggleFullscreen();
		});

		#end
	}

	public inline function isFullscreen() {
		#if js
		return (cast js.Browser.document).fullscreen;
		#elseif hl
		return engine.fullScreen;
		#else
		return false;
		#end
	}
	public function toggleFullscreen() {
		#if js
		if( isFullscreen() )
			(cast js.Browser.document).exitFullscreen();
		else
			(cast js.Browser.document.getElementById("webgl")).requestFullscreen(); // Warning: only works if called from a user-generated event
		#else
		engine.fullScreen = !engine.fullScreen;
		#end
	}

	public function startGame() {
		if( Game.ME!=null ) {
			Game.ME.destroy();
			delayer.addF(function() {
				new Game();
			}, 1);
		}
		else
			new Game();
	}

	override public function onResize() {
		super.onResize();

		// Auto scaling
		if( Const.AUTO_SCALE_TARGET_WID>0 )
			Const.SCALE = M.ceil( h()/Const.AUTO_SCALE_TARGET_WID );
		else if( Const.AUTO_SCALE_TARGET_HEI>0 )
			Const.SCALE = M.ceil( h()/Const.AUTO_SCALE_TARGET_HEI );
		root.setScale(Const.SCALE);
	}

    override function update() {
		dn.heaps.slib.SpriteLib.TMOD = tmod;
        super.update();
    }
}