package ui.win;

class SimpleMenu extends ui.Window {
	var useMouse : Bool; // TODO rework that
	public var group : InteractiveGroup;

	public function new(useMouse=true) {
		super(true);

		makeModal();
		this.useMouse = useMouse;
		content.padding = 1;
		content.enableInteractive = useMouse;

		group = new InteractiveGroup(content, this);
		group.content.verticalSpacing = 1;
		group.content.layout = Vertical;
		group.content.maxWidth = 120;

		mask.enableInteractive = useMouse;
		if( useMouse ) {
			mask.interactive.onClick = _->close();
			mask.interactive.enableRightButton = true;
		}
	}

	public function addSpacer() {
		var f = new h2d.Flow(content);
		f.minWidth = f.minHeight = 4;
	}

	public function addTitle(str:String) {
		var c = new ui.comp.Title(str, Col.coldGray(0.6));
		group.addNonInteractive(c);
	}

	public function addButton(label:String, autoClose=true, cb:Void->Void) {
		var c = new ui.comp.Button(label);
		group.addInteractive(c, ()->{
			cb();
			if( autoClose )
				close();
		});

		// Mouse controls
		// if( useMouse ) {
		// 	f.enableInteractive = true;
		// 	f.interactive.cursor = Button;
		// 	f.interactive.onOver = _->moveCursorOn(i);
		// 	f.interactive.onOut = _->if(cur==i) curIdx = -1;
		// 	f.interactive.onClick = ev->ev.button==0 ? validate(i) : this.close();
		// 	f.interactive.enableRightButton = true;
		// }
	}

	// public function addFlag(label:String, curValue:Bool, setter:Bool->Void, close=false) {
	// 	return addButton(
	// 		Lib.padRight(label,labelPadLen-4) + '[${curValue?"ON":"  "}]',
	// 		()->setter(!curValue),
	// 		close
	// 	);
	// }

	// public function addRadio(label:String, isActive:Bool, onPick:Void->Void, close=false) {
	// 	return addButton(
	// 		Lib.padRight(label,labelPadLen-3) + '<${isActive?"X":" "}>',
	// 		()->onPick(),
	// 		close
	// 	);
	// }

	// override function update() {
	// 	super.update();

	// 	if( ca.isPressedAutoFire(MenuUp) && curIdx>0 )
	// 		curIdx--;

	// 	if( ca.isPressedAutoFire(MenuDown) && curIdx<items.allocated-1 )
	// 		curIdx++;

	// 	if( cur!=null && ca.isPressed(MenuOk) )
	// 		validate(cur);
	// }
}