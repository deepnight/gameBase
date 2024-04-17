package ui;

class UiComponent extends h2d.Flow {
	public function new(?p:h2d.Object) {
		super(p);
	}

	@:keep override function toString() {
		return super.toString()+".UiComponent";
	}

	public final function doUse() {
		onUse();
		onUseCb();
	}
	function onUse() {}

	// Callback after `doUse()` call. DO NOT call this manually!
	public dynamic function onUseCb() {}
}