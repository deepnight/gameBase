package ui;

class IconBar extends h2d.TileGroup {
	var curX = 0;
	public var width(default,null) = 0;
	public var height(default,null) = 0;
	public var overlap = 0.5;

	public function new(?p) {
		super(Assets.tiles.tile, p);
	}

	public inline function empty() {
		clear();
		curX = 0;
	}

	public function addIcons(iconId:String, n=1) {
		for(i in 0...n) {
			var t = Assets.tiles.getTile(iconId);
			add(curX, 0, t);
			width = curX + t.iwidth;
			height = M.imax(height, t.iheight);
			curX += M.ceil(t.width*(1-overlap));
		}
	}
}