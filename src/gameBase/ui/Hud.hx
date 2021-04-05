package ui;

class Hud extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;
	public var level(get,never) : Level; inline function get_level() return Game.ME.level;

	var flow : h2d.Flow;
	var invalidated = true;
	var notifications : Array<h2d.Flow> = [];

	var debugText : h2d.Text;

	public function new() {
		super(Game.ME);

		createRootInLayers(game.root, Const.DP_UI);
		root.filter = new h2d.filter.Nothing(); // force pixel perfect rendering

		flow = new h2d.Flow(root);
		notifications = [];

		debugText = new h2d.Text(Assets.fontSmall, root);
		clearDebug();
	}

	override function onResize() {
		super.onResize();
		root.setScale(Const.UI_SCALE);
	}

	/** Clear debug printing **/
	public inline function clearDebug() {
		debugText.text = "";
		debugText.visible = false;
	}

	/** Display a debug string **/
	public inline function debug(v:Dynamic, clear=true) {
		if( clear )
			debugText.text = Std.string(v);
		else
			debugText.text += "\n"+v;
		debugText.visible = true;
		debugText.x = Std.int( w()/Const.UI_SCALE - 4 - debugText.textWidth );
	}


	/** Pop a quick notification in the corner **/
	public function notify(str:String, color=0xA56DE7) {
		var f = new h2d.Flow(root);
		f.paddingHorizontal = 6;
		f.paddingVertical = 4;
		f.backgroundTile = h2d.Tile.fromColor(color);
		f.y = 4;

		var tf = new h2d.Text(Assets.fontSmall, f);
		tf.text = str;
		tf.maxWidth = 0.6 * w()/Const.UI_SCALE;
		tf.textColor = 0xffffff;


		var durationS = 2 + str.length*0.04;
		var p = createChildProcess();
		for(of in notifications)
			p.tw.createS(of.y, of.y+f.outerHeight+1, 0.1); // TODO fix quick notifications bug
		notifications.push(f);
		p.tw.createS(f.x, -f.outerWidth>0, 0.1);
		p.onUpdateCb = ()->{
			if( p.stime>=durationS && !p.cd.hasSetS("done",Const.INFINITE) )
				p.tw.createS(f.x, -f.outerWidth, 0.2).end( p.destroy );
		}
		p.onDisposeCb = ()->{
			notifications.remove(f);
			f.remove();
		}
	}

	public inline function invalidate() invalidated = true;

	function render() {}

	public function onLevelStart() {}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}
