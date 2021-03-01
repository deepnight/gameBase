import Data;
import hxd.Key;

class Main extends dn.Process {
	public static var ME : Main;

	/** 2D scene **/
	public var scene(default,null) : h2d.Scene;

	/** Used to create "Access" instances that allow controller checks (keyboard or gamepad) **/
	public var controller : dn.heaps.Controller;

	/** Controller Access created for Main & Boot **/
	public var ca : dn.heaps.Controller.ControllerAccess;

	public function new(s:h2d.Scene) {
		super();
		ME = this;
		scene = s;
        createRoot(scene);

		initHeaps();
		initAssets();
		initController();

		// Optional screen that shows a "Click to start/continue" message when the game client looses focus
		#if js
		new dn.heaps.GameFocusHelper(scene, Assets.fontMedium);
		#end

		startGame();
	}


	function initHeaps() {
		// Engine settings
		engine.backgroundColor = 0xff<<24 | 0x111133;
        #if( hl && !debug )
        engine.fullScreen = true;
        #end

		// Heaps resources
		#if( hl && debug )
			hxd.Res.initLocal();
			hxd.res.Resource.LIVE_UPDATE = true;
        #else
      		hxd.Res.initEmbed();
        #end

		// Sound manager (force manager init on startup to avoid a freeze on first sound playback)
		hxd.snd.Manager.get();

		// Init Timer with desired FPS
		hxd.Timer.wantedFPS = Const.FPS;
	}


	function initAssets() {
        // CastleDB file hot reloading
		#if debug
        hxd.Res.data.watch(function() {
            delayer.cancelById("cdb");
            delayer.addS("cdb", function() {
				// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
            	Data.load( hxd.Res.data.entry.getBytes().toString() );
            	if( Game.ME!=null )
                    Game.ME.onCdbReload();
            }, 0.2);
        });
		#end

		// LDtk file hot-reloading
		#if debug
		hxd.Res.world.world.watch(function() {
			delayer.cancelById("ldtk");
			delayer.addS("ldtk", function() {
				// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
				if( Game.ME!=null )
					Game.ME.onLdtkReload();
			}, 0.2);
		});
		#end

		// Parse castleDB JSON
		Data.load( hxd.Res.data.entry.getText() );

		// Init game assets
		Assets.init();

		// Init console (open with [²] key)
		new ui.Console(Assets.fontTiny, scene); // init debug console

		// Init lang data
		Lang.init("en");
	}


	/** Game controller & default key bindings **/
	function initController() {
		controller = new dn.heaps.Controller(scene);
		ca = controller.createAccess("main");
		controller.bind(AXIS_LEFT_X_NEG, Key.LEFT, Key.Q, Key.A);
		controller.bind(AXIS_LEFT_X_POS, Key.RIGHT, Key.D);
		controller.bind(X, Key.SPACE, Key.F, Key.E);
		controller.bind(A, Key.UP, Key.Z, Key.W);
		controller.bind(B, Key.ENTER, Key.NUMPAD_ENTER);
		controller.bind(SELECT, Key.R);
		controller.bind(START, Key.N);
	}




	/** Start game process **/
	public function startGame() {
		if( Game.ME!=null ) {
			Game.ME.destroy();
			dn.Process.updateAll(1);
			new Game();
			hxd.Timer.skip();
		}
		else {
			hxd.Timer.skip(); // need to ignore heavy Sound manager init frame
			delayer.addF( ()->{
				new Game();
				hxd.Timer.skip();
			}, 1 );
		}
	}


    override function update() {
		Assets.tiles.tmod = tmod;
        super.update();
    }
}