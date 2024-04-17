package ui;

class Window extends dn.Process {
	public static var ALL : Array<Window> = [];
	static var MODAL_COUNT = 0;

	public var content: h2d.Flow;

	var ca : ControllerAccess<GameAction>;
	var mask : Null<h2d.Flow>;
	var modalIdx = 0;

	public var isModal(default, null) = false;
	public var canBeClosedManually = true;


	public function new(modal:Bool, ?p:dn.Process) {
		super(p==null ? App.ME : p);

		ALL.push(this);
		createRootInLayers(Game.ME.root, Const.DP_UI);
		root.filter = new h2d.filter.Nothing(); // force pixel perfect rendering

		content = new h2d.Flow(root);
		content.backgroundTile = h2d.Tile.fromColor(0xffffff, 32,32);
		content.borderWidth = 7;
		content.borderHeight = 7;
		content.layout = Vertical;
		content.verticalSpacing = 2;
		content.onAfterReflow = onResize;
		content.enableInteractive = true;

		ca = App.ME.controller.createAccess();
		ca.lockCondition = ()->App.ME.anyInputHasFocus() || !isActive();
		ca.lock(0.1);

		emitResizeAtEndOfFrame();

		if( modal )
			makeModal();
	}

	public function isActive() {
		return !isModal || isLatestModal();
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

	@:keep override function toString():String {
		return isModal ? 'ModalWin${isActive()?"*":""}($modalIdx)' : 'Win';
	}

	public function makeModal() {
		if( isModal )
			return;

		isModal = true;

		modalIdx = MODAL_COUNT++;
		if( modalIdx==0 )
			Game.ME.pause();

		mask = new h2d.Flow(root);
		mask.backgroundTile = h2d.Tile.fromColor(0x0, 1, 1, 0.8);
		mask.enableInteractive = true;
		mask.interactive.onClick = _->{
			if( canBeClosedManually )
				close();
		}
		mask.interactive.enableRightButton = true;
		root.under(mask);
	}

	function isLatestModal() {
		var idx = ALL.length-1;
		while( idx>=0 ) {
			var w = ALL[idx];
			if( !w.destroyed ) {
				if( w!=this && w.isModal )
					return false;
				if( w==this )
					return true;
			}
			idx--;
		}
		return false;
	}

	public static function hasAnyModal() {
		for(e in ALL)
			if( !e.destroyed && e.isModal )
				return true;
		return false;
	}

	public function clearContent() {
		content.removeChildren();
	}


	override function onResize() {
		super.onResize();

		root.setScale(Const.UI_SCALE);

		var wid = M.ceil( w()/Const.UI_SCALE );
		var hei = M.ceil( h()/Const.UI_SCALE );
		content.x = Std.int( wid*0.5 - content.outerWidth*0.5 + modalIdx*8 );
		content.y = Std.int( hei*0.5 - content.outerHeight*0.5 + modalIdx*4 );

		if( mask!=null ) {
			var w = M.ceil( w()/Const.UI_SCALE );
			var h = M.ceil( h()/Const.UI_SCALE );
			mask.minWidth = w;
			mask.minHeight = h;
		}
	}

	public dynamic function onClose() {}

	public function close() {
		if( !destroyed ) {
			destroy();
			onClose();
		}
	}

	override function update() {
		super.update();
		if( canBeClosedManually && isModal && ca.isPressed(MenuCancel) )
			close();
	}
}
