

import solv.Boids;
import solv.DebugSolver;
import solv.FluidSolver;

import solv.SolverModifier;

import h3d.Vector;

class Solver extends dn.Process {
	
    var game(get,never) : Game; inline function get_game() return Game.ME;
	var level(get,never) : Level; inline function get_level() return Game.ME.level;

    var width(get,never) : Int; inline function get_width() return Std.int(level.pxWid);
    var height(get,never): Int; inline function get_height()return Std.int(level.pxHei);
    
    var isw(get,never): Float; inline function get_isw() return 1 / width;
    var ish(get,never): Float; inline function get_ish() return 1 / width;

	var aspectRatio(get,never):Float ;inline function get_aspectRatio() return width * ish;
	var aspectRatio2(get,never):Float;inline function get_aspectRatio2() return aspectRatio * aspectRatio;

    var FLUID_WIDTH(get,never) : Int; inline function get_FLUID_WIDTH() return level.cWid;
    var FLUID_HEIGHT(get,never): Int; inline function get_FLUID_HEIGHT() return Std.int( FLUID_WIDTH * height / width );
    
    var graphicsDebug:solv.DebugSolver;
	var solver:solv.FluidSolver;

	public function new() {
		super(Game.ME);

		solver = new FluidSolver(FLUID_WIDTH, FLUID_HEIGHT );
        graphicsDebug = new DebugSolver(solver);

	}

    
    override public function fixedUpdate() {
        super.fixedUpdate();

        for (e in SolverModifier.ALL){
            if (e.isBlowing){
                var cells = e.getInformedCells();
                for(c in cells){
                setUVatIndex(c.u,c.v,c.index);
                }
            }
        }

        for (e in Boids.ALL){
            if(e.isOnSurface){
                addForce(e.cx,e.cy,e.dx,e.dy);
            }
        }

        solver.update();     
    }


    override public function postUpdate() {
        super.postUpdate();

        graphicsDebug.renderDebugGrid();
        highlightModifierCell();

    }

    private function turnOffFanCells() {
        for (e in SolverModifier.ALL){
            var l = e.getInformedCellsIndex();
            graphicsDebug.turnOffListOfCells(l);
        }
    }

    private function highlightModifierCell() {
        for (e in SolverModifier.ALL){
            var index = computeSolverIndexFromCxCy(e.cx,e.cy);
            graphicsDebug.pushSelectedCell(index);
        }
    }

    public function addForce(cx:Int, cy:Int, dx:Float, dy:Float):Void {
		var speed:Float = dx * dx  + dy * dy * aspectRatio2;
		if(speed > 0) {
			var velocityMult:Float = 20.0;
			var index:Int = solver.getIndexForCellPosition(cx,cy);

			solver.uOld[index] += dx * velocityMult;
			solver.vOld[index] += dy * velocityMult;
		}
	}

    private function setUVatIndex(u:Float,v:Float,index:Int){
        solver.u[index] = u;
        solver.v[index] = v;
        solver.uOld[index] = u;
        solver.vOld[index] = v;
    }

	public  function getUVatCoord(cx:Int,cy:Int) {
        if (testIfCellIsInGrid(cx,cy)){
            var index = solver.getIndexForCellPosition(cx,cy);
            return new Vector(solver.u[index],solver.v[index]);
        }
        return new Vector(0,0);    
    }

    public function  computeSolverIndexFromCxCy(cx:Int,cy:Int){
        var index = solver.getIndexForCellPosition(cx,cy);
        return index;
    }

    public function testIfIndexIsInArray(cellIndex:Int) {
		if (cellIndex >= 0 && cellIndex < solver.numCells)
			return true;
		return false;
	}

    public function testIfCellIsInGrid(cx:Int,cy:Int){
        if (cx >= 0 && cx < solver.width && cy >=0 && cy < solver.height )
            return true;
     
        return false;   
    }

	override public function onDispose() {
		super.onDispose();
        graphicsDebug.dispose();
        Boids.ALL = [];
        SolverModifier.ALL=[];
	}
   
}