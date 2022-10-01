package en.mob;

class Gun extends Mob {
	var maxAmmo = 2;
	var ammo = 0;

	public function new(d) {
		super(d);

		spr.anim.registerStateAnim(D.ent.mGun_reload, 1, ()->isChargingAction("reload"));
		spr.anim.registerStateAnim(D.ent.mGun_charge, 1, ()->isChargingAction("shoot"));
	}

	override function setAffectS(k:Affect, t:Float, allowLower:Bool = false) {
		switch k {
			case Stun,LayDown:
				t *= 1-0.5*rankRatio;

			case Dodge, Shield:
		}
		super.setAffectS(k, t, allowLower);
	}

	override function initRank() {
		super.initRank();

		switch rank {
			case 0:
				weapon = Assets.tiles.h_get(D.tiles.equipPistol);
				weapon.setPivotCoord(1,1);

			case 1:
				weapon = Assets.tiles.h_get(D.tiles.equipMachineGun);
				weapon.setPivotCoord(3,2);

			case 2:
				weapon = Assets.tiles.h_get(D.tiles.equipChainsaw);
				weapon.setPivotCoord(3, weapon.tile.height-3);
		}

		spr.addChild(weapon);
	}

	override function getMoveSpeed():Float {
		return super.getMoveSpeed() * switch rank {
			case 0: 1;
			case 1: 1.5;
			case _: 2.5;
		};
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( !aiLocked() ) {
			dir = dirTo(hero);
			// goto(hero.attachX, hero.attachY);

			if( ammo>0 ) {
				// Attack
				chargeAction("shoot", 1, ()->{
					camera.shakeS(0.2, 0.1);
					lockAiS(0.8 - rankRatio*0.3);
					spr.anim.playOverlap(D.ent.mGun_shoot);
					weaponRot = -0.3;
					cd.setS("keepWeaponRot",0.2);
					ammo--;
				});
			}
			else {
				// Reload
				chargeAction("reload", 1, ()->{
					ammo = maxAmmo;
					lockAiS(0.3);
				});
			}
			// if( distPx(hero)<=Const.GRID*1.2 ) {
				// var ct = switch rank {
				// 	case 0 : 0.7;
				// 	case 1 : 0.3;
				// 	case _ : 0.5;
				// }
			// }
		}

		if( !cd.has("keepWeaponRot") )
			weaponRot = 0;
	}

}