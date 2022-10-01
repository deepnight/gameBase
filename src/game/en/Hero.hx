package en;

class Hero extends Entity {
	var ca : ControllerAccess<GameAction>;
	var pressQueue : Map<GameAction, Float> = new Map();
	var comboCpt = 0;

	public function new(data:Entity_PlayerStart) {
		super(data.cx, data.cy);
		camera.trackEntity(this, true);
		ca = App.ME.controller.createAccess();

		circularWeight = 0.3;

		spr.set(Assets.entities, D.ent.kIdle);
		var f = new dn.heaps.filter.PixelOutline( Assets.dark() );
		f.bottom = false;
		spr.filter = f;

		spr.anim.registerStateAnim(D.ent.kPunchC_charge, 1, ()->isChargingAction("atkC"));
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
		return !isAlive() || cd.has("controlsLock") || isChargingAction();
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
				mulVelocities(0.4);
				spr.anim.stopWithStateAnims();
				switch comboCpt {
					case 0,1:
						chargeAction("atkA", 0.1, ()->{
							lockControlS(0.15);
							dx += dir*0.02;
							spr.anim.play(D.ent.kPunchA_hit);
						});
						comboCpt++;

					case 2:
						chargeAction("atkB", 0.15, ()->{
							lockControlS(0.15);
							dx += dir*0.04;
							spr.anim.play(D.ent.kPunchB_hit);
							camera.bump(dir*1,0);
						});
						comboCpt++;

					case 3:
						chargeAction("atkC", 0.23, ()->{
							lockControlS(0.25);
							dx += dir*0.15;
							spr.anim.play(D.ent.kPunchC_hit);
							camera.bump(dir*4,0);
						});
						comboCpt = 0;
				}
				cd.setS("keepCombo", 0.4);
			}

			// Lose combo
			if( comboCpt>0 && !cd.has("keepCombo") )
				comboCpt = 0;
		}

	}

	override function fixedUpdate() {
		super.fixedUpdate();
	}

}