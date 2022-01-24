
import solv.SolverModifier;
import solv.DebugSolver;
//import solv.ViiEmitter;
import solv.FluidSolver;
import h3d.Vector;
import hxd.Math;
import h2d.SpriteBatch;

class Solver extends dn.Process {
	var game(get,never) : Game; inline function get_game() return Game.ME;
	var level(get,never) : Level; inline function get_level() return Game.ME.level;

	//var solver : tools.FluidSolver;

    /** Width in nb cells **/
    
	//for aspect ratio func// 
    /** width in pixel **/
    public var width(get,never) : Int; inline function get_width() return Std.int(level.pxWid);
    public var height(get,never): Int; inline function get_height()return Std.int(level.pxHei);
    
    public var isw(get,never): Float; inline function get_isw() return 1 / width;
    public var ish(get,never): Float; inline function get_ish() return 1 / width;

	public var aspectRatio(get,never):Float ;inline function get_aspectRatio() return width * ish;
	public var aspectRatio2(get,never):Float;inline function get_aspectRatio2() return aspectRatio * aspectRatio;

    public var FLUID_WIDTH(get,never) : Int; inline function get_FLUID_WIDTH() return level.cWid;
    public var FLUID_HEIGHT(get,never):Int; inline function get_FLUID_HEIGHT() return Std.int( FLUID_WIDTH * height / width );
    
    var graphicsDebug:solv.DebugSolver;

	var frame:Int;  
    //solver grid width hei shorcut for list parcour
    public var sw:Int;
    public var sh:Int; 
    var boundOffset:Int;
    public var caseOffset:Int;

	public var solver:solv.FluidSolver;

	public function new() {
		super(Game.ME);

		solver = new FluidSolver( FLUID_WIDTH, FLUID_HEIGHT );
		//solver.isRGB = false;
		solver.fadeSpeed = 0.05;
		solver.deltaT = 0.5/Const.FIXED_UPDATE_FPS;
		solver.viscosity = .0000003;//**0^8**/
		solver.vorticityConfinement = true; //false;//true;
        solver.solverIterations = 1;

        
        graphicsDebug = new DebugSolver(solver);

        //init start value//
        /* for (i in 0...solver.rOld.length) {
			solver.rOld[i] = solver.gOld[i] = solver.bOld[i] = 0;
		} */

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

        solver.update();     
    }


    override public function postUpdate() {
        super.postUpdate();
        //turnOffFanCells();
        graphicsDebug.updateGridDebugDraw();
    }

    private function turnOffFanCells() {
        for (e in SolverModifier.ALL){
            var l = e.getInformedCellsIndex();
            graphicsDebug.turnOffListOfCells(l);
        }
    }

    public function addForce(x:Int, y:Int, dx:Float, dy:Float, rgb:Vector):Void {
		var speed:Float = dx * dx  + dy * dy * aspectRatio2;    // balance the x and y components of speed with the screen aspect ratio
		rgb.toColor();
		if(speed > 0) {
			var velocityMult:Float = 20.0;
			
			var index:Int = solver.getIndexForCellPosition(x,y);
			
			//solver.rOld[index]  = rgb.r;
			//solver.gOld[index]  = rgb.g;
			//solver.bOld[index]  = rgb.b;
			
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
	}

   
}