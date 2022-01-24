package en;

import hxd.Math;
import h3d.Vector;
import solv.FluidSolver;

// ici pouront etre iom[plementer] differente steering behaviors de reynols ou des trajet plus basique  ?
// un state enum de behaviors une fonction compute qui switche entre les differentes demandes 
// la possibilite de desactive les behaviors par le bool is Autonomous permet d'utiliser le boids 
//comme simple "lecteur" de vent
 
class Boids extends Entity{
    
    public var solver(get,never):Solver; inline function get_solver() return Game.ME.solver;
    public var maxSpeed = 0.1;
    public var maxForce = 1;

    var location:Vector;
    var velocity:Vector;
    var acceleration:Vector;
    var desired:Vector;
    var angle:Float;

    var tarLocation:Vector;
    var tarAngle:Float = 0 ;
    
    var index:Int;
    var autonomy:Bool = true;
    
    var isAutonomous(get,never):Bool; inline function get_isAutonomous() return autonomy;

    
    public function new(x:Int,y:Int) {
        super(x,y);
        
        location     = new Vector(attachX,attachY);
        velocity     = new Vector(dx,dy);
        acceleration = new Vector(0,0);
        desired      = new Vector(0,0);
        tarLocation  = new Vector(attachX+(Math.cos(tarAngle)*30),attachY+(Math.sin(tarAngle)*30));
        

        spr.set(D.tiles.fxCircle15);
        spr.colorize(0x0ea0ff);
        
    }

    override public function fixedUpdate() {
        super.fixedUpdate();
        
        if (!solver.testIfCellIsInGrid(cx,cy))
            destroy();


        tarLocation.x = Math.floor(attachX+(Math.cos(tarAngle)*60));
        tarLocation.y = Math.floor(attachY+(Math.sin(tarAngle)*60));

        var steer = computeFlowfieldSteering();

        if(isAutonomous)
            dx += steer.x;
            dy += steer.y;
        
    }
    

    public function computeFlowfieldSteering() {
        velocity.x = dx;
        velocity.y = dy;

        desired = solver.getUVatCoord(cx,cy); 
        angle = Math.atan2(desired.y,desired.x);
        
        var l = desired.length();
        desired.multiply(maxSpeed*l);
        var steer = desired.sub(velocity);
        return steer;
    }
}

/*     function capMaxForce(steer:Vector) {
        if (desired.lengthSq() > maxForce*maxForce){
            steer.normalize();
            steer.multiply(maxForce);
        }
    } */
