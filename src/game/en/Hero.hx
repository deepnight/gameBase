package en;

class Hero extends Entity {
	var ca : ControllerAccess<GameAction>;
	var pressQueue : Map<GameAction, Float> = new Map();

	public function new(data:Entity_PlayerStart) {
		super(data.cx, data.cy);
		camera.trackEntity(this, true);
		ca = App.ME.controller.createAccess();

		circularWeight = 0.3;

		spr.set(Assets.entities, D.ent.kIdle);
		var f = new dn.heaps.filter.PixelOutline( Assets.dark() );
		f.bottom = false;
		spr.filter = f;

		spr.anim.registerStateAnim(D.ent.kPunchB_charge, 1, ()->isChargingAction("atkB"));
		spr.anim.registerStateAnim(D.ent.kPunchA_charge, 1, ()->isChargingAction("atkA"));
		spr.anim.registerStateAnim(D.ent.kIdle, 0);
	}

	override function dispose() {
		super.dispose();
		ca.dispose();
	}

	inline function unlockControls() {
		cd.unset("controlsLock");
	}

	inline function lockControlS(t:Float) {
		cd.setS("controlsLock", t, false);
	}

	inline function queueCommandPress(a:GameAction) {
		if( ca.isPressed(a) )
			pressQueue.set(a, stime);
	}

	inline function isPressedOrQueued(a:GameAction) {
		if( ca.isPressed(a) || stime-pressQueue.get(a)<=0.3 ) {
			pressQueue.set(a,-1);
			return true;
		}
		else
			return false;
	}

	inline function controlsLocked() {
		return !isAlive() || cd.has("controlsLock");
	}

	override function frameUpdate() {
		super.frameUpdate();

		queueCommandPress(Atk);

		if( !controlsLocked() ) {
			// Walk around
			var s = 0.015;
			var d = ca.getAnalogDist4(MoveLeft,MoveRight,MoveUp,MoveDown);
			if( d>0 ) {
				cancelMove();
				var ang = ca.getAnalogAngle4(MoveLeft,MoveRight,MoveUp,MoveDown);
				dx+=Math.cos(ang)*d*s * tmod;
				dy+=Math.sin(ang)*d*s * tmod;
				dir = ca.isDown(MoveLeft) ? -1 : ca.isDown(MoveRight) ? 1 : dir;
			}

			// Punch
			if( isPressedOrQueued(Atk) ) {
				dx*=0.5;
				dy*=0.5;
				spr.anim.stopWithStateAnims();
				if( !cd.has("allowB") ) {
					cd.setS("allowB",0.6);
					lockControlS(0.25);
					chargeAction("atkA", 0.1, ()->{
						dx += dir*0.05;
						spr.anim.play(D.ent.kPunchA_hit);
					});
				}
				else {
					cd.unset("allowB");
					lockControlS(0.35);
					chargeAction("atkB", 0.2, ()->{
						dx += dir*0.1;
						spr.anim.play(D.ent.kPunchB_hit);
					});
				}
			}
		}

	}

	override function fixedUpdate() {
		super.fixedUpdate();
	}

}