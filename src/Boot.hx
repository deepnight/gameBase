class Boot extends hxd.App {
	public static var ME : Boot;

	var ca(get,never) : dn.heaps.Controller.ControllerAccess;
		inline function get_ca() return Main.ME.ca;

	// Boot
	static function main() {
		new Boot();
	}

	// Engine ready
	override function init() {
		ME = this;
		new Main(s2d);
		onResize();
	}

	override function onResize() {
		super.onResize();
		dn.Process.resizeAll();
	}

	var tmodSpeedMul = 1.0;
	/** Main app loop **/
	override function update(deltaTime:Float) {
		super.update(deltaTime);

		// Controller update
		dn.heaps.Controller.beforeUpdate();

		var adjustedTmod = hxd.Timer.tmod;
		if( Main.ME!=null && !Main.ME.destroyed ) {
			// Debug slow-mo (toggled with a key)
			#if debug
			if( ca.isKeyboardPressed(K.NUMPAD_SUB) || ca.isKeyboardPressed(K.HOME) || ca.dpadDownPressed()  )
				tmodSpeedMul = tmodSpeedMul>=1 ? 0.2 : 1;
			#end
			adjustedTmod*=tmodSpeedMul;

			// Debug turbo (by holding a key)
			#if debug
			adjustedTmod *= ca.isKeyboardDown(K.NUMPAD_ADD) || ca.isKeyboardDown(K.END) || ca.ltDown() ? 5 : 1;
			#end
		}

		// Update all Processes
		dn.Process.updateAll(adjustedTmod);
	}
}

