package solv;

class ViiEmitter extends Entity {
    public static var ALL: Array<ViiEmitter> = [];
    
    public var windX(get,never) : Float; inline function get_windX() return velx;//+(dx*0.1);
    public var windY(get,never) : Float; inline function get_windY() return vely;//+(dy*0.1);

    var velx:Float = 0 ;
    var vely:Float = 0 ;
    var bBlow:Bool  = false;

    public var isBlowing(get,never) : Bool; inline function get_isBlowing() return bBlow;

    var WIND_FRICTION = 0.20;

    public function new(x:Int,y:Int) {
        super(x,y);
        ALL.push(this);
    }

    public function setBlowingStatus(bool:Bool) {
       bBlow = bool;
    }

    public function blow(dx:Float,dy:Float) {
        if(isBlowing){
            vely = dy*15;
            velx = dx*15;
        }
    }

    public function shape() {
        Game.ME.solver.addEquation(cx,cy,10,10);
    }


    override function fixedUpdate() {
        super.fixedUpdate();
        
        if(!isBlowing){
            velx *= WIND_FRICTION;
            if( M.fabs(velx) <= 0.005 ) velx = 0;
            vely *= WIND_FRICTION;
            if( M.fabs(vely) <= 0.005 ) vely = 0;
        }
    }
}