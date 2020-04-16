class Level extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;

	public var wid(get,never) : Int; inline function get_wid() return data.getLayerByName("collisions").cWid;
	public var hei(get,never) : Int; inline function get_hei() return data.getLayerByName("collisions").cHei;
	var ogmo : ogmo.Project;
	var data : ogmo.Level;

	var marks : Map< LevelMark, Map<Int,Bool> > = new Map();
	var invalidated = true;

	public function new() {
		super(Game.ME);
		createRootInLayers(Game.ME.scroller, Const.DP_BG);

		ogmo = new ogmo.Project(hxd.Res.ld.world, false);
		data = ogmo.getLevelByName("baseLevel");
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

	public inline function getOgmoEntity(id:String) : Null<ogmo.Entity> {
		return data.getLayerByName("entities").getEntity(id);
	}

	public inline function getOgmoEntities(id:String) : Array<ogmo.Entity> {
		return data.getLayerByName("entities").getEntities(id);
	}

	public inline function hasCollision(cx,cy) : Bool {
		return !isValid(cx,cy) ? true : data.getLayerByName("collisions").getIntGrid(cx,cy)==1;
	}

	public function render() {
		// Debug level render
		root.removeChildren();
		for(cx in 0...wid)
		for(cy in 0...hei) {
			var g = new h2d.Graphics(root);
			g.beginFill(Color.randomColor(rnd(0,1), 0.5, 0.4), 1);
			g.drawRect(cx*Const.GRID, cy*Const.GRID, Const.GRID, Const.GRID);

			if( hasCollision(cx,cy) ) {
				g.beginFill(0xffffff);
				g.drawRect(cx*Const.GRID, cy*Const.GRID, Const.GRID, Const.GRID);
			}
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