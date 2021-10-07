/**
	"App" class takes care of all the top-level stuff in the whole application. Any other Process, including Game instance, should be a child of App.
**/

class App extends dn.Process {
	public static var ME : App;

	/** 2D scene **/
	public var scene(default,null) : h2d.Scene;

	/** Used to create "ControllerAccess" instances that will grant controller usage (keyboard or gamepad) **/
	public var controller : Controller<GameAction>;

	/** Controller Access created for Main & Boot **/
	public var ca : ControllerAccess<GameAction>;

	/** If TRUE, game is paused, and a Contrast filter is applied **/
	public var screenshotMode(default,null) = false;

	public function new(s:h2d.Scene) {
		super();
		ME = this;
		scene = s;
        createRoot(scene);

		initEngine();
		initAssets();
		initController();

		// Create console (open with [²] key)
		new ui.Console(Assets.fontPixel, scene); // init debug console

		// Optional screen that shows a "Click to start/continue" message when the game client looses focus
		#if js
		new dn.heaps.GameFocusHelper(scene, Assets.fontPixel);
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
		return Console.ME.isActive() || cd.has("consoleRecentlyActive");
	}


	/** Set screenshot mode **/
	public function setScreenshotMode(v:Bool) {
		screenshotMode = v;

		if( screenshotMode ) {
			var f = new h2d.filter.ColorMatrix();
			f.matrix.colorContrast(0.2);
			root.filter = f;
			if( Game.exists() ) {
				Game.ME.hud.root.visible = false;
				Game.ME.pause();
			}
		}
		else {
			if( Game.exists() ) {
				Game.ME.hud.root.visible = true;
				Game.ME.resume();
			}
			root.filter = null;
		}
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

		#if( hl && !debug)
		hl.UI.closeConsole();
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
		controller = new dn.heaps.input.Controller(GameAction);

		// Gamepad bindings
		controller.bindPadLStick(MoveX,MoveY);
		controller.bindPad(Jump, A);
		controller.bindPad(Restart, SELECT);
		controller.bindPadButtonsAsStick(MoveX, MoveY, DPAD_UP, DPAD_LEFT, DPAD_DOWN, DPAD_RIGHT);

		// Keyboard bindings
		controller.bindKeyboardAsStick(MoveX,MoveY, K.UP, K.LEFT, K.DOWN, K.RIGHT);
		controller.bindKeyboard(Jump, K.SPACE);
		controller.bindKeyboard(Restart, K.R);

		// Debug controls
		#if debug
		controller.bindPad(DebugTurbo, LT);
		controller.bindPad(DebugSlowMo, LB);
		controller.bindKeyboard(DebugTurbo, [K.END, K.NUMPAD_ADD]);
		controller.bindKeyboard(DebugSlowMo, [K.HOME, K.NUMPAD_SUB]);
		#end

		ca = controller.createAccess();
		ca.lockCondition = ()->{
			return destroyed || Console.ME.isActive();
		}
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
		Assets.update(tmod);

        super.update();

		if( ca.isKeyboardPressed(K.F9) )
			setScreenshotMode( !screenshotMode );

		if( ui.Console.ME.isActive() )
			cd.setF("consoleRecentlyActive",2);


    }
}