/**
	Boot class is the entry point for the app.
	It doesn't do much, except creating Main class and taking care of loops. Thus, you shouldn't be doing too much in this class.
**/

class Boot extends hxd.App {
	#if debug
	// Debug controls over game speed
	var tmodSpeedMul = 1.0;

	// Shortcut to controller
	var ca(get,never) : dn.heaps.Controller.ControllerAccess;
		inline function get_ca() return App.ME.ca;
	#end


	/**
		App entry point: everything starts here
	**/
	static function main() {
		new Boot();
	}

	/**
		Called when engine is ready, actual app can start
	**/
	override function init() {
		new App(s2d);
		onResize();
	}

	// Window resized
	override function onResize() {
		super.onResize();
		dn.Process.resizeAll();
	}


	/** Main app loop **/
	override function update(deltaTime:Float) {
		super.update(deltaTime);

		// Controller update
		dn.heaps.Controller.beforeUpdate();


		// Debug controls over app speed
		var adjustedTmod = hxd.Timer.tmod;
		#if debug
		if( App.exists() ) {
			// Slow down (toggle)
			if( ca.isKeyboardPressed(K.NUMPAD_SUB) || ca.isKeyboardPressed(K.HOME) || ca.dpadDownPressed()  )
				tmodSpeedMul = tmodSpeedMul>=1 ? 0.2 : 1;
			adjustedTmod *= tmodSpeedMul;

			// Turbo (by holding a key)
			adjustedTmod *= ca.isKeyboardDown(K.NUMPAD_ADD) || ca.isKeyboardDown(K.END) || ca.ltDown() ? 5 : 1;
		}
		#end

		// Run all dn.Process instances loops
		dn.Process.updateAll(adjustedTmod);

		// Update current sprite atlas "tmod" value (for animations)
		Assets.update(adjustedTmod);
	}
}

