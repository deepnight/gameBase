package en;

class Destructible extends Entity {
	public static var ALL : FixedArray<Destructible> = new FixedArray(40);
	var isEmpty = false;
	var player = false;
	var col1 : Col;
	var col2 : Col;

	public function new(d:Entity_Destructible) {
		super();
		ALL.push(this);
		initLife(4);
		isEmpty = d.f_empty;
		player = d.f_playerDestructible;
		setPosPixel(d.pixelX, d.pixelY+d.f_yOff);
		spr.set(Assets.world);
		spr.useCustomTile( d.f_tile_getTile() );
		circularRadius = 6;
		circularWeightBase = 5;
		col1 = d.f_breakColor1_int;
		col2 = d.f_breakColor2_int;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	public function explode(?e:Entity) {
		if( !isEmpty )
			new Item(attachX, attachY, RageCharge);
		fx.brokenProp(centerX, centerY, col1, col2, e==null ? -999 : M.PI+angTo(e));
		destroy();
		S.break01(0.4).pitchRandomly();
	}

	public static function checkEnt(e:Entity) {
		for(d in ALL)
			if( d.distCase(e)<=1 )
				d.explode(e);
	}

	override function onDie() {
		super.onDie();
		explode(lastDmgSource);
	}

	override function postUpdate() {
		super.postUpdate();
		if( cd.has("shake") ) {
			spr.x+=Math.cos(ftime*8)*1*cd.getRatio("shake");
			spr.rotation = rnd(0,0.1,true);
		}
		else
			spr.rotation = 0;
	}

	public function onPunch() {
		if( player )
			hit(1,hero);
		cd.setS("shake", R.around(0.3));
		dz = rnd(0, 0.12);
	}

	override function fixedUpdate() {
		super.fixedUpdate();
	}
}