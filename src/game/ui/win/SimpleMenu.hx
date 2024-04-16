package ui.win;

class SimpleMenu extends ui.Window {
	public var group : InteractiveGroup;

	public function new() {
		super(true);

		makeModal();
		content.padding = 1;
		content.enableInteractive = true;

		group = new InteractiveGroup(content, this);
		group.content.verticalSpacing = 1;
		group.content.layout = Vertical;
		group.content.maxWidth = 150;
		group.customControllerLock = ()->!isLatestModal();
	}

	public function addSpacer() {
		var f = new h2d.Flow(content);
		f.minWidth = f.minHeight = 4;
	}

	public function addTitle(str:String) {
		group.addNonInteractive( new ui.comp.Title( str, Col.coldGray(0.6) ) );
	}

	public function addButton(label:String, autoClose=true, cb:Void->Void) {
		group.addInteractive(new ui.comp.Button(label), _->{
			cb();
			if( autoClose )
				close();
		});
	}

	public function addFlag(label:String, curValue:Bool, setter:Bool->Void, close=false) {
		var v = curValue;
		group.addInteractive( new ui.comp.FlagButton(label,curValue), fb->{
			v = !v;
			setter(v);
			if( close )
				this.close();
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