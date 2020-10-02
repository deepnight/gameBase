class Boot extends hxd.App {
	public static var ME : Boot;

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

	// Window resized
	override function onResize() {
		super.onResize();
		dn.Process.resizeAll();
	}

	var speed = 1.0;
	override function update(deltaTime:Float) {
		super.update(deltaTime);

		var boost = 1.0;

		#if debug
		// Debug time controls
		if( Main.ME!=null && !Main.ME.destroyed ) {
			// Manual debug slow-mo when pressing SUBSTRACT key, HOME key or DPAD-DOWN on a gamepad
			var ca = Main.ME.ca;
			if( ca.isKeyboardPressed(K.NUMPAD_SUB) || ca.isKeyboardPressed(K.HOME) || ca.dpadDownPressed() )
				speed = speed>=1 ? 0.25 : 1;

			// Manual debug turbo when holding ADD key, END key or LEFT STICK on a gamepad
			boost = ca.isKeyboardDown(K.NUMPAD_ADD) || ca.isKeyboardDown(K.END) || ca.ltDown() ? 5 : 1;
		}
		#end

		var tmod = hxd.Timer.tmod * boost * speed;

		dn.heaps.Controller.beforeUpdate();
		dn.Process.updateAll(tmod);
	}
}

