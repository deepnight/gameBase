package ui.component;

class Text extends ui.UiComponent {
	public function new(label:String, col:dn.Col=Black, ?p) {
		super(p);

		paddingTop = 4;
		paddingBottom = 4;
		var tf = new h2d.Text(Assets.fontPixelMono, this);
		tf.textColor = col;
		tf.text = label;
	}
}
