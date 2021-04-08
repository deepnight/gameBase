/**
	"App" class takes care of all the top-level stuff in the whole application. Any other Process, including Game instance, should be a child of App.
**/

class App extends dn.Process {
	public static var ME : App;

	public static var test(get,set): Int;
		static function get_test() return 0;
		static function set_test(v) return v;

	public var pouet = "hello";
	public var int=5;
	public var bool=true;

	/** 2D scene **/
	public var scene(default,null) : h2d.Scene;

	/** Used to create "ControllerAccess" instances that will grant controller usage (keyboard or gamepad) **/
	public var controller : dn.heaps.Controller;

	/** Controller Access created for Main & Boot **/
	public var ca : dn.heaps.Controller.ControllerAccess;

	public function new(s:h2d.Scene) {
		super();
		ME = this;
		scene = s;
        createRoot(scene);

		initEngine();
		initAssets();
		initController();

		// Create console (open with [²] key)
		new ui.Console(Assets.fontTiny, scene); // init debug console

		// Optional screen that shows a "Click to start/continue" message when the game client looses focus
		#if js
		new dn.heaps.GameFocusHelper(scene, Assets.fontMedium);
		#end

		startGame();
	}



	/** Start game process **/
	public function startGame() {
		if( Game.exists() ) {
			// Kill previous game instance first
			Game.ME.destroy();
			dn.Process.updateAll(1); // ensure all garbage collection is done
			_createGameInstance();
			hxd.Timer.skip();
		}
		else {
			// Fresh start
			delayer.addF( ()->{
				_createGameInstance();
				hxd.Timer.skip();
			}, 1 );
		}
	}

	final function _createGameInstance() {
		// new Game(); // <---- Uncomment this to start an empty Game instance
		new sample.SampleGame(); // <---- Uncomment this to start the Sample Game instance
	}


	public function anyInputHasFocus() {
		return Console.ME.isActive();
	}


	/**
		Initialize low level stuff, before anything else
	**/
	function initEngine() {
		// Engine settings
		engine.backgroundColor = 0xff<<24 | 0x111133;
        #if( hl && !debug )
        engine.fullScreen = true;
        #end

		// Heaps resource management
		#if( hl && debug )
			hxd.Res.initLocal();
			hxd.res.Resource.LIVE_UPDATE = true;
        #else
      		hxd.Res.initEmbed();
        #end

		// Sound manager (force manager init on startup to avoid a freeze on first sound playback)
		hxd.snd.Manager.get();
		hxd.Timer.skip(); // needed to ignore heavy Sound manager init frame

		// Framerate
		hxd.Timer.smoothFactor = 0.4;
		hxd.Timer.wantedFPS = Const.FPS;
		dn.Process.FIXED_UPDATE_FPS = Const.FIXED_UPDATE_FPS;
	}


	/** Init app assets **/
	function initAssets() {
		// Init game assets
		Assets.init();

		// Init lang data
		Lang.init("en");
	}


	/** Init game controller and default key bindings **/
	function initController() {
		controller = new dn.heaps.Controller(scene);
		ca = controller.createAccess("main");
		controller.bind(AXIS_LEFT_X_NEG, K.LEFT, K.Q, K.A);
		controller.bind(AXIS_LEFT_X_POS, K.RIGHT, K.D);
		controller.bind(X, K.SPACE, K.F, K.E);
		controller.bind(A, K.UP, K.Z, K.W);
		controller.bind(B, K.ENTER, K.NUMPAD_ENTER);
		controller.bind(SELECT, K.R);
		controller.bind(START, K.N);
	}


	/** Return TRUE if an App instance exists **/
	public static inline function exists() return ME!=null && !ME.destroyed;

	/** Close the app **/
	public function exit() {
		destroy();
	}

	override function onDispose() {
		super.onDispose();

		#if hl
		hxd.System.exit();
		#end
	}


    override function update() {
		Assets.tiles.tmod = tmod;
        super.update();
    }
}