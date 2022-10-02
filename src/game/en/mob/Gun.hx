package en.mob;

class Gun extends Mob {
	var maxAmmo = 0;
	var ammo = 0;
	var maxDistY = 3;
	var minDistX = 3;
	var maxDistX = 6;

	public function new(d) {
		super(d);

		spr.anim.registerStateAnim(D.ent.mGun_reload, 1, ()->isChargingAction("reload"));
		spr.anim.registerStateAnim(D.ent.mGun_charge, 1, ()->isChargingAction("shoot"));
	}

	override function setAffectS(k:Affect, t:Float, allowLower:Bool = false) {
		// switch k {
		// 	case Stun,LayDown:
		// 		t *= 1-0.5*rankRatio;

		// 	case Dodge, Shield:
		// }
		super.setAffectS(k, t, allowLower);
	}

	override function initRank() {
		super.initRank();

		switch rank {
			case 0:
				weapon = Assets.tiles.h_get(D.tiles.equipPistol);
				weapon.setPivotCoord(1,1);
				maxAmmo = 1;

			case 1:
				weapon = Assets.tiles.h_get(D.tiles.equipMachineGun);
				weapon.setPivotCoord(3,2);
				maxAmmo = 1;

			case 2:
				weapon = Assets.tiles.h_get(D.tiles.equipMachineGun);
				weapon.setPivotCoord(3,2);
		}

		spr.addChild(weapon);
	}

	override function getMoveSpeed():Float {
		return super.getMoveSpeed() * switch rank {
			case 0: 1.8;
			case 1: 2;
			case _: 2.2;
		};
	}

	inline function inShootSpot(x:Float, y:Float) {
		return M.fabs(x-hero.attachX) > minDistX*G
			&& M.fabs(x-hero.attachX) < maxDistX*G
			&& M.fabs(y-hero.attachY) < maxDistY*G;
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( !aiLocked() ) {
			dir = dirTo(hero);


			if( hasMoveTarget() ) {
				// Stop if safe
				if( inShootSpot(attachX,attachY) )
					cancelMove();

				// Invalid move target
				if( !inShootSpot(moveTarget.levelX, moveTarget.levelY) )
					cancelMove();
			}


			// Find a good shoot spot
			if( !hasMoveTarget() && !inShootSpot(attachX,attachY) ) {
				var dh = new dn.DecisionHelper(level.cachedEmptyPoints);
				dh.remove( pt->!inShootSpot(pt.levelX,pt.levelY) );
				dh.score( pt->-pt.distCase(hero)*0.5 );
				dh.score( pt->-M.iabs(pt.cy-hero.cy)*0.2 );
				dh.score( pt->dirTo(hero)<0 && pt.cx>cx || dirTo(hero)>0 && pt.cx<cx ? 3 : 0 );
				dh.score( _->rnd(0,2) );

				var pt = dh.getBest();
				gotoCase(pt.cx, pt.cy);
			}

			if( !hasMoveTarget() ) {
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
					chargeAction("reload", 0.6, ()->{
						ammo = maxAmmo;
						lockAiS(0.3);
					});
				}
			}
		}

		if( !cd.has("keepWeaponRot") )
			weaponRot = 0;
	}

}