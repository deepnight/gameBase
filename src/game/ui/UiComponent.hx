package ui;

class UiComponent extends h2d.Flow {
	var _tmpPt : h2d.col.Point;

	public var uid(default,null) : Int;

	public var globalLeft(get,never) : Float;
	public var globalRight(get,never) : Float;
	public var globalTop(get,never) : Float;
	public var globalBottom(get,never) : Float;

	public var globalWidth(get,never) : Int;
	public var globalHeight(get,never) : Int;

	public var globalCenterX(get,never) : Float;
	public var globalCenterY(get,never) : Float;


	public function new(?p:h2d.Object) {
		super(p);
		uid = Const.makeUniqueId();
		_tmpPt = new h2d.col.Point();
	}

	@:keep override function toString() {
		return super.toString()+".UiComponent";
	}

	public final function use() {
		onUse();
		onUseCb();
	}
	function onUse() {}
	public dynamic function onUseCb() {}

	@:allow(ui.UiGroupController)
	function onFocus() {
		filter = new dn.heaps.filter.Invert();
	}

	@:allow(ui.UiGroupController)
	function onBlur() {
		filter = null;
	}



	function get_globalLeft() {
		_tmpPt.set();
		localToGlobal(_tmpPt);
		return _tmpPt.x;
	}

	function get_globalRight() {
		_tmpPt.set(outerWidth, outerHeight);
		localToGlobal(_tmpPt);
		return _tmpPt.x;
	}

	function get_globalTop() {
		_tmpPt.set();
		localToGlobal(_tmpPt);
		return _tmpPt.y;
	}

	function get_globalBottom() {
		_tmpPt.set(outerWidth, outerHeight);
		localToGlobal(_tmpPt);
		return _tmpPt.y;
	}

	inline function get_globalWidth() return Std.int( globalRight - globalLeft );
	inline function get_globalHeight() return Std.int( globalBottom - globalTop );
	inline function get_globalCenterX() return ( globalLeft + globalRight ) * 0.5;
	inline function get_globalCenterY() return ( globalTop + globalBottom ) * 0.5;


	public function getRelativeX(relativeTo:h2d.Object) {
		_tmpPt.set();
		localToGlobal(_tmpPt);
		relativeTo.globalToLocal(_tmpPt);
		return _tmpPt.x;
	}

	public function getRelativeY(relativeTo:h2d.Object) {
		_tmpPt.set();
		localToGlobal(_tmpPt);
		relativeTo.globalToLocal(_tmpPt);
		return _tmpPt.y;
	}

	public inline function globalAngTo(to:UiComponent) {
		return Math.atan2(to.globalCenterY-globalCenterY, to.globalCenterX-globalCenterX);
	}

	public inline function globalDistTo(to:UiComponent) {
		return M.dist(globalCenterX, globalCenterY, to.globalCenterX, to.globalCenterY);
	}

	public function overlapsRect(x:Float, y:Float, w:Int, h:Int) {
		return dn.geom.Geom.rectOverlapsRect(
			globalLeft, globalTop, globalWidth, globalHeight,
			x, y, w, h
		);
	}

	override function sync(ctx:h2d.RenderContext) {
		super.sync(ctx);
		update();
	}

	function update() {}
}