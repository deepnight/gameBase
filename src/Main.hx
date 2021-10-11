import Data;
import hxd.Key;

class Main extends dn.Process {
	public static var ME : Main;

	/** Used to create "Access" instances that allow controller checks (keyboard or gamepad) **/
	public var controller : Controller;

	/** Controller Access created for Main & Boot **/
	public var ca : ControllerAccess;

	public function new(s:h2d.Scene) {
		super();
		ME = this;

        createRoot(s);

		// Engine settings
		engine.backgroundColor = 0xff<<24|0x111133;
        #if( hl && !debug )
        engine.fullScreen = true;
        #end

		// Heaps resources
		#if( hl && debug )
			hxd.Res.initLocal();
        #else
      		hxd.Res.initEmbed();
        #end

        // CastleDB hot reloading
		#if debug
        hxd.res.Resource.LIVE_UPDATE = true;
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

		// Assets & data init
		hxd.snd.Manager.get(); // force sound manager init on startup instead of first sound play
		Assets.init(); // init assets
		new ui.Console(Assets.fontTiny, s); // init debug console
		Lang.init("en"); // init Lang
		Data.load( hxd.Res.data.entry.getText() ); // read castleDB json

		// Game controller & default key bindings
		controller = new Controller(s);
		ca = controller.createAccess("main");
		controller.bind(AXIS_LEFT_X_NEG, Key.LEFT, Key.Q, Key.A);
		controller.bind(AXIS_LEFT_X_POS, Key.RIGHT, Key.D);
		controller.bind(X, Key.SPACE, Key.F, Key.E);
		controller.bind(A, Key.UP, Key.Z, Key.W);
		controller.bind(B, Key.ENTER, Key.NUMPAD_ENTER);
		controller.bind(SELECT, Key.R);
		controller.bind(START, Key.N);

		#if js
		// Optional helper that shows a "Click to start/continue" message when the game looses focus
		new dn.heaps.GameFocusHelper(Boot.ME.s2d, Assets.fontMedium);
		#end

		// Start with 1 frame delay, to avoid 1st frame freezing from the game perspective
		hxd.Timer.wantedFPS = Const.FPS;
		hxd.Timer.skip();
		delayer.addF( startGame, 1 );
	}

	/** Start game process **/
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


    override function update() {
		Assets.tiles.tmod = tmod;
        super.update();
    }
}