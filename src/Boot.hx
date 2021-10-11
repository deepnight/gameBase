/**
	This class is the entry point for the app.
	It doesn't do much, except creating Main and taking care of app speed ()
**/

class Boot extends hxd.App {
	public static var ME : Boot;

	#if debug
	var tmodSpeedMul = 1.0;
	var ca(get,never) : ControllerAccess;
		inline function get_ca() return Main.ME.ca;
	#end


	/**
		App entry point
	**/
	static function main() {
		new Boot();
	}

	/**
		Called when engine is ready, actual app can start
	**/
	override function init() {
		ME = this;
		new Main(s2d);
		onResize();
	}


	override function onResize() {
		super.onResize();
		dn.Process.resizeAll();
	}


	/** Main app loop **/
	override function update(deltaTime:Float) {
		super.update(deltaTime);

		// Controller update
		Controller.beforeUpdate();

		var currentTmod = hxd.Timer.tmod;
		#if debug
		if( Main.ME!=null && !Main.ME.destroyed ) {
			// Slow down app (toggled with a key)
			if( ca.isKeyboardPressed(K.NUMPAD_SUB) || ca.isKeyboardPressed(K.HOME) || ca.dpadDownPressed()  )
				tmodSpeedMul = tmodSpeedMul>=1 ? 0.2 : 1;
			currentTmod*=tmodSpeedMul;

			// Turbo (by holding a key)
			currentTmod *= ca.isKeyboardDown(K.NUMPAD_ADD) || ca.isKeyboardDown(K.END) || ca.ltDown() ? 5 : 1;
		}
		#end

		// Update all dn.Process instances
		dn.Process.updateAll(currentTmod);
	}
}

