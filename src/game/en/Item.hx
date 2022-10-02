package en;

class Item extends Entity {
	public var type : ItemType;

	public function new(x,y, t:ItemType) {
		super();
		type = t;
		setPosPixel(x,y);

		zr = 0.2;
		dz = 0.2;
		cd.setS("pickLock",0.2);

		spr.set(switch type {
			case RageCharge: D.tiles.itemCharge;
		});
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

		if( distCase(hero)<=1 && !cd.has("pickLock") )
			onPick();
	}
}