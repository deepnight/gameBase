package ui.comp;

class FlagButton extends ui.comp.Button {
	var labelPad : Int;
	var state : Bool;
	var lastLabel : String;

	public function new(label:String, curState:Bool, labelPad=15, ?p) {
		this.labelPad = labelPad;
		state = curState;
		super(p, label);
	}

	public function setState(v:Bool) {
		state = v;
		setLabel(lastLabel);
	}

	override function setLabel(str:String, col:Col = Black) {
		lastLabel = str;
		super.setLabel(Lib.padRight(str,labelPad) + (state?" [ON]":" [  ]"), col);
	}
}
