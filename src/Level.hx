class Level extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;

	public var cWid(get,never) : Int; inline function get_cWid() return 48;
	public var cHei(get,never) : Int; inline function get_cHei() return cWid;

	public var pxWid(get,never) : Int; inline function get_pxWid() return cWid*Const.GRID;
	public var pxHei(get,never) : Int; inline function get_pxHei() return cHei*Const.GRID;

	var invalidated = true;

	public function new() {
		super(Game.ME);
		createRootInLayers(Game.ME.scroller, Const.DP_BG);
	}

	public inline function isValid(cx,cy) return cx>=0 && cx<cWid && cy>=0 && cy<cHei;
	public inline function coordId(cx,cy) return cx + cy*cWid;


	public function render() {
		// Debug level render
		root.removeChildren();
		for(cx in 0...cWid)
		for(cy in 0...cHei) {
			var g = new h2d.Graphics(root);
			if( cx==0 || cy==0 || cx==cWid-1 || cy==cHei-1 )
				g.beginFill( 0xffcc00 );
			else
				g.beginFill( Color.randomColor(rnd(0,1), 0.5, 0.4) );
			g.drawRect(cx*Const.GRID, cy*Const.GRID, Const.GRID, Const.GRID);
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