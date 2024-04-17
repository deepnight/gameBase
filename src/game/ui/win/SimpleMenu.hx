package ui.win;

class SimpleMenu extends ui.Window {
	public var group : UiGroupController;

	public function new() {
		super(true);

		content.padding = 1;
		content.horizontalSpacing = 4;
		content.verticalSpacing = 0;
		content.layout = Vertical;
		content.multiline = true;
		content.maxWidth = 150;

		group = new UiGroupController(this);
		group.customControllerLock = ()->!isLatestModal();
	}


	override function onResize() {
		super.onResize();
		content.maxHeight = Std.int( 0.8 * h()/Const.UI_SCALE );
	}

	public function addSpacer() {
		var f = new h2d.Flow(content);
		f.minWidth = f.minHeight = 4;
	}

	public function addTitle(str:String) {
		new ui.component.Title( str, Col.coldGray(0.6), content );
	}

	public function addButton(label:String, autoClose=true, cb:Void->Void) {
		var bt = new ui.component.Button(label, content);
		bt.fillWidth = true;
		bt.onUseCb = ()->{
			cb();
			if( autoClose )
				close();
		}
		group.register(bt);
	}

	public function addCheckBox(label:String, getter:Void->Bool, setter:Bool->Void, autoClose=false) {
		var bt = new ui.component.CheckBox(label,getter,setter,content);
		bt.fillWidth = true;
		bt.onUseCb = ()->{
			if( autoClose )
				close();
		}
		// bt.onUse = ()->{
		// 	v = !v;
		// 	setter(v);
		// 	if( autoClose )
		// 		close();
		// 	else
		// 		bt.setValue(v);
		// }

		group.register(bt);
	}

	// public function addRadio(label:String, isActive:Bool, onPick:Void->Void, close=false) {
	// 	return addButton(
	// 		Lib.padRight(label,labelPadLen-3) + '<${isActive?"X":" "}>',
	// 		()->onPick(),
	// 		close
	// 	);
	// }
}