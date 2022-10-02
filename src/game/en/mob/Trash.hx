package en.mob;

class Trash extends Mob {
	public function new(d) {
		super(d);
		initLife(5);
		spr.anim.registerStateAnim(D.ent.mPunch_charge, 1, ()->isChargingAction("punch"));
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
					spr.anim.play(D.ent.mPunch_hit);
					if( hero.canBeHit() )
						if( dirTo(hero)==dir && M.fabs(hero.attachX-attachX)<Const.GRID*1.2 && M.fabs(hero.attachY-attachY)<=Const.GRID )
							hero.hit(1, this);
				});
			}
		}
	}

}