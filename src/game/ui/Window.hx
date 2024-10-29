package ui;

enum WindowAlign {
	Start;
	End;
	Center;
	Fill;
}

class Window extends dn.Process {
	public static var ALL : Array<Window> = [];

	var uiWid(get,never) : Int; inline function get_uiWid() return M.ceil( stageWid/Const.UI_SCALE );
	var uiHei(get,never) : Int; inline function get_uiHei() return M.ceil( stageHei/Const.UI_SCALE );

	public var content: h2d.Flow;

	var ca : ControllerAccess<GameAction>;
	var mask : Null<h2d.Flow>;

	public var isModal(default, null) = false;
	public var canBeClosedManually = true;
	public var horizontalAlign(default,set) : WindowAlign = WindowAlign.Center;
	public var verticalAlign(default,set) : WindowAlign = WindowAlign.Center;


	public function new(modal:Bool, ?p:dn.Process) {
		var parentProc = p==null ? App.ME : p;
		super(parentProc);

		ALL.push(this);
		createRootInLayers(parentProc.root, Const.DP_UI);
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

	function getModalIndex() {
		if( !isModal )
			return -1;

		var i = 0;
		for( w in ALL )
			if( w.isModal ) {
				if( w==this )
					return i;
				i++;
			}
		Console.ME.error('$this has no valid modalIndex');
		return -1;
	}

	function set_horizontalAlign(v:WindowAlign) {
		if( v!=horizontalAlign ) {
			switch horizontalAlign {
				case Fill: content.minWidth = content.maxWidth = null; // clear previous constraint from onResize()
				case _:
			}
			horizontalAlign = v;
			emitResizeAtEndOfFrame();
		}
		return v;
	}

	function set_verticalAlign(v:WindowAlign) {
		if( v!=verticalAlign ) {
			switch verticalAlign {
				case Fill: content.minHeight = content.maxHeight = null; // clear previous constraint from onResize()
				case _:
			}
			verticalAlign = v;
			emitResizeAtEndOfFrame();
		}
		return v;
	}

	public function setAlign(h:WindowAlign, ?v:WindowAlign) {
		horizontalAlign = h;
		verticalAlign = v!=null ? v : h;
	}

	public function isActive() {
		return !destroyed && ( !isModal || isLatestModal() );
	}

	public function makeTransparent() {
		content.backgroundTile = null;
	}

	override function onDispose() {
		super.onDispose();

		ALL.remove(this);

		ca.dispose();
		ca = null;

		if( !hasAnyModal() )
			Game.ME.resume();

		emitResizeAtEndOfFrame();
	}

	@:keep override function toString():String {
		return isModal ? 'ModalWin${isActive()?"*":""}(${getModalIndex()})' : 'Win';
	}

	function makeModal() {
		if( isModal )
			return;

		isModal = true;

		if( getModalIndex()==0 )
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

		// Horizontal
		if( horizontalAlign==Fill )
			content.minWidth = content.maxWidth = uiWid;

		switch horizontalAlign {
			case Start: content.x = 0;
			case End: content.x = uiWid-content.outerWidth;
			case Center: content.x = Std.int( uiWid*0.5 - content.outerWidth*0.5 + getModalIndex()*8 );
			case Fill: content.x = 0; content.minWidth = content.maxWidth = uiWid;
		}

		// Vertical
		if( verticalAlign==Fill )
			content.minHeight = content.maxHeight = uiHei;

		switch verticalAlign {
			case Start: content.y = 0;
			case End: content.y = uiHei-content.outerHeight;
			case Center: content.y = Std.int( uiHei*0.5 - content.outerHeight*0.5 + getModalIndex()*4 );
			case Fill: content.y = 0; content.minHeight = content.maxHeight = uiHei;
		}

		// Mask
		if( mask!=null ) {
			mask.minWidth = uiWid;
			mask.minHeight = uiHei;
		}
	}

	public dynamic function onClose() {}

	public function close() {
		if( !destroyed ) {
			destroy();
			onClose();
		}
	}


	public function addSpacer(pixels=4) {
		var f = new h2d.Flow(content);
		f.minWidth = f.minHeight = pixels;
	}

	public function addTitle(str:String) {
		new ui.component.Text( str.toUpperCase(), Col.coldGray(0.5), content );
		addSpacer();
	}

	public function addText(str:String, col:Col=Black) {
		new ui.component.Text( str, col, content );
	}



	override function update() {
		super.update();
		if( canBeClosedManually && isModal && ca.isPressed(MenuCancel) )
			close();
	}
}
