package ui.win;

typedef MenuItem = {
	var f: h2d.Flow;
	var tf: h2d.Text;
	var close: Bool;
	var cb: Void->Void;
}

class Menu extends ui.Modal {
	var padCount = 24;

	var curIdx = 0;
	public var cur(get,never) : Null<MenuItem>; inline function get_cur() return items.get(curIdx);
	var items : FixedArray<MenuItem> = new FixedArray(40);
	var cursor : h2d.Bitmap;
	var cursorInvalidated = true;


	public function new() {
		super(App.ME);

		win.padding = 1;
		win.enableInteractive = true;
		win.verticalSpacing = 0;

		mask.enableInteractive = true;
		mask.interactive.onClick = _->close();
		mask.interactive.enableRightButton = true;

		initMenu();
		ca.lock(0.1);
	}


	function initMenu() {
		items.empty();
		win.removeChildren();
		cursor = new h2d.Bitmap(h2d.Tile.fromColor(Black), win);
		win.getProperties(cursor).isAbsolute = true;

		invalidateCursor();
	}

	public function addSpacer() {
		var f = new h2d.Flow(win);
		f.minWidth = f.minHeight = 4;
	}

	public function addTitle(str:String) {
		var f = new h2d.Flow(win);
		f.padding = 2;
		if( items.allocated>0 )
			f.paddingTop = 6;

		var tf = new h2d.Text(Assets.fontPixelMono, f);
		tf.textColor = Col.coldGray(0.6);
		tf.text = Lib.padRight(str.toUpperCase(), padCount, "_");
	}

	public function addButton(label:String, cb:Void->Void, close=true) {
		var f = new h2d.Flow(win);
		f.padding = 2;
		f.paddingBottom = 4;

		// Label
		var tf = new h2d.Text(Assets.fontPixelMono, f);
		tf.textColor = Black;
		tf.text = Lib.padRight(label, padCount);

		var i : MenuItem = { f:f, tf:tf, cb:cb, close:close }
		items.push(i);

		// Mouse controls
		f.enableInteractive = true;
		f.interactive.cursor = Button;
		f.interactive.onOver = _->moveCursorOn(i);
		f.interactive.onOut = _->if(cur==i) { curIdx = -1; invalidateCursor(); };
		f.interactive.onClick = ev->ev.button==0 ? validate(i) : this.close();
		f.interactive.enableRightButton = true;
	}

	public function addFlag(label:String, curValue:Bool, setter:Bool->Void, close=false) {
		addButton(
			Lib.padRight(label,padCount-4) + '[${curValue?"ON":"  "}]',
			()->setter(!curValue),
			close
		);
	}

	public function addRadio(label:String, isActive:Bool, onPick:Void->Void, close=false) {
		addButton(
			Lib.padRight(label,padCount-3) + '<${isActive?"X":" "}>',
			()->onPick(),
			close
		);
	}

	function moveCursorOn(item:MenuItem) {
		var idx = 0;
		for(i in items) {
			if( i==item ) {
				curIdx = idx;
				invalidateCursor();
				break;
			}
			idx++;
		}
	}

	function validate(item:MenuItem) {
		item.cb();
		if( item.close )
			close();
		else
			initMenu();
	}

	inline function invalidateCursor() {
		cursorInvalidated = true;
	}

	function updateCursor() {
		// Clean up
		for(i in items)
			i.f.filter = null;

		if( cur==null )
			cursor.visible = false;
		else {
			cursor.visible = true;
			cursor.width = win.innerWidth;
			cursor.height = cur.f.outerHeight;
			cursor.x = cur.f.x;
			cursor.y = cur.f.y;
			cur.f.filter = new dn.heaps.filter.Invert();
		}
	}

	override function postUpdate() {
		super.postUpdate();
		if( cursorInvalidated ) {
			cursorInvalidated = false;
			updateCursor();
		}
	}

	override function update() {
		super.update();

		if( ca.isPressedAutoFire(MenuUp) && curIdx>0 ) {
			curIdx--;
			invalidateCursor();
		}

		if( ca.isPressedAutoFire(MenuDown) && curIdx<items.allocated-1 ) {
			curIdx++;
			invalidateCursor();
		}

		if( cur!=null && ca.isPressed(MenuOk) )
			validate(cur);
	}
}