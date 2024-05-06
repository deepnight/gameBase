package ui.component;

class ControlsHelp extends ui.UiComponent {
	public function new(?p) {
		super(p);

		layout = Horizontal;
		horizontalSpacing = 16;
	}


	public function addControl(a:GameAction, label:String, col:Col=White) {
		var f = new h2d.Flow(this);
		f.layout = Horizontal;
		f.verticalAlign = Middle;

		var icon = App.ME.controller.getFirstBindindIconFor(a, "agnostic", f);
		f.addSpacing(4);

		var tf = new h2d.Text(Assets.fontPixel, f);
		f.getProperties(tf).offsetY = -2;
		tf.textColor = col;
		tf.text = txt;
	}

}
