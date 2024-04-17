package ui.win;

class SimpleMenu extends ui.Window {
	public var group : InteractiveGroup;

	public function new() {
		super(true);

		makeModal();
		content.padding = 1;
		content.enableInteractive = true;

		group = new InteractiveGroup(content, this);
		group.content.horizontalSpacing = 4;
		group.content.verticalSpacing = 1;
		group.content.layout = Vertical;
		group.content.multiline = true;
		group.content.maxWidth = 150;
		group.customControllerLock = ()->!isLatestModal();
	}


	override function onResize() {
		super.onResize();
		group.content.maxHeight = Std.int( 0.8 * h()/Const.UI_SCALE );
	}

	public function addSpacer() {
		var f = new h2d.Flow(content);
		f.minWidth = f.minHeight = 4;
	}

	public function addTitle(str:String) {
		group.addNonInteractive( new ui.element.Title( str, Col.coldGray(0.6) ) );
	}

	public function addButton(label:String, autoClose=true, cb:Void->Void) {
		var e = new ui.element.Button(label);
		e.fillWidth = true;
		group.addInteractive(e, _->{
			cb();
			if( autoClose )
				close();
		});
	}

	public function addFlag(label:String, curValue:Bool, setter:Bool->Void, autoClose=false) {
		var v = curValue;
		var e = new ui.element.FlagButton(label,curValue);
		e.fillWidth = true;
		group.addInteractive( e, fb->{
			v = !v;
			setter(v);
			if( autoClose )
				close();
			else
				fb.setValue(v);
		});
	}

	// public function addRadio(label:String, isActive:Bool, onPick:Void->Void, close=false) {
	// 	return addButton(
	// 		Lib.padRight(label,labelPadLen-3) + '<${isActive?"X":" "}>',
	// 		()->onPick(),
	// 		close
	// 	);
	// }
}