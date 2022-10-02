package en;

class Hero extends Entity {
	var ca : ControllerAccess<GameAction>;
	var pressQueue : Map<GameAction, Float> = new Map();
	var comboCpt = 0;
	public var hasSuperCharge = false;
	public var rage(default,null) = 0;

	public function new(d:Entity_PlayerStart) {
		super();
		useLdtkEntity(d);
		camera.trackEntity(this, true);
		ca = App.ME.controller.createAccess();

		circularWeightBase = 0.4;
		circularRadius = 3;
		initLife(3);

		spr.set(Assets.entities);

		spr.anim.registerStateAnim(D.ent.kFly, 10.2, ()->!onGround && !isAlive());
		spr.anim.registerStateAnim(D.ent.kLay, 10.1, ()->isLayingDown());

		spr.anim.registerStateAnim(D.ent.kDodgeEnd, 2.1, ()->hasAffect(Dodge) && getAffectRemainingS(Dodge)<=0.3);
		spr.anim.registerStateAnim(D.ent.kDodgeDive, 2.0, ()->hasAffect(Dodge) && !onGround);
		spr.anim.registerStateAnim(D.ent.kDodgeRoll, 2.0, ()->hasAffect(Dodge) && onGround);
		spr.anim.registerStateAnim(D.ent.kDodgeCharge, 2.0, ()->isChargingAction("dodge"));

		spr.anim.registerStateAnim(D.ent.kSuper_charge, 1, ()->isChargingAction("execute"));
		spr.anim.registerStateAnim(D.ent.kKickA_charge, 1, ()->isChargingAction("kickA"));
		spr.anim.registerStateAnim(D.ent.kPunchC_charge, 1, ()->isChargingAction("punchC"));
		spr.anim.registerStateAnim(D.ent.kPunchB_charge, 1, ()->isChargingAction("punchB"));
		spr.anim.registerStateAnim(D.ent.kPunchA_charge, 1, ()->isChargingAction("punchA"));
		spr.anim.registerStateAnim(D.ent.kIdle, 0);

		spr.anim.registerTransition(D.ent.kDodgeEnd, "*", D.ent.kDodgeEndToIdle);
	}

	public function addRage(n=1) {
		rage+=n;
		iconBar.empty();
		iconBar.addIcons(D.tiles.iconMark100, rage);
	}

	public function clearRage() {
		rage = 0;
		iconBar.empty();
	}

	override function hit(dmg:Int, from:Null<Entity>) {
		super.hit(dmg, from);
		setAffectS(Shield, 1);
		fx.flashBangEaseInS(Red, 0.3, 1);
		lockControlS(0.2);
		if( !isAlive() ) {
			dz = 0.17;
			bumpAwayFrom(from, 0.4);
		}
		else {
			dz = 0.11;
			bumpAwayFrom(from, 0.2);
			spr.anim.playOverlap(D.ent.kHit);
		}
	}

	override function dispose() {
		super.dispose();
		ca.dispose();
	}

	inline function unlockControls() {
		cd.unset("controlsLock");
	}

	inline function getLockRemainingS() {
		return cd.getS("controlsLock");
	}

	inline function lockControlS(t:Float) {
		cd.setS("controlsLock", t, false);
	}

	inline function queueCommandPress(a:GameAction) {
		if( ca.isPressed(a) )
			pressQueue.set(a, stime);
	}

	inline function isPressedOrQueued(a:GameAction, remove=true) {
		if( ca.isPressed(a) || pressQueue.exists(a) && stime-pressQueue.get(a)<=0.3 ) {
			if( remove )
				pressQueue.set(a,-1);
			return true;
		}
		else
			return false;
	}

	inline function controlsLocked() {
		return !isAlive() || cd.has("controlsLock") || isChargingAction() || hasAffect(Dodge) || hasAffect(Stun);
	}

	function onAnyAttack() {
		for(e in en.Destructible.ALL)
			if( inHitRange(e,1) )
				e.onPunch();
	}

	inline function inHitRange(e:Entity, rangeMul:Float) {
		return e.isAlive() && distPx(e)<=24*rangeMul && M.fabs(attachY-e.attachY)<=6+6*rangeMul && dirTo(e)==dir;
	}

	var _atkVictims : FixedArray<Mob> = new FixedArray(20); // alloc cache
	function getVictims(rangeMul:Float) {
		_atkVictims.empty();
		for(e in en.Mob.ALL)
			if( inHitRange(e, rangeMul) )
				_atkVictims.push(e);
		return _atkVictims;
	}

	override function postUpdate() {
		super.postUpdate();

		// Super charge outline
		if( rage>0 && isAlive() ) {
			var mod = Std.int( game.stime / 0.1 ) % 3;
			outline.color = switch mod {
				case 0: Assets.green();
				case 1: Assets.black();
				case 2: Assets.blue();
				case _: Assets.black();
			}
		}
		else
			outline.color = Assets.black();

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

		// Dodge can cancel a few stuff
		if( isPressedOrQueued(Dodge, false) && controlsLocked() ) {
			if( isChargingAction() && !isChargingAction("dodge") && !isChargingAction("execute") )
				cancelAction();

			if( !isChargingAction() && !hasAffect(Stun) && getLockRemainingS()<=0.09 ) {
				unlockControls();
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
				cancelAction();
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
				if( rage>0) {

					// Super attack
					fx.flashBangEaseInS(Assets.blue(), 0.1, 0.3);
					game.addSlowMo("powerAtk", 0.3, 0.25);
					chargeAction("punchC", 0.2, ()->{
						onAnyAttack();
						fx.flashBangEaseInS(Assets.green(), 0.3, 1);
						lockControlS(0.3);
						for(e in getVictims(2)) {
							e.cancelAction();
							e.addRageMarks(rage);
							// if( hasSuperCharge && e.armor>0 )
							// 	e.loseArmor();
							// else
							// e.hit(4, this);
							e.bumpAwayFrom(this,0.4);
							e.dz = 0.2;
							e.setAffectS(Stun, 1.5);
							e.cd.setS("pushOthers",1);
							// superCharge = 0;
						}
						clearRage();
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
						case 0,1: // Punch A
							chargeAction("punchA", 0.1, ()->{
								onAnyAttack();
								lockControlS(0.06);
								for(e in getVictims(1)) {
									e.cancelAction();
									e.hit(0,this);
									e.setAffectS(Stun,0.3);
								}
								dx += dir*0.02;
								spr.anim.play(D.ent.kPunchA_hit);
							});
							comboCpt++;

						case 2: // Punch B
							chargeAction("punchB", 0.15, ()->{
								onAnyAttack();
								lockControlS(0.1);
								for(e in getVictims(1.3)) {
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

						case 3: // Kick
							game.addSlowMo("heroKick", 0.3, 0.4);
							dz = 0.12;
							dx+=dir*0.1;
							chargeAction("kickA", 0.16, ()->{
								onAnyAttack();
								dx+=dir*0.1;
								dz = 0.05;
								camera.bumpZoom(-0.03);
								game.addSlowMo("heroKick", 0.5, 0.8);
								lockControlS(0.3);
								camera.bump(dir*1, 0);
								spr.anim.play(D.ent.kKickA_hit);

								for(e in getVictims(1.5)) {
									e.cancelAction();
									e.hit(0,this);
									e.cd.setS("pushOthers",1);
									e.bumpAwayFrom(this, 0.3);
									e.dz = 0.2;
									e.dropCharge = true;
									e.setAffectS(Stun, 3.5);
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