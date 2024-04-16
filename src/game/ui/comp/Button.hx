package ui.comp;

class Button extends h2d.Flow {
	public function new(?iconTile:h2d.Tile, label:String, col:dn.Col=Black, ?p) {
		super(p);

		verticalAlign = Middle;
		padding = 2;
		paddingBottom = 4;
		backgroundTile = h2d.Tile.fromColor(White);

		if( iconTile!=null )
			new h2d.Bitmap(iconTile, this);

		var tf = new h2d.Text(Assets.fontPixelMono, this);
		tf.textColor = col;
		tf.text = label;
	}
}
