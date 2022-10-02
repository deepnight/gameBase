package en.mob;

class Melee extends Mob {
	var dashAng = 0.;
	var hitDmg = 1;

	public function new(d) {
		super(d);

		sprScaleX = sprScaleY = 1.25;
		// armor = 1;
		initLife(3);

		spr.anim.registerStateAnim(D.ent.mDash, 1, ()->cd.has("dashing"));
		spr.anim.registerStateAnim(D.ent.mDash_charge, 1, ()->isChargingAction("dash"));
		spr.anim.registerStateAnim(D.ent.mPunch_charge, 1, ()->isChargingAction("punch"));
	}

	override function setAffectS(k:Affect, t:Float, allowLower:Bool = false) {
		switch k {
			case Stun:
				t *= 1-0.2*rankRatio;

			case Dodge, Shield:
		}
		super.setAffectS(k, t, allowLower);
	}

	override function initRank() {
		super.initRank();

		switch rank {
			case 0:
				weapon = Assets.tiles.h_get(D.tiles.equipKnife);
				weapon.setPivotCoord(2, weapon.tile.height-1);
				hitDmg = 1;

			case 1:
				weapon = Assets.tiles.h_get(D.tiles.equipShovel);
				weapon.setPivotCoord(2, weapon.tile.height-7);
				hitDmg = 1;

			case 2:
				weapon = Assets.tiles.h_get(D.tiles.equipChainsaw);
				weapon.setPivotCoord(3, weapon.tile.height-3);
				hitDmg = 2;
				sprScaleX = sprScaleY = 1.5;
		}

		spr.addChild(weapon);
	}

	override function getMoveSpeed():Float {
		return super.getMoveSpeed()
			* switch rank {
				case 0: 1;
				case 1: 1.5;
				case _: 2.5;
			}
	}

	override function onTouchWall(wallX:Int, wallY:Int) {
		super.onTouchWall(wallX, wallY);
		if( cd.has("dashing") ) {
			cd.unset("dashing");
			setAffectS(Stun, 1);
			bump(-wallX*0.2, -wallY*0.2);
			dz = 0.1;
			camera.shakeS(0.2,0.1);
		}
	}

	override function onTouchEntity(e:Entity) {
		super.onTouchEntity(e);

		if( cd.has("dashing") && e.is(Hero) && e.canBeHit() ) {
			e.hit(hitDmg, this);
		}
	}

	override function aiLocked():Bool {
		return super.aiLocked() || cd.has("dashing");
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( cd.has("dashing") ) {
			final s = 0.06;
			dx += Math.cos(dashAng)*s;
			dy += Math.sin(dashAng)*s;
			weaponRot += 0.6;
		}
		else
			weaponRot = 0;

		if( !aiLocked() && hero.isAlive() ) {
			// Follow hero
			dir = dirTo(hero);
			gotoPx(hero.attachX, hero.attachY);

			// Dash attack
			if( rank>=2 && !cd.has("dashLock") && distCase(hero)<=8 ) {
				cd.setS("dashLock", 4);
				dir = dirTo(hero);
				dashAng = angTo(hero);
				chargeAction("dash", 1, ()->{
					cd.setS("dashing", 1.2);
				});
			}

			// Melee attack
			if( distPx(hero)<=Const.GRID*1.2 ) {
				var ct = switch rank {
					case 0 : 0.3;
					case 1 : 0.5;
					case _ : 0.5;
				}
				chargeAction("punch", ct, ()->{
					lockAiS(0.5 - rankRatio*0.3);
					spr.anim.playOverlap(D.ent.mPunch_hit);
					if( hero.canBeHit() )
						if( dirTo(hero)==dir && M.fabs(hero.attachX-attachX)<Const.GRID*1.2 && M.fabs(hero.attachY-attachY)<=Const.GRID )
							hero.hit(hitDmg, this);
				});
			}
		}
	}

}