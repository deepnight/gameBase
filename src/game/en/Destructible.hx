package en;

class Destructible extends Entity {
	public static var ALL : FixedArray<Destructible> = new FixedArray(40);

	public function new(d:Entity_Destructible) {
		super();
		ALL.push(this);
		setPosPixel(d.pixelX, d.pixelY);
		spr.set(Assets.world);
		spr.useCustomTile( d.f_tile_getTile() );
		circularRadius = 8;
		circularWeightBase = 2;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	public function explode() {
		fx.dotsExplosionExample(centerX, centerY, White);
		new Item(attachX, attachY, RageCharge);
		destroy();
	}

	public static function checkEnt(e:Entity) {
		for(d in ALL)
			if( d.distCase(e)<=1 )
				d.explode();
	}

	override function fixedUpdate() {
		super.fixedUpdate();
	}
}