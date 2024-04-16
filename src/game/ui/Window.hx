package ui;

class Window extends dn.Process {
	public static var ALL : Array<Window> = [];
	static var MODAL_COUNT = 0;

	public var win: h2d.Flow;

	var ca : ControllerAccess<GameAction>;
	var mask : Null<h2d.Flow>;
	var modalIdx = -1;

	public var isModal(default, null) = false;


	public function new(?p:dn.Process) {
		super(p==null ? App.ME : p);

		ALL.push(this);
		createRootInLayers(Game.ME.root, Const.DP_UI);
		root.filter = new h2d.filter.Nothing(); // force pixel perfect rendering

		win = new h2d.Flow(root);
		win.backgroundTile = h2d.Tile.fromColor(0xffffff, 32,32);
		win.borderWidth = 7;
		win.borderHeight = 7;
		win.layout = Vertical;
		win.verticalSpacing = 2;

		ca = App.ME.controller.createAccess();
		ca.lockCondition = ()->!isModal || App.ME.anyInputHasFocus();

		emitResizeAtEndOfFrame();
	}

	override function onDispose() {
		super.onDispose();

		ALL.remove(this);
		if( isModal )
			MODAL_COUNT--;

		ca.dispose();
		ca = null;

		if( !hasAnyModal() )
			Game.ME.resume();
	}

	public function makeModal() {
		if( isModal )
			return;

		isModal = true;

		modalIdx = MODAL_COUNT++;
		if( modalIdx==0 )
			Game.ME.pause();

		mask = new h2d.Flow(root);
		mask.backgroundTile = h2d.Tile.fromColor(0x0, 1, 1, 0.6);
		root.under(mask);
	}

	public static function hasAnyModal() {
		for(e in ALL)
			if( !e.destroyed && e.isModal )
				return true;
		return false;
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

		var wid = M.ceil( w()/Const.UI_SCALE );
		var hei = M.ceil( h()/Const.UI_SCALE );
		win.x = Std.int( wid*0.5 - win.outerWidth*0.5 );
		win.y = Std.int( hei*0.5 - win.outerHeight*0.5 );

		if( mask!=null ) {
			var w = M.ceil( w()/Const.UI_SCALE );
			var h = M.ceil( h()/Const.UI_SCALE );
			mask.minWidth = w;
			mask.minHeight = h;
		}
	}

	function onClose() {}
	public function close() {
		if( !destroyed ) {
			destroy();
			onClose();
		}
	}

	override function postUpdate() {
		super.postUpdate();
		if( isModal ) {
			mask.visible = modalIdx==0;
			win.alpha = modalIdx==MODAL_COUNT-1 ? 1 : 0.6;
		}
	}

	override function update() {
		super.update();
		if( isModal && ca.isPressed(MenuCancel) )
			close();
	}
}
