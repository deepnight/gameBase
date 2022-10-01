package en;

class Mob extends Entity {
	public static var ALL : FixedArray<Mob> = new FixedArray(40);
	var data : Entity_Mob;

	public function new(d) {
		data = d;
		super(data.cx, data.cy);
		ALL.push(this);

		spr.set(Assets.entities, D.ent.kIdle);
		var f = new dn.heaps.filter.PixelOutline( Assets.dark() );
		f.bottom = false;
		spr.filter = f;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function fixedUpdate() {
		super.fixedUpdate();
	}

}