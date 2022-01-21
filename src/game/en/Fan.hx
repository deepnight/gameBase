package en;

import dn.CiAssert;
import dn.Bresenham;

typedef CellStruct = {index:Int, abx:Int, aby:Int, u:Float, v:Float}

class Fan extends Entity {
	public static var ALL:Array<Fan> = [];

	public var solver(get, never):Solver;inline function get_solver()return Game.ME.solver;

	var areaShape:AreaShape = AsCircle;
	var areaInfluence:AreaInfluence = AiSmall;
	var areaEquation:AreaEquation = AeCurl;
	var ah:Int = 5;
	var aw:Int = 5;
	var areaRadius:Int = 3;

	var cxSolverOffset(get, never):Int;inline function get_cxSolverOffset() return cx + solver.caseOffset;
	var cySolverOffset(get, never):Int;inline function get_cySolverOffset() return cy + solver.caseOffset;

	// var isx = Math.floor(x - (aw / 2));
	var cxTopRectangle(get, never):Int;inline function get_cxTopRectangle()return Math.floor(cxSolverOffset - (aw / 2));
	var cyTopRectangle(get, never):Int;inline function get_cyTopRectangle()return Math.floor(cySolverOffset - (ah / 2));

	var angle:Float = 0;

	public var informedCells:Array<CellStruct> = [];

	public function new(x:Int, y:Int) {
		super(x, y);
		ALL.push(this);
		computeInfluencedCell();

		spr.set(D.tiles.Square);
		spr.colorize(0x00ff00, 1);
	}

	override function update() {
		angle += 0.01;
	}

	function computeInfluencedCell() {
		informedCells = [];
		switch (areaShape) {
			case AsSquare:
				addRectangleAreaCells_toInformedCells();
				return;
			case AsCircle:
				addRectangleAreaCells_toInformedCells();
				return;
			case AsLine:
				return;
		}
	}

	function addRectangleAreaCells_toInformedCells() {
		var list = Bresenham.getRectangle(cxTopRectangle, cyTopRectangle, aw, ah);
		for (l in list) {
			var absoluteCx = l.x - cx;
			var absoluteCy = l.y - cy;
			var ind = l.x + (solver.sw * l.y);
			solver.cells[ind].visible = false;
			if (testIfIndexIsInArray(ind)) {
				solver.cells[ind].visible = false;
				informedCells.push({index: ind,abx: absoluteCx,aby: absoluteCy,u: 0,v: 0});
			}
		}
	}

	function addCircleAreaCells_toInformedCells() {
		var list = Bresenham.getDisc(cxSolverOffset, cySolverOffset, areaRadius);

		for (l in list) {
			var absoluteCx = l.x - cx;
			var absoluteCy = l.y - cy;
			var ind = l.x + (solver.sw * l.y);
			solver.cells[ind].visible = false;
			if (testIfIndexIsInArray(ind)) {
				solver.cells[ind].visible = false;
				informedCells.push({index: ind,	abx: absoluteCx,aby: absoluteCy,u: 0,v: 0});
			}
		}
	}

	// a delocaliser en api public solver
	function testIfIndexIsInArray(cellIndex:Int) {
		if (cellIndex >= 0 && cellIndex < solver.solver.numCells)
			return true;
		return false;
	}
}

    
/*     function addSquareAreaCells_toInformedCells(){
            var ind:Int;
			var x = cxSolverOffset;
            var y = cySolverOffset;

			var jsy = Math.floor(y - (ah / 2));
			var jey = Math.floor(y + (ah / 2));
			var isx = Math.floor(x - (aw / 2));
			var iex = Math.floor(x + (aw / 2));

			for (j in jsy...jey) {
				for (i in isx...iex) {
					ind = i + (solver.sw * j);
					if (testIfIndexIsInArray(ind)) {
						var absoluteCx = Math.floor((i + solver.caseOffset - x));
						var absoluteCy = Math.floor((j + solver.caseOffset - y));
						informedCells.push({index: ind,abx: absoluteCx,aby: absoluteCy,u: 0,v: 0});
					}
				}
			}
        } */