package en;

class Mob extends Entity {
	public static var ALL : FixedArray<Mob> = new FixedArray(40);
	var data : Entity_Mob;

	public function new(d) {
		data = d;
		super();
		useLdtkEntity(data);
		ALL.push(this);
		initLife(data.f_hp);
		circularWeight = 3;
		circularRadius = 7;

		spr.set(Assets.entities);
		outline.color = Assets.red();

		spr.anim.registerStateAnim(D.ent.mFly, 2, ()->!onGround);

		spr.anim.registerStateAnim(D.ent.mLay, 1.1, ()->hasAffect(LayDown));
		spr.anim.registerStateAnim(D.ent.mStun, 1.0, ()->hasAffect(Stun));

		spr.anim.registerStateAnim(D.ent.mIdle, 0);
	}

	override function hit(dmg:Int, from:Null<Entity>) {
		super.hit(dmg, from);
		setSquashX(0.4);
		setAffectS(Stun, dmg==0 ? 0.5 : 1.2);
		blink(dmg==0 ? White : Red);
		spr.anim.playOverlap(D.ent.mHit);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function onLand() {
		super.onLand();

		camera.shakeS(0.3, 0.2);
		setSquashX(0.7);

		if( hasAffect(Stun) ) {
			setAffectS(LayDown, 0.5);
			setAffectS(Stun, getAffectDurationS(Stun)+getAffectDurationS(LayDown));
		}

		if( !cd.has("landBumpLimit") ) {
			mulVelocities(0.6);
			cd.setS("landBumpLimit",1.5);
			dz = 0.2;
		}
	}

	override function canMoveToTarget():Bool {
		return super.canMoveToTarget() && !aiLocked();
	}

	inline function aiLocked() {
		return !isAlive() || hasAffect(Stun) || hasAffect(LayDown);
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( !aiLocked() ) {
			dir = dirTo(hero);
			goto(hero.attachX, hero.attachY);
		}
	}

}