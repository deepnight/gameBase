package en;

class Bullet extends Entity {
	public static var ALL : FixedArray<Bullet> = new FixedArray(40);

	public function new(x, y, ang:Float, speed:Float) {
		super();
		ALL.push(this);

		setPosPixel(x,y);
		zr = 0.5;
		wid = hei = 4;
		zGravity = 0;
		dx = Math.cos(ang)*speed;
		dy = Math.sin(ang)*speed;
		frict = 1;

		outline.enable = false;

		spr.set(Assets.entities);
		spr.anim.playAndLoop(D.ent.bullet);
		setPivots(0.5, 0.5);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function onTouchEntity(e:Entity) {
		super.onTouchEntity(e);
		if( e.is(Hero) && e.canBeHit() ) {
			e.hit(1,this);
			destroy();
		}
	}

	override function postUpdate() {
		super.postUpdate();
		shadow.scale(0.5);
	}

	override function onTouchWall(wallX:Int, wallY:Int) {
		super.onTouchWall(wallX, wallY);
		destroy();
	}
}