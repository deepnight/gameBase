import dn.Process;
import hxd.Key;

class Game extends Process {
	public static var ME : Game;

	public var ca : dn.heaps.Controller.ControllerAccess;
	public var fx : Fx;
	public var camera : Camera;
	public var scroller : h2d.Layers;
	public var level : Level;

	public function new() {
		super(Main.ME);
		ME = this;
		ca = Main.ME.controller.createAccess("game");
		ca.leftDeadZone = 0.2;
		ca.rightDeadZone = 0.2;
		createRootInLayers(Main.ME.root, Const.DP_BG);

		scroller = new h2d.Layers();
		if( Const.SCALE>1 )
			scroller.filter = new h2d.filter.ColorMatrix(); // force pixel render
		root.add(scroller, Const.DP_BG);

		camera = new Camera();
		level = new Level();
		fx = new Fx();

		trace(Lang.t._("Game is ready."));
	}

	public function onCdbReload() {
	}


	function gc() {
		if( Entity.GC==null || Entity.GC.length==0 )
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

		if( !ui.Console.ME.isActive() && !ui.Modal.hasAny() ) {
			#if hl
			// Exit
			if( ca.isKeyboardPressed(Key.ESCAPE) )
				if( !cd.hasSetS("exitWarn",3) )
					trace(Lang.t._("Press ESCAPE again to exit."));
				else
					hxd.System.exit();
			#end
		}
	}
}

