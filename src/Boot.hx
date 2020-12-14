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

	override function onResize() {
		super.onResize();
		dn.Process.resizeAll();
	}

	var tmodSpeedMul = 1.0;
	/** Main app loop **/
	override function update(deltaTime:Float) {
		super.update(deltaTime);

		var adjustedTmod = hxd.Timer.tmod;

		// Controller update
		dn.heaps.Controller.beforeUpdate();

		// Debug slow-mo (toggled with a key)
		#if debug
		if( hxd.Key.isPressed(hxd.Key.NUMPAD_SUB) || Main.ME.ca.dpadDownPressed() )
			tmodSpeedMul = tmodSpeedMul>=1 ? 0.33 : 1;
		#end
		adjustedTmod*=tmodSpeedMul;

		// Debug turbo (by holding a key)
		#if debug
		adjustedTmod *= hxd.Key.isDown(hxd.Key.NUMPAD_ADD) || Main.ME!=null && Main.ME.ca.ltDown() ? 5 : 1;
		#end

		// Update all Processes
		dn.Process.updateAll(adjustedTmod);
	}
}

