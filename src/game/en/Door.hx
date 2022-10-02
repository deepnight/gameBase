package en;

class Door extends Entity {
	public static var ALL : FixedArray<Door> = new FixedArray(40);
	var isOpen = false;
	public var data : Entity_Door;

	public function new(d:Entity_Door) {
		super();
		data = d;
		ALL.push(this);
		setPosCase(d.cx, d.cy);
		setPivots(d.pivotX, d.pivotY);
		xr = yr = 0;
		onPosManuallyChangedBoth();
		spr.set(D.tiles.empty);
		wid = d.width;
		hei = d.height;

		var s = new h2d.ScaleGrid(Assets.tiles.getTile(D.tiles.door), 6,6, spr);
		s.tileBorders = true;
		s.width = d.width;
		s.height = d.height;
		s.colorAdd = spr.colorAdd;
		s.colorMatrix = spr.colorMatrix;

		setCollisions(true);
	}

	public function open() {
		setCollisions(false);
		isOpen = true;
		cd.setS("shake", 1);
		dz = 0.12;
	}
	public function close() {
		setCollisions(true);
		isOpen = false;
	}

	function setCollisions(v:Bool) {
		for(y in cy...cy+M.round(hei/G))
		for(x in cx...cx+M.round(wid/G)) {
			level.setTempCollision(x,y, v);
		}
	}

	override function dispose() {
		if( !level.destroyed )
			setCollisions(false);
		super.dispose();
		ALL.remove(this);
	}

	override function postUpdate() {
		super.postUpdate();
		if( cd.has("shake") )
			spr.x+=Math.cos(ftime*8)*1*cd.getRatio("shake");

		spr.alpha += ( (isOpen?0:1) - spr.alpha ) * M.fmin(1, 0.03*tmod);
	}

	public function onPunch() {
		cd.setS("shake", R.around(0.7));
		dz = rnd(0, 0.12);
	}

	override function fixedUpdate() {
		super.fixedUpdate();
	}
}