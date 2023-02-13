package tools;

class AppChildProcess extends dn.Process {
	public static var ALL : FixedArray<AppChildProcess> = new FixedArray(256);

	public var app(get,never) : App; inline function get_app() return App.ME;

	public function new() {
		super(App.ME);
		ALL.push(this);
	}

	override function onDispose() {
		super.onDispose();
		ALL.remove(this);
	}
}