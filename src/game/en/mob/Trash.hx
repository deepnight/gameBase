package en.mob;

class Trash extends Mob {
	public function new(d) {
		super(d);
		initLife(1);

		outline.color = Assets.black();

		spr.anim.removeAllStateAnims();
		spr.anim.registerStateAnim(D.ent.tPunch_charge, 1, ()->isChargingAction("punch"));

		spr.anim.registerStateAnim(D.ent.tFly, 10.2, ()->!onGround);
		spr.anim.registerStateAnim(D.ent.tLay, 10.1, ()->isLayingDown());
		spr.anim.registerStateAnim(D.ent.tStun, 10.0, ()->hasAffect(Stun));

		spr.anim.registerStateAnim(D.ent.tWalk, 0.1, ()->isMoving());

		spr.anim.registerStateAnim(D.ent.tIdle, 0);
	}

	override function hit(dmg:Int, from:Null<Entity>) {
		super.hit(dmg, from);
		if( !isChargingAction() && !isLayingDown() )
			spr.anim.playOverlap(D.ent.tHit);
	}

	override function increaseRank() {} // nope

	override function fixedUpdate() {
		super.fixedUpdate();

		if( !aiLocked() && hero.isAlive() ) {
			// Follow hero
			dir = dirTo(hero);
			gotoPx(hero.attachX, hero.attachY);

			// Melee attack
			if( distPx(hero)<=Const.GRID*1.2 ) {
				chargeAction("punch", 1, ()->{
					lockAiS(0.6);
					spr.anim.play(D.ent.tPunch_hit);
					if( hero.canBeHit() )
						if( dirTo(hero)==dir && M.fabs(hero.attachX-attachX)<Const.GRID*1.2 && M.fabs(hero.attachY-attachY)<=Const.GRID )
							hero.hit(1, this);
				});
			}
		}
	}

}