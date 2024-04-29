package ui;

class UiComponent extends h2d.Flow {
	public function new(?p:h2d.Object) {
		super(p);
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

	public dynamic function onFocus() {
		filter = new dn.heaps.filter.Invert();
	}
	public dynamic function onBlur() {
		filter = null;
	}
}