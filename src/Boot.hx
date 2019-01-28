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
		mt.Process.resizeAll();
	}

	override function onResize() {
		super.onResize();
		mt.Process.resizeAll();
	}

	var speed = 1.0;
	override function update(deltaTime:Float) {
		super.update(deltaTime);

		// Bullet time
		#if debug
		if( hxd.Key.isPressed(hxd.Key.NUMPAD_SUB) )
			speed = speed>=1 ? 0.33 : 1;
		#end

		var tmod = hxd.Timer.tmod * speed;
		#if debug
		tmod *= hxd.Key.isDown(hxd.Key.NUMPAD_ADD) || Main.ME!=null && Main.ME.ca.ltDown() ? 5 : 1;
		#end
		mt.heaps.Controller.beforeUpdate();
		mt.Process.updateAll(tmod);
	}
}

