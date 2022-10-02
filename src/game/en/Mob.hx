package en;

class Mob extends Entity {
	public static var ALL : FixedArray<Mob> = new FixedArray(40);
	var data : Entity_Mob;
	var weapon : Null<HSprite>;
	var weaponRot = 0.;

	public var rageCharges = 0;
	public var dropCharge = false;
	public var rank = 0;
	public var rankRatio(get,never) : Float;
		inline function get_rankRatio() return rank/2;

	private function new(d) {
		super();

		ALL.push(this);
		data = d;
		useLdtkEntity(data);

		initLife(3);
		rank = data.f_rank;
		circularWeightBase = 5;
		circularRadius = 7;
		lockAiS(1);

		spr.set(Assets.entities);
		outline.color = Assets.red();

		spr.anim.registerStateAnim(D.ent.mFly, 10.2, ()->!onGround);
		spr.anim.registerStateAnim(D.ent.mLay, 10.1, ()->isLayingDown());
		spr.anim.registerStateAnim(D.ent.mStun, 10.0, ()->hasAffect(Stun));

		spr.anim.registerStateAnim(D.ent.mWalk, 0.1, ()->isMoving());

		spr.anim.registerStateAnim(D.ent.mIdle, 0);
	}
	override function over() {
		super.over();

		if( weapon!=null )
			game.scroller.over(weapon);
	}

	public function addRageMarks(n:Int) {
		rageCharges+=n;
		debug(rageCharges);
	}

	public function clearRage() {
		rageCharges = 0;
		debug();
	}

	public function increaseRank() {
		rank = M.imin(rank+1, 2);
		fx.popIcon(D.tiles.iconLevelUp, attachX, attachY-hei);
		blink(Yellow);
		initRank();

		lockAiS(0.5);
		cancelAction();
		cancelMove();
	}

	function initRank() {
		if( weapon!=null ) {
			weapon.remove();
			weapon = null;
		}
	}

	override function hit(dmg:Int, from:Null<Entity>) {
		if( armor>0 )
			dmg = 0;

		super.hit(dmg, from);

		setSquashX(0.4);
		blink(dmg==0 ? White : Red);
		if( !isChargingAction() && !isLayingDown() )
			spr.anim.playOverlap(D.ent.mHit);
	}

	override function onDie() {
		super.onDie();
		if( lastDmgSource!=null ) {
			dir = lastHitDirToSource;
			bumpAwayFrom(lastDmgSource, 0.3);
			dz = R.around(0.15);
		}
		outline.enable = false;
		circularWeightBase = 0;
		for(e in ALL)
			if( e!=this && e.isAlive() )
				e.increaseRank();
	}

	override function dispose() {
		super.dispose();

		ALL.remove(this);

		if( weapon!=null )
			weapon.remove();
	}

	override function onLand() {
		super.onLand();

		cd.unset("pushOthers");
		camera.shakeS(0.3, 0.2);
		setSquashX(0.7);

		if( hasAffect(Stun) )
			incAffectS(Stun, 0.5);

		if( !cd.has("landBumpLimit") ) {
			cd.setS("landBumpLimit",1.5);
			dz = 0.12;
		}

		if( dropCharge ) {
			dropCharge = false;
			dropItem(RageCharge);
		}
	}

	function dropItem(i:ItemType) {
		new Item(attachX, attachY, i);
		fx.dotsExplosionExample(centerX, centerY, Assets.green());
	}

	override function canMoveToTarget():Bool {
		return super.canMoveToTarget() && !aiLocked();
	}

	function aiLocked() {
		return !isAlive() || hasAffect(Stun) || isChargingAction() || cd.has("aiLock");
	}

	public inline function lockAiS(t:Float) {
		cd.setS("aiLock",t,false);
	}

	override function onTouchWall(wallX:Int, wallY:Int) {
		super.onTouchWall(wallX, wallY);

		// Bounce on walls
		if( !onGround ) {
			if( cd.has("pushOthers") )
				hit(0,null);

			if( dropCharge )
				dropItem(RageCharge);

			if( wallX!=0 )
				bdx = -bdx*0.6;

			if( wallY!=0 )
				bdy = -bdy*0.6;
		}
	}

	override function onTouchEntity(e:Entity) {
		super.onTouchEntity(e);

		if( e.is(en.Mob) && e.isAlive() && cd.has("pushOthers") ) {
			if( !onGround && e.onGround && ( hasAffect(Stun) || !isAlive() ) && !e.cd.has("mobBumpLock") ) {
				setAffectS(Stun, 1);
				e.bumpAwayFrom(this, 0.3);
				e.setAffectS(Stun, 0.6);
				e.dz = rnd(0.15,0.2);
				e.cd.setS("pushOthers",0.5);
				e.cd.setS("mobBumpLock",0.2);
				if( dropCharge )
					dropItem(RageCharge);
			}
		}
	}

	override function preUpdate() {
		super.preUpdate();
		if( !cd.hasSetS("rankInitDone",Const.INFINITE) )
			initRank();
	}

	override function postUpdate() {
		super.postUpdate();

		if( !isAlive() && !onGround && !cd.hasSetS("deathBlink",0.2) )
			blink(Red);

		if( !isAlive() && onGround )
			spr.alpha = 0.6;

		if( weapon!=null ) {
			weapon.colorMatrix = colorMatrix;
			var a = Assets.getAttach(spr.groupName, spr.frame);
			weapon.visible = a!=null;
			if( a!=null ) {
				weapon.x = a.x - M.round(spr.pivot.centerFactorX*spr.tile.width) + (a.rot?1:0);
				weapon.y = a.y - M.round(spr.pivot.centerFactorY*spr.tile.height);
				weapon.rotation = a.rot ? M.PIHALF : 0;
				weapon.rotation += weaponRot;
			}
		}
	}

	override function fixedUpdate() {
		super.fixedUpdate();
	}

}