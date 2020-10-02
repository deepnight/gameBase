class Level extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;

	public var wid(get,never) : Int; inline function get_wid() return level.l_Collisions.cWid;
	public var hei(get,never) : Int; inline function get_hei() return level.l_Collisions.cHei;

	public var level : World.World_Level;
	var tilesetSource : h2d.Tile;

	var marks : Map< LevelMark, Map<Int,Bool> > = new Map();
	var invalidated = true;

	public function new(l:World.World_Level) {
		super(Game.ME);
		createRootInLayers(Game.ME.scroller, Const.DP_BG);
		level = l;
		tilesetSource = hxd.Res.world.tiles.toTile();
	}

	public inline function isValid(cx,cy) return cx>=0 && cx<wid && cy>=0 && cy<hei;
	public inline function coordId(cx,cy) return cx + cy*wid;


	public inline function hasMark(mid:LevelMark, cx:Int, cy:Int) {
		return !isValid(cx,cy) || !marks.exists(mid) ? false : marks.get(mid).exists( coordId(cx,cy) );
	}

	public function setMark(mid:LevelMark, cx:Int, cy:Int) {
		if( isValid(cx,cy) && !hasMark(mid,cx,cy) ) {
			if( !marks.exists(mid) )
				marks.set(mid, new Map());
			marks.get(mid).set( coordId(cx,cy), true );
		}
	}

	public function removeMark(mid:LevelMark, cx:Int, cy:Int) {
		if( isValid(cx,cy) && hasMark(mid,cx,cy) )
			marks.get(mid).remove( coordId(cx,cy) );
	}

	public inline function hasCollision(cx,cy) : Bool {
		return !isValid(cx,cy) ? true : level.l_Collisions.getInt(cx,cy)==0;
	}

	public function render() {
		root.removeChildren();

		var tg = new h2d.TileGroup(tilesetSource, root);

		var layer = level.l_Collisions;
		for( autoTile in layer.autoTiles ) {
			var tile = layer.tileset.getAutoLayerHeapsTile(tilesetSource, autoTile);
			tg.add(autoTile.renderX, autoTile.renderY, tile);
		}
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}