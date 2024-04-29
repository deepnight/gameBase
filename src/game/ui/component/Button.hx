package ui.component;

class Button extends ui.UiComponent {
	var tf : h2d.Text;

	public function new(?label:String, ?iconTile:h2d.Tile, col:dn.Col=Black, ?p:h2d.Object) {
		super(p);

		verticalAlign = Middle;
		padding = 2;
		paddingBottom = 4;
		backgroundTile = h2d.Tile.fromColor(White);

		if( iconTile!=null )
			new h2d.Bitmap(iconTile, this);

		tf = new h2d.Text(Assets.fontPixelMono, this);
		if( label!=null )
			setLabel(label, col);
	}

	public function setLabel(str:String, col:dn.Col=Black) {
		tf.text = str;
		tf.textColor = col;
	}
}
