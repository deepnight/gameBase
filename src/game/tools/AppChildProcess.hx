package tools;

class AppChildProcess extends dn.Process {
	public static var ALL : FixedArray<AppChildProcess> = new FixedArray(32);

	public var app(get,never) : App; inline function get_app() return App.ME;

	var fadeMask : h2d.Bitmap;

	public function new() {
		super(App.ME);
		createRootInLayers(App.ME.root, Const.DP_MAIN);
		ALL.push(this);

		fadeMask = new h2d.Bitmap( h2d.Tile.fromColor(Assets.walls()) );
		root.add(fadeMask, 99999);
		fadeMask.visible = false;
	}

	function fadeIn(t=1.5, ?then:Void->Void) {
		root.over(fadeMask);
		fadeMask.visible = true;
		tw.createS(fadeMask.alpha, 1>0, t).end( ()->{
			fadeMask.visible = false;
			if( then!=null )
				then();
		});
	}
	function fadeOut(t=0.5, ?then:Void->Void) {
		root.over(fadeMask);
		fadeMask.visible = true;
		tw.createS(fadeMask.alpha, 0>1, t).end( then );
	}

	override function onDispose() {
		super.onDispose();
		ALL.remove(this);
	}

	override function onResize() {
		super.onResize();

		fadeMask.scaleX = w();
		fadeMask.scaleY = h();
	}
}