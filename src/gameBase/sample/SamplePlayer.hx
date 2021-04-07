package sample;

/**
	SamplePlayer is an Entity with some extra functionalities:
	- basic level collisions and gravity
	- controls (gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/

class SamplePlayer extends gm.Entity {
	var ca : ControllerAccess;


	public function new() {
		super(5,5);

		// Start point using level entity "PlayerStart"
		var start = level.data.l_Entities.all_PlayerStart[0];
		if( start!=null )
			setPosCase(start.cx, start.cy);

		// Inits
		frictX = 0.89;
		frictY = 0.95;

		// Camera tracks this
		camera.trackEntity(this, true);
		camera.clampToLevelBounds = true;

		// Init controller
		ca = App.ME.controller.createAccess("entitySample");
		ca.setLeftDeadZone(0.3);

		// Placeholder representation
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
			yr = 1;
		}

		// Ceiling collision
		if( yr<0.2 && level.hasCollision(cx,cy-1) )
			yr = 0.2;
	}


	override function update() {
		super.update();

		// Gravity
		var onGround = yr==1 && level.hasCollision(cx,cy+1);
		if( !onGround )
			dy+=0.015*tmod;
		else {
			cd.setS("recentOnGround",0.1); // allows "just-in-time" jumps
			dy = 0;
		}

		if( !ca.locked() ) {
			// Jump
			if( cd.has("recentOnGround") && ( ca.aPressed() || ca.isKeyboardPressed(K.SPACE) ) ) {
				dy = -0.5;
				setSquashX(0.5);
				onGround = false;
				cd.unset("recentOnGround");
			}

			// Walk around
			if( !App.ME.anyInputHasFocus() && ca.leftDist()>0 ) {
				var speed = 0.015;
				dx += Math.cos(ca.leftAngle()) * speed*tmod * ca.leftDist();
			}
		}
	}
}