package ui;

class Window extends dn.Process {
	public var win: h2d.Flow;

	public function new(?p:dn.Process) {
		super(p==null ? App.ME : p);

		createRootInLayers(Game.ME.root, Const.DP_UI);
		root.filter = new h2d.filter.Nothing(); // force pixel perfect rendering

		win = new h2d.Flow(root);
		win.backgroundTile = h2d.Tile.fromColor(0xffffff, 32,32);
		win.borderWidth = 7;
		win.borderHeight = 7;
		win.layout = Vertical;
		win.verticalSpacing = 2;

		dn.Process.resizeAll();
	}

	public function clearWindow() {
		win.removeChildren();
	}

	public inline function add(e:h2d.Flow) {
		win.addChild(e);
		onResize();
	}

	override function onResize() {
		super.onResize();

		root.setScale(Const.UI_SCALE);

		var w = M.ceil( w()/Const.UI_SCALE );
		var h = M.ceil( h()/Const.UI_SCALE );
		win.x = Std.int( w*0.5 - win.outerWidth*0.5 );
		win.y = Std.int( h*0.5 - win.outerHeight*0.5 );
	}

	function onClose() {}
	public function close() {
		if( !destroyed ) {
			destroy();
			onClose();
		}
	}
}
