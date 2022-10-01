package en;

class Hero extends Entity {
	var ca : ControllerAccess<GameAction>;
	var moveTarget : LPoint;

	public function new(data:Entity_PlayerStart) {
		super(data.cx, data.cy);
		ca = App.ME.controller.createAccess();
		camera.trackEntity(this, true);
		moveTarget = new LPoint();
	}

	override function dispose() {
		super.dispose();
		ca.dispose();
	}

	public function goto(x,y) {
		moveTarget.setLevelPixel(x,y);
	}

	final brakeDist = 16;
	override function fixedUpdate() {
		super.fixedUpdate();

		var d = distPx(moveTarget.levelX, moveTarget.levelY);
		if( d>2 ) {
			var a = Math.atan2(moveTarget.levelY-attachY, moveTarget.levelX-attachX);
			var s = 0.05 * M.fmin(1, d/brakeDist);
			dx+=Math.cos(a)*s;
			dy+=Math.sin(a)*s;
		}

		if( d<=brakeDist ) {
			dx*=0.8;
			dy*=0.8;
		}
	}

}