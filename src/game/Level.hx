class Level extends GameChildProcess {
	/** Level grid-based width**/
	public var cWid(default,null): Int;
	/** Level grid-based height **/
	public var cHei(default,null): Int;

	/** Level pixel width**/
	public var pxWid(default,null) : Int;
	/** Level pixel height**/
	public var pxHei(default,null) : Int;

	public var data : World_Level;

	public var marks : dn.MarkerMap<LevelMark>;
	var invalidated = true;
	public var cachedEmptyPoints : Array<LPoint> = [];

	public function new(ldtkLevel:World.World_Level) {
		super();

		createRootInLayers(Game.ME.scroller, Const.DP_BG);
		data = ldtkLevel;
		cWid = data.l_Collisions.cWid;
		cHei = data.l_Collisions.cHei;
		pxWid = cWid * Const.GRID;
		pxHei = cHei * Const.GRID;

		marks = new dn.MarkerMap(cWid, cHei);
		for(cy in 0...cHei)
		for(cx in 0...cWid) {
			if( data.l_Collisions.getInt(cx,cy)==1 )
				marks.set(Coll_Wall, cx,cy);

			if( !hasCollision(cx,cy) )
				cachedEmptyPoints.push( LPoint.fromCase(cx,cy) );
		}
	}

	override function onDispose() {
		super.onDispose();
		data = null;
		marks.dispose();
		marks = null;
	}

	/** TRUE if given coords are in level bounds **/
	public inline function isValid(cx,cy) return cx>=0 && cx<cWid && cy>=0 && cy<cHei;

	/** Gets the integer ID of a given level grid coord **/
	public inline function coordId(cx,cy) return cx + cy*cWid;

	/** Ask for a level render that will only happen at the end of the current frame. **/
	public inline function invalidate() {
		invalidated = true;
	}

	public inline function setTempCollision(cx,cy, v) {
		if( isValid(cx,cy) )
			if( v )
				marks.set(Coll_Temp, cx,cy);
			else
				marks.clearMarkAt(Coll_Temp, cx,cy);
	}

	/** Return TRUE if "Collisions" layer contains a collision value **/
	public inline function hasCollision(cx,cy) : Bool {
		return !isValid(cx,cy) ? true : marks.has(Coll_Wall, cx,cy) || marks.has(Coll_Temp, cx,cy);
	}

	/** Render current level**/
	function render() {
		root.removeChildren();

		var tg = new h2d.TileGroup(Assets.world.tile, root);
		data.l_AutoFloors.render(tg);
		data.l_Floors.render(tg);
		data.l_Collisions.render(tg);
		data.l_Details.render(tg);
	}

	public function darken() {
		var m = new h3d.Matrix();
		m.identity();
		final v = 0.15;
		m._11 = v;
		m._22 = v;
		m._33 = v;
		root.filter = new h2d.filter.ColorMatrix(m);
	}
	public function undarken() {
		root.filter = null;
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}