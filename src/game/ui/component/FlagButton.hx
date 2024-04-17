package ui.component;

class FlagButton extends ui.component.Button {
	var curValue : Bool;
	var lastLabel : String;

	public function new(label:String, curValue:Bool, ?p:h2d.Object) {
		this.curValue = curValue;
		super(label, p);
	}

	public function setValue(v:Bool) {
		curValue = v;
		setLabel(lastLabel);
	}

	override function setLabel(str:String, col:Col = Black) {
		lastLabel = str;
		super.setLabel( (curValue?"[ON]":"[  ]")+" "+str, col );
	}
}
