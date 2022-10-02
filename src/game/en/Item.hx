package en;

class Item extends Entity {
	public static var ALL = new FixedArray(40);

	public var type : ItemType;

	public function new(x,y, t:ItemType) {
		super();
		ALL.push(this);
		type = t;
		setPosPixel(x,y);

		zr = 0.2;
		dz = 0.2;
		cd.setS("pickLock",0.2);

		game.scroller.add(spr, Const.DP_TOP);
		spr.set(switch type {
			case RageCharge: D.tiles.itemCharge;
		});
		spr.blendMode = Add;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	function onPick() {
		switch type {
			case RageCharge:
				fx.flashBangS(Assets.green(), 0.2, 1);
				hero.addRage(1);
		}
		destroy();
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( onGround )
			dz = 0.15;

		if( distCase(hero)<=1 && !cd.has("pickLock") )
			onPick();
	}
}