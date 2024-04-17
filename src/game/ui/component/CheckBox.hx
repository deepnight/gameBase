package ui.component;

class CheckBox extends ui.component.Button {
	var label : String;
	var lastDisplayedValue : Bool;
	var getter : Void->Bool;
	var setter : Bool->Void;

	public function new(label:String, getter:Void->Bool, setter:Bool->Void, ?p:h2d.Object) {
		this.getter = getter;
		this.setter = setter;
		super(label, p);
	}

	override function onUse() {
		super.onUse();

		setter(!getter());
		setLabel(label);
	}

	override function setLabel(str:String, col:Col = Black) {
		label = str;
		lastDisplayedValue = getter();
		super.setLabel( (getter()?"[ON]":"[  ]")+" "+label, col );
	}

	override function sync(ctx:h2d.RenderContext) {
		super.sync(ctx);
		if( lastDisplayedValue!=getter() )
			setLabel(label);
	}
}
