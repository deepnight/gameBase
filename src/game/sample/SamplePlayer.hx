package sample;

//import solv.ViiEmitter;
import solv.SolverModifier;


/**
	SamplePlayer is an Entity with some extra functionalities:
	- falls with gravity
	- has basic level collisions
	- controllable (using gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/

class SamplePlayer extends Entity {
	var ca : ControllerAccess<GameAction>;
	var xSpeed = 0.;
	var ySpeed = 0.;

	// This is TRUE if the player is not falling
	var onGround(get,never) : Bool;
		inline function get_onGround() return !destroyed && dy==0 && yr==1 && level.hasCollision(cx,cy+1);

	//var emit :ViiEmitter;
	var fan :SolverModifier;

	public function new() {
		super(5,5);
		//emit = new ViiEmitter(5,5);
		fan = new SolverModifier(5,5,this);
		// Start point using level entity "PlayerStart"
		var start = level.data.l_Entities.all_PlayerStart[0];

		if( start!=null )
			setPosCase(start.cx, start.cy);
			//emit.setPosCase(start.cx,start.cy);
			//fan.setPosCase(start.cx,start.cy);

		// Misc inits
		frictX = 0.84;
		frictY = 0.94;

		// Camera tracks this
		camera.trackEntity(this, true);
		camera.clampToLevelBounds = true;

		// Init controller
		ca = App.ME.controller.createAccess();
		ca.lockCondition = Game.isGameControllerLocked;

		// Placeholder display
		var g = new h2d.Graphics(spr);
		g.beginFill(0x00ff00);
		g.drawCircle(0,-hei*0.5,9);
	}


	override function dispose() {
		super.dispose();
		ca.dispose(); // don't forget to dispose controller accesses
	}


	/** X collisions **/
	override function onPreStepX() {
		super.onPreStepX();

		// Right collision
		if( xr>0.8 && level.hasCollision(cx+1,cy) )
			xr = 0.8;

		// Left collision
		if( xr<0.2 && level.hasCollision(cx-1,cy) )
			xr = 0.2;
	}


	/** Y collisions **/
	override function onPreStepY() {
		super.onPreStepY();

		// Land on ground
		if( yr>1 && level.hasCollision(cx,cy+1) ) {
			setSquashY(0.5);
			dy = 0;
			yr = 1;
			ca.rumble(0.2, 0.06);
			onPosManuallyChanged();
		}

		// Ceiling collision
		if( yr<0.2 && level.hasCollision(cx,cy-1) )
			yr = 0.2;
	}


	/**
		Control inputs are checked at the beginning of the frame.
		VERY IMPORTANT NOTE: because game physics only occur during the `fixedUpdate` (at a constant 30 FPS), no physics increment should ever happen here! What this means is that you can SET a physics value (eg. see the Jump below), but not make any calculation that happens over multiple frames (eg. increment X speed when walking).
	**/
	override function preUpdate() {
		super.preUpdate();

		xSpeed = 0;
		ySpeed = 0;
		//emit.setBlowingStatus(false);
		
		if( onGround )
			cd.setS("recentlyOnGround",0.1); // allows "just-in-time" jumps


		// Jump
		if( cd.has("recentlyOnGround") && ca.isPressed(Jump) ) {
			dy = -0.85;
			setSquashX(0.6);
			cd.unset("recentlyOnGround");
			fx.dotsExplosionExample(centerX, centerY, 0xffcc00);
			ca.rumble(0.05, 0.06);
		}
		if (!ca.isDown(Blow)){
			//emit.setBlowingStatus(false);
		}

		if (ca.isDown(Blow)){
			//emit.blow(dx,dy);
			//emit.setBlowingStatus(true); 
		}

		if (ca.isDown(ShapeWind)){
			if(!fan.isBlowing)
				fan.activateFan();
		}
		if (!ca.isDown(ShapeWind)){
			//emit.shape();
			if(fan.isBlowing)
				fan.deactivateFan();
		}
		// Walk
		if ( ca.getAnalogDist(MoveY)>0){
			ySpeed = ca.getAnalogValue(MoveY); 
		}
		if( ca.getAnalogDist(MoveX)>0 ) {
			// As mentioned above, we don't touch physics values (eg. `dx`) here. We just store some "requested walk speed", which will be applied to actual physics in fixedUpdate.
			xSpeed = ca.getAnalogValue(MoveX); // -1 to 1
		}
	}


	override function fixedUpdate() {
		super.fixedUpdate();

		// Gravity
		//if( !onGround )
		//	dy+=0.05;

		// Apply requested walk movement
		if( ySpeed!=0 ) {
			var speed = 0.075;
			dy += ySpeed * speed;
		} 
		if( xSpeed!=0 ) {
			var speed = 0.075;
			dx += xSpeed * speed;
		}

		//emit.dx = dx;
		//emit.dy = dy;
		//emit.setPosPixel(attachX,attachY);
	}
}