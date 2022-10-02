package en.mob;

class Gun extends Mob {
	var aimAng = 0.;
	var maxAmmo = 0;
	var burstCount = 1;
	var burstDelayS = 0.;
	var chargeTimeS = 0.;
	var reloadTimeS = 0.;
	var ammo = 0;
	var pendingBullets = 0;

	var maxDistY = 3;
	var minDistX = 1.5;
	var maxDistX = 4;

	public function new(d) {
		super(d);

		armor = 1;
		initLife(5);

		spr.anim.registerStateAnim(D.ent.mGun_hold, 2, ()->pendingBullets>0);
		spr.anim.registerStateAnim(D.ent.mGun_reload, 1, ()->isChargingAction("reload"));
		spr.anim.registerStateAnim(D.ent.mGun_charge, 1, ()->isChargingAction("shoot"));
	}

	override function setAffectS(k:Affect, t:Float, allowLower:Bool = false) {
		if( k==Stun )
			pendingBullets = 0;
		super.setAffectS(k, t, allowLower);
	}

	override function onDie() {
		super.onDie();
		pendingBullets = 0;
	}

	override function initRank() {
		super.initRank();

		switch rank {
			case 0:
				weapon = Assets.tiles.h_get(D.tiles.equipPistol);
				weapon.setPivotCoord(1,1);
				ammo = maxAmmo = 2;
				burstCount = 1;
				chargeTimeS = 0.7;
				reloadTimeS = 0.5;

			case 1:
				weapon = Assets.tiles.h_get(D.tiles.equipMachineGun);
				weapon.setPivotCoord(3,2);
				ammo = maxAmmo = 2;
				burstCount = 5;
				burstDelayS = 0.1;
				chargeTimeS = 1;
				reloadTimeS = 1;

			case 2:
				weapon = Assets.tiles.h_get(D.tiles.equipMachineGun);
				weapon.setPivotCoord(3,2);
				sprScaleX = sprScaleY = 1.5;
		}

		spr.addChild(weapon);
	}

	override function getMoveSpeed():Float {
		return super.getMoveSpeed() * switch rank {
			case 0: 2;
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

		if( !aiLocked() && pendingBullets>0 && !cd.has("bulletLock") ) {
			// Aim follow
			var delta = M.radSubstract( angTo(hero), aimAng );
			aimAng += delta*0.8;
			aimAng = M.radClamp(aimAng, dirToAng(), 0.4);

			// Shoot bullet
			new Bullet(attachX+dir*2, attachY, aimAng, 0.2);
			camera.shakeS(0.2, 0.1);
			spr.anim.playOverlap(D.ent.mGun_shoot);
			weaponRot = -0.3;
			cd.setS("keepWeaponRot",0.2);

			pendingBullets--;
			cd.setS("bulletLock", burstDelayS);
			if( pendingBullets==0 )
				lockAiS(0.25);
		}

		if( !aiLocked() && pendingBullets==0 ) {
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
					aimAng = angTo(hero);
					chargeAction("shoot", chargeTimeS, ()->{
						pendingBullets = burstCount;
						ammo--;
					}, (t)->{
						// Aim during charge
						if( t>0.2 ) {
							fx.markerFree(hero.attachX, hero.attachY, 0.06, Red);
							aimAng = angTo(hero);
						}
					});
				}
				else {
					// Reload
					chargeAction("reload", reloadTimeS, ()->{
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