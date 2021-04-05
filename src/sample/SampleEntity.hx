package sample;

class SampleEntity extends gm.Entity {
	var ca : ControllerAccess;

	public function new() {
		super(5,5);

		frict = 0.93;

		camera.trackEntity(this, true);
		camera.clampToLevelBounds = true;

		ca = Main.ME.controller.createAccess("entitySample");
		ca.setLeftDeadZone(0.3);

		Main.ME.controller.bind(AXIS_LEFT_Y_NEG, K.UP, K.Z, K.W);
		Main.ME.controller.bind(AXIS_LEFT_Y_POS, K.DOWN, K.S);
	}

	override function dispose() {
		super.dispose();
		ca.dispose();
	}

	override function onPreStepX() {
		super.onPreStepX();

		if( xr>0.8 && level.hasCollision(cx+1,cy) )
			xr = 0.8;

		if( xr<0.2 && level.hasCollision(cx-1,cy) )
			xr = 0.2;
	}

	override function onPreStepY() {
		super.onPreStepY();

		if( yr>0.8 && level.hasCollision(cx,cy+1) )
			yr = 0.8;

		if( yr<0.2 && level.hasCollision(cx,cy-1) )
			yr = 0.2;
	}

	override function update() {
		super.update();

		if( ca.leftDist()>0 ) {
			var s = 0.010;
			dx += Math.cos( ca.leftAngle() ) * s*tmod;
			dy += Math.sin( ca.leftAngle() ) * s*tmod;
		}
	}
}