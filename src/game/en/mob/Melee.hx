package en.mob;

class Melee extends Mob {
	public function new(d) {
		super(d);

		spr.anim.registerStateAnim(D.ent.mPunch_charge, 1, ()->isChargingAction("punch"));
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( !aiLocked() ) {
			dir = dirTo(hero);
			goto(hero.attachX, hero.attachY);

			if( distPx(hero)<=Const.GRID*1.2 ) {
				chargeAction("punch", 0.7, ()->{
					lockAiS(0.5);
					spr.anim.playOverlap(D.ent.mPunch_hit);
				});
			}
		}
	}

}