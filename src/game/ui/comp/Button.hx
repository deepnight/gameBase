package ui.comp;

class Button extends h2d.Flow {
	var tf : h2d.Text;
	public function new(?iconTile:h2d.Tile, ?label:String, col:dn.Col=Black, ?p) {
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
