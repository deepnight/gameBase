package en;

import hxd.Math;
import h3d.Vector;
import solv.FluidSolver;

class Bullet extends Entity {
    public var solver(get,never):Solver; inline function get_solver() return Game.ME.solver;
    public var maxSpeed = 0.1;
    public var maxForce = 1;

    var location:Vector;
    var velocity:Vector;
    var acceleration:Vector;
    var targetLoc:Vector;
    var targetAngle:Float = 0 ;
    var angle:Float;
    
    
    public function new(x:Int,y:Int) {
        super(x,y);
        
        location = new Vector(attachX,attachY);
        velocity = new Vector(dx,dy);
        acceleration = new Vector(0,0);
        targetLoc = new Vector(attachX+(Math.cos(targetAngle)*30),attachY+(Math.sin(targetAngle)*30));
        //maxForce = 1.2;
        frictX = 0.99;
        frictY = 0.99;

       // var g = new h2d.Graphics(spr);
		//g.beginFill(0x0000ff);
		//g.drawCircle(0,0,9);
        spr.set(D.tiles.fxCircle15);
        spr.colorize(0x0000ff);
        
        ///var p = new h2d.Graphics(spr);
        //p.beginFill(0xff00ff);
        //p.drawCircle(10,0,4);

        spr.setCenterRatio(0.5,1);
    }

    override public function fixedUpdate() {
        //super.fixedUpdate();
        //angle += 0.01;
        targetLoc.x = Math.floor(attachX+(Math.cos(targetAngle)*60));
        targetLoc.y = Math.floor(attachY+(Math.sin(targetAngle)*60));

        velocity.x = dx;
        velocity.y = dy;

        //var desired = solver.getUVatCoord(cx,cy);
        //angle = ;//desired.getPolar();
        var index = solver.solver.getIndexForCellPosition(cx,cy);
        //var desired = new Vector(0,0);
        //var std = new Vector(1,1);
        var desired = new Vector(solver.solver.u[index],solver.solver.v[index]);
        angle = Math.atan2(solver.solver.v[index],solver.solver.u[index]);//solver.directions[index].rotation;
        var l = desired.length();
        //desired.normalize();


        desired.multiply(maxSpeed*l);
        

        var steer = desired.sub(velocity);
        
/*         if (desired.lengthSq() > maxForce*maxForce){
            steer.normalize();
            steer.multiply(maxForce);
        } */
        
        dx += steer.x;
        dy += steer.y;

        super.fixedUpdate();
    }

/*     public PVector limit(float max) {
        if (magSq() > max*max) {
          normalize();
          mult(max);
        }
        return this;
      } */

    override function postUpdate() {
        super.postUpdate();
       // spr.rotation = angle;
    }

}