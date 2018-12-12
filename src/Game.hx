import mt.Process;
import mt.MLib;
import mt.deepnight.CdbHelper;
import hxd.Key;

class Game extends mt.Process {
	public static var ME : Game;

	public var ca : mt.heaps.Controller.ControllerAccess;
	public var fx : Fx;

	public function new() {
		super(Main.ME);
		ME = this;
		ca = Main.ME.controller.createAccess("game");
		createRootInLayers(Main.ME.root, Const.DP_BG);

		fx = new Fx();
		trace("Game is ready.");
	}

	public function onCdbReload() {
	}


	function gc() {
		if( Entity.GC==null )
			return;

		for(e in Entity.GC)
			e.dispose();
		Entity.GC = [];
	}

	override function onDispose() {
		super.onDispose();

		fx.destroy();
		for(e in Entity.ALL)
			e.destroy();
		gc();
	}

	override function update() {
		super.update();

		// Updates
		for(e in Entity.ALL) if( !e.destroyed ) e.preUpdate();
		for(e in Entity.ALL) if( !e.destroyed ) e.update();
		for(e in Entity.ALL) if( !e.destroyed ) e.postUpdate();
		gc();

		if( !Console.ME.isActive() ) {
			#if hl
			if( ca.isKeyboardPressed(Key.ESCAPE) )
				if( !cd.hasSetS("exitWarn",3) )
					trace("Press ESCAPE again to exit.");
				else
					hxd.System.exit();
			#end
		}
	}
}

