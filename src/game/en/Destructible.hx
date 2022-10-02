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
		circularWeightBase = 5;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	public function explode(?e:Entity) {
		new Item(attachX, attachY, RageCharge);
		fx.brokenProp(centerX, centerY, Col.inlineHex("#ef7d57"), e==null ? -999 : e.getMoveAng());
		destroy();
	}

	public static function checkEnt(e:Entity) {
		for(d in ALL)
			if( d.distCase(e)<=1 )
				d.explode(e);
	}

	override function postUpdate() {
		super.postUpdate();
		if( cd.has("shake") ) {
			spr.x+=Math.cos(ftime*8)*1*cd.getRatio("shake");
		}
	}

	public function onPunch() {
		cd.setS("shake", R.around(0.7));
		dz = rnd(0, 0.12);
	}

	override function fixedUpdate() {
		super.fixedUpdate();
	}
}