package sample;

class SampleEntity extends gm.Entity {
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

		// Controller
		ca = App.ME.controller.createAccess("entitySample");
		ca.setLeftDeadZone(0.3);
		App.ME.controller.bind(AXIS_LEFT_Y_NEG, K.UP, K.Z, K.W);
		App.ME.controller.bind(AXIS_LEFT_Y_POS, K.DOWN, K.S);

		// Placeholder representation
		var g = new h2d.Graphics(spr);
		g.beginFill(0x00ff00);
		g.drawCircle(0,-hei*0.5,9);
	}

	override function dispose() {
		super.dispose();
		ca.dispose();
	}

	// X physics
	override function onPreStepX() {
		super.onPreStepX();

		if( xr>0.8 && level.hasCollision(cx+1,cy) )
			xr = 0.8;

		if( xr<0.2 && level.hasCollision(cx-1,cy) )
			xr = 0.2;
	}

	// Y physics
	override function onPreStepY() {
		super.onPreStepY();

		if( yr>1 && level.hasCollision(cx,cy+1) ) {
			setSquashY(0.5);
			yr = 1;
		}

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
			cd.setS("recentOnGround",0.1);
			dy = 0;
		}

		// Jump
		if( cd.has("recentOnGround") && ca.aPressed() ) {
			dy = -0.35;
			onGround = false;
			setSquashX(0.5);
			cd.unset("recentOnGround");
		}

		// Walk around
		if( !App.ME.anyInputHasFocus() && ca.leftDist()>0 ) {
			var s = 0.015;
			dx += Math.cos( ca.leftAngle() ) * s*tmod * ca.leftDist();
		}
	}
}