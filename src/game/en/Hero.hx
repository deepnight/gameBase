package en;

class Hero extends Entity {
	var ca : ControllerAccess<GameAction>;
	var pressQueue : Map<GameAction, Float> = new Map();
	var comboCpt = 0;

	public function new(d:Entity_PlayerStart) {
		super();
		useLdtkEntity(d);
		camera.trackEntity(this, true);
		ca = App.ME.controller.createAccess();

		circularWeightBase = 1;
		circularRadius = 3;

		spr.set(Assets.entities);

		spr.anim.registerStateAnim(D.ent.kDodgeEnd, 2.1, ()->hasAffect(Dodge) && getAffectRemainingS(Dodge)<=0.3);
		spr.anim.registerStateAnim(D.ent.kDodgeDive, 2.0, ()->hasAffect(Dodge) && !onGround);
		spr.anim.registerStateAnim(D.ent.kDodgeRoll, 2.0, ()->hasAffect(Dodge) && onGround);
		spr.anim.registerStateAnim(D.ent.kDodgeCharge, 2.0, ()->isChargingAction("dodge"));

		spr.anim.registerStateAnim(D.ent.kKickA_charge, 1, ()->isChargingAction("kickA"));
		spr.anim.registerStateAnim(D.ent.kPunchC_charge, 1, ()->isChargingAction("punchC"));
		spr.anim.registerStateAnim(D.ent.kPunchB_charge, 1, ()->isChargingAction("punchB"));
		spr.anim.registerStateAnim(D.ent.kPunchA_charge, 1, ()->isChargingAction("punchA"));
		spr.anim.registerStateAnim(D.ent.kIdle, 0);

		spr.anim.registerTransition(D.ent.kDodgeEnd, "*", D.ent.kDodgeEndToIdle);
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
		if( ca.isPressed(a) || pressQueue.exists(a) && stime-pressQueue.get(a)<=0.3 ) {
			pressQueue.set(a,-1);
			return true;
		}
		else
			return false;
	}

	inline function controlsLocked() {
		return !isAlive() || cd.has("controlsLock") || isChargingAction() || hasAffect(Dodge) || hasAffect(Stun);
	}

	var _atkVictims : FixedArray<Mob> = new FixedArray(20); // alloc cache
	function getVictims() {
		_atkVictims.empty();
		for(e in en.Mob.ALL)
			if( distPx(e)<=24 && dirTo(e)==dir )
				_atkVictims.push(e);
		return _atkVictims;
	}

	override function postUpdate() {
		super.postUpdate();
		if( spr.anim.isPlaying(D.ent.kDodgeRoll) ) {
			outline.enable = false;
			outline.top = false;
			outline.left = false;
			outline.right = true;
		}
		else {
			outline.enable = true;

			outline.top = outline.left = outline.right = true;
		}
	}

	override function frameUpdate() {
		super.frameUpdate();

		queueCommandPress(Atk);
		queueCommandPress(Dodge);

		if( !controlsLocked() ) {
			var stickDist = ca.getAnalogDist4(MoveLeft,MoveRight,MoveUp,MoveDown);

			// Walk around
			var s = 0.015;
			if( stickDist>0 ) {
				cancelMove();
				var ang = ca.getAnalogAngle4(MoveLeft,MoveRight,MoveUp,MoveDown);
				dx+=Math.cos(ang)*stickDist*s * tmod;
				dy+=Math.sin(ang)*stickDist*s * tmod;
				dir = ca.isDown(MoveLeft) ? -1 : ca.isDown(MoveRight) ? 1 : dir;
			}

			// Dodge
			if( isPressedOrQueued(Dodge) ) {
				var ang = ca.getAnalogAngle4(MoveLeft,MoveRight,MoveUp,MoveDown);
				if( stickDist<=0.1 )
					ang = dirToAng();
				spr.anim.stopWithStateAnims();
				chargeAction("dodge", 0.1, ()->{
					game.addSlowMo("dodge", 0.2, 0.5);
					dz = 0.12;
					setAffectS(Dodge, 0.8);
					var s = 0.25;
					dodgeDx = Math.cos(ang)*s;
					dodgeDy = Math.sin(ang)*s;
				});
			}

			// Attack
			if( isPressedOrQueued(Atk) ) {
				mulVelocities(0.4);
				spr.anim.stopWithStateAnims();
				switch comboCpt {
					case 0,1:
						chargeAction("punchA", 0.1, ()->{
							lockControlS(0.06);
							for(e in getVictims()) {
								e.hit(0,this);
							}
							dx += dir*0.02;
							spr.anim.play(D.ent.kPunchA_hit);
						});
						comboCpt++;

					case 2:
						chargeAction("punchB", 0.15, ()->{
							lockControlS(0.1);
							for(e in getVictims()) {
								e.hit(0,this);
								e.bump(dir*0.04, 0);
							}
							dx += dir*0.04;
							spr.anim.play(D.ent.kPunchB_hit);
							camera.bump(dir*1,0);
						});
						comboCpt++;

						case 3:
							game.addSlowMo("heroKick", 0.3, 0.4);
							dz = 0.12;
							dx+=dir*0.1;
							chargeAction("kickA", 0.16, ()->{
								dx+=dir*0.1;
								dz = 0.05;
								camera.bumpZoom(-0.03);
								game.addSlowMo("heroKick", 0.5, 0.8);
								lockControlS(0.3);
								camera.bump(dir*1, 0);
								spr.anim.play(D.ent.kKickA_hit);

								for(e in getVictims()) {
									e.hit(0,this);
									e.cd.setS("pushOthers",1);
									e.bumpAwayFrom(this, 0.3);
									e.dz = 0.2;
									e.setAffectS(Stun, 1.5);
								}
							});
							comboCpt = 0;

					case 4:
						chargeAction("punchC", 0.2, ()->{
							lockControlS(0.25);
							for(e in getVictims()) {
								e.hit(0,this);
								e.bump(0.5*dir, 0);
								e.dz = 0.1;
								e.setAffectS(Stun, 1.5);
							}
							game.addSlowMo("powerAtk", 0.5, 0.6);
							dx += dir*0.15;
							spr.anim.play(D.ent.kPunchC_hit);
							camera.bump(dir*4,0);
						});
						comboCpt = 0;
				}
				cd.setS("keepCombo", 0.4);
			}

			// Lose attack combo
			if( comboCpt>0 && !cd.has("keepCombo") )
				comboCpt = 0;
		}
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( hasAffect(Dodge) && onGround ) {
			mulVelocities(0.95);
		}
	}

}