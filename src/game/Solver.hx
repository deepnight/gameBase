import hxsl.Types.Vec;
import solv.ViiEmitter;
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
    
	var frame:Int;  
    //solver grid width hei shorcut for list parcour
    var sw:Int;
    var sh:Int; 
    var boundOffset:Int;
    var caseOffset:Int;

	public var solver:solv.FluidSolver;

    var sb : h2d.SpriteBatch;
    var cells : Array<h2d.SpriteBatch.BatchElement>;
    public var directions : Array<h2d.SpriteBatch.BatchElement>;
    
	public function new() {
		super(Game.ME);

		solver = new FluidSolver( FLUID_WIDTH, FLUID_HEIGHT );
		solver.isRGB = false;
		solver.fadeSpeed = 0.05;
		solver.deltaT = 0.5/Const.FIXED_UPDATE_FPS;
		solver.viscosity = .0000003;//**0^8**/
		solver.vorticityConfinement = true; //false;//true;
        solver.solverIterations = 1;

        

        //init start value//
        for (i in 0...solver.rOld.length) {
			solver.rOld[i] = solver.gOld[i] = solver.bOld[i] = 0;
		}

        cells = [];
        directions = [];
        sb = new h2d.SpriteBatch(h2d.Tile.fromColor(Color.makeColorRgb(1,1,1),Const.GRID,Const.GRID));
        game.scroller.add(sb,Const.DP_SOLVER);
        sb.blendMode = Add;
        sb.hasUpdate = true;
        sb.hasRotationScale = true;

        sw = solver.width;
        sh = solver.height;
        caseOffset = 1;
        boundOffset = Const.GRID * caseOffset;

        for(j in 0...sh) {
			for(i in 0...sw) {
                var be = new BatchElement(h2d.Tile.fromColor(Color.makeColorRgb(1,1,1),Const.GRID-1,Const.GRID-1));
                be.x = i*Const.GRID+1 -boundOffset;
                be.y = j*Const.GRID+1 -boundOffset;
                be.a = 0.3;
                sb.add(be);
                cells.push(be);
                var ve = new BatchElement(Assets.tiles.getTile(D.tiles.vector12));
                ve.x = i*Const.GRID-boundOffset + Const.GRID/2;
                ve.y = j*Const.GRID-boundOffset + Const.GRID/2;
                ve.rotation = 0;
                sb.add(ve);
                directions.push(ve);
			}
		}

        sb.visible = false;

	}
    
    override public function fixedUpdate() {
        super.fixedUpdate();
        for ( e in ViiEmitter.ALL){
            addForce(e.cx,e.cy,e.windX,e.windY,new Vector(1,0,1));
        } 
        solver.update();     
    }


    override public function postUpdate() {
        super.postUpdate();
    
        if( ui.Console.ME.hasFlag("grid")){
            sb.visible = true;
		    var fi:Int;
        
            for(j in 0...sh) {
                for(i in 0...sw) {
                    fi = i + (sw * j);
                    if (fi < cells.length){
                        cells[fi].r = Math.lerp(0,255,solver.r[fi]);
                        cells[fi].g = Math.lerp(0,255,solver.g[fi]);
                        cells[fi].b = Math.lerp(0,255,solver.b[fi]);
                        var a = Math.atan2(solver.v[fi],solver.u[fi]);
                        directions[fi].rotation = a;
                        directions[fi].a =1*Math.sqrt((solver.u[fi]*solver.u[fi]+solver.v[fi]*solver.v[fi]));
                    }
                }
            }
        }  
    }

    public function addForce(x:Int, y:Int, dx:Float, dy:Float, rgb:Vector):Void {
		var speed:Float = dx * dx  + dy * dy * aspectRatio2;    // balance the x and y components of speed with the screen aspect ratio
		rgb.toColor();
		if(speed > 0) {
			var velocityMult:Float = 20.0;
			
			var index:Int = solver.getIndexForCellPosition(x,y);
			
			solver.rOld[index]  = rgb.r;
			solver.gOld[index]  = rgb.g;
			solver.bOld[index]  = rgb.b;
			
			solver.uOld[index] += dx * velocityMult;
			solver.vOld[index] += dy * velocityMult;
		}
	}

    public function addEquation(_x:Int, _y:Int, w:Int, h:Int) {
        var index:Int;
        var x = _x + caseOffset;
        var y = _y + caseOffset;

        var jsy = Math.floor(y-(h/2));
        var jey = Math.floor(y+(h/2));
        var isx = Math.floor(x-(w/2));
        var iex = Math.floor(x+(w/2));

        

        for( j in jsy...jey){
            for(i in isx...iex){
                index = i+(sw*j);
                if(index >=0 && index < solver.numCells){
                    
                    var ex = Math.floor((i+caseOffset-x));
                    var ey = Math.floor((j+caseOffset-y));//-(h/2));
                    
                        solver.u[index] = -ey*0.2 -(ex*0.02);// - fSolver.v[index];
                        solver.v[index] = ex*0.2 -(ey*0.02);// 0;


                        solver.uOld[index] =  -ey*0.2-(ex*0.02);
                        solver.vOld[index] =  ex*0.2- (ey*0.02);
                }
            }
        }
    }

	public  function getUVatCoord(cx:Int,cy:Int) {
        if (isInGrid(cx,cy)){
            var index = solver.getIndexForCellPosition( cx - boundOffset,cy - boundOffset);
            return new Vector(solver.u[index],solver.v[index]);
        }
        return new Vector(0,0);    
    }

    public function isInGrid(cx:Int,cy:Int){
        if (cx >= 0 && cx < FLUID_WIDTH && cy >=0 && cy < FLUID_HEIGHT )
            return true;
     
        return false;
        
    }

	override public function onDispose() {
		super.onDispose();

		//solver.dispose(); a inventer
		sb.remove();
        cells = [];
        directions = [];
	}
}