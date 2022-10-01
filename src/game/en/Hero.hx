package en;

class Hero extends Entity {
	var ca : ControllerAccess<GameAction>;
	var pressQueue : Map<GameAction, Float> = new Map();
	var comboCpt = 0;
	public var hasSuperCharge = false;

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
			if( e.isAlive() && distPx(e)<=24 && dirTo(e)==dir )
				_atkVictims.push(e);
		return _atkVictims;
	}

	override function postUpdate() {
		super.postUpdate();

		// Super charge outline
		if( hasSuperCharge ) {
			var mod = Std.int( game.stime / 0.1 ) % 3;
			outline.color = switch mod {
				case 0: Assets.blue();
				case 1: Assets.dark();
				case 2: Assets.red();
				case _: Assets.dark();
			}
		}
		else
			outline.color = Assets.dark();

		// No outline during roll anim
		if( spr.anim.isPlaying(D.ent.kDodgeRoll) )
			outline.enable = false;
		else
			outline.enable = true;
	}

	override function frameUpdate() {
		super.frameUpdate();

		var stickDist = ca.getAnalogDist4(MoveLeft,MoveRight,MoveUp,MoveDown);
		var stickAng = ca.getAnalogAngle4(MoveLeft,MoveRight,MoveUp,MoveDown);

		queueCommandPress(Atk);
		queueCommandPress(Dodge);

		// Manual dodge braking
		if( hasAffect(Dodge) && stickDist>0 ) {
			var a = getMoveAng();
			if( M.radDistance(a,stickAng)>=M.PIHALF ) {
				dodgeDx*=0.98;
				dodgeDy*=0.98;
			}
		}

		if( !controlsLocked() ) {
			var stickDist = ca.getAnalogDist4(MoveLeft,MoveRight,MoveUp,MoveDown);

			// Walk around
			var s = 0.015;
			if( stickDist>0 ) {
				cancelMove();
				dx+=Math.cos(stickAng)*stickDist*s * tmod;
				dy+=Math.sin(stickAng)*stickDist*s * tmod;
				dir = ca.isDown(MoveLeft) ? -1 : ca.isDown(MoveRight) ? 1 : dir;
			}

			// Dodge
			if( isPressedOrQueued(Dodge) ) {
				if( stickDist<=0.1 )
					stickAng = dirToAng();
				spr.anim.stopWithStateAnims();
				chargeAction("dodge", 0.1, ()->{
					game.addSlowMo("dodge", 0.2, 0.5);
					dz = 0.12;
					setAffectS(Dodge, 0.8);
					var s = 0.25;
					dodgeDx = Math.cos(stickAng)*s;
					dodgeDy = Math.sin(stickAng)*s;
				});
			}

			// Attack
			if( isPressedOrQueued(Atk) ) {
				mulVelocities(0.4);
				spr.anim.stopWithStateAnims();
				if( hasSuperCharge ) {
					hasSuperCharge = false;

					fx.flashBangEaseInS(Assets.blue(), 0.1, 0.3);
					game.addSlowMo("powerAtk", 0.3, 0.25);
					chargeAction("punchC", 0.2, ()->{
						fx.flashBangEaseInS(Assets.blue(), 0.3, 1);
						lockControlS(0.3);
						for(e in getVictims()) {
							e.cancelAction();
							e.hit(1,this);
							e.bumpAwayFrom(this,0.6);
							e.dz = 0.2;
							e.setAffectS(Stun, 2);
							e.cd.setS("pushOthers",1);
						}
						game.addSlowMo("powerAtk", 0.5, 0.6);
						dx += dir*0.2;
						spr.anim.play(D.ent.kPunchC_hit);
						camera.shakeS(1, 0.2);
						camera.bumpZoom(0.05);
					});
					comboCpt = 0;
				}
				else {
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
									e.cancelAction();
									e.hit(0,this);
									e.setAffectS(Stun, 0.5);
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
									e.cancelAction();
									e.hit(0,this);
									e.cd.setS("pushOthers",1);
									e.bumpAwayFrom(this, 0.3);
									e.dz = 0.2;
									e.setAffectS(Stun, 1.5);
								}
							});
							comboCpt = 0;
					}
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