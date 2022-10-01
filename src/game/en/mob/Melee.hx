package en.mob;

class Melee extends Mob {
	public function new(d) {
		super(d);

		spr.anim.registerStateAnim(D.ent.mPunch_charge, 1, ()->isChargingAction("punch"));
	}

	override function setAffectS(k:Affect, t:Float, allowLower:Bool = false) {
		switch k {
			case Stun,LayDown:
				t *= 1-0.5*rankRatio;

			case Dodge:
		}
		super.setAffectS(k, t, allowLower);
	}

	override function initRank() {
		super.initRank();

		switch rank {
			case 0:

			case 1:
				weapon = Assets.tiles.h_get(D.tiles.equipKnife);
				weapon.setCenterRatio(0.5, 1);
				game.scroller.add(weapon, Const.DP_MAIN);

			case 2: // TODO
		}
	}

	override function getMoveSpeed():Float {
		return super.getMoveSpeed() * switch rank {
			case 0: 1;
			case 1: 1.5;
			case _: 2;
		};
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( !aiLocked() ) {
			dir = dirTo(hero);
			goto(hero.attachX, hero.attachY);

			if( distPx(hero)<=Const.GRID*1.2 ) {
				var ct = switch rank {
					case 0 : 0.7;
					case 1 : 0.3;
					case _ : 0.5;
				}
				chargeAction("punch", ct, ()->{
					lockAiS(0.5 - rankRatio*0.3);
					spr.anim.playOverlap(D.ent.mPunch_hit);
				});
			}
		}
	}

}