package ui;

class Hud extends GameProcess {
	var flow : h2d.Flow;
	var invalidated = true;
	var notifications : Array<h2d.Flow> = [];
	var notifTw : dn.Tweenie;

	var debugText : h2d.Text;

	public function new() {
		super();

		notifTw = new Tweenie(Const.FPS);

		createRootInLayers(game.root, Const.DP_UI);
		root.filter = new h2d.filter.Nothing(); // force pixel perfect rendering

		flow = new h2d.Flow(root);
		notifications = [];

		debugText = new h2d.Text(Assets.fontPixel, root);
		debugText.filter = new dn.heaps.filter.PixelOutline();
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


	/** Pop a quick s in the corner **/
	public function notify(str:String, color:Col=0xA56DE7) {
		// Bg
		var t = Assets.tiles.getTile( D.tiles.uiBar );
		var f = new dn.heaps.FlowBg(t, 2, root);
		f.colorizeBg(color);
		f.paddingHorizontal = 6;
		f.paddingBottom = 4;
		f.paddingTop = 2;
		f.paddingLeft = 9;
		f.y = 4;

		// Text
		var tf = new h2d.Text(Assets.fontPixel, f);
		tf.text = str;
		tf.maxWidth = 0.6 * w()/Const.UI_SCALE;
		tf.textColor = 0xffffff;

		// Notification lifetime
		var durationS = 2 + str.length*0.04;
		var p = createChildProcess();
		notifications.insert(0,f);
		p.tw.createS(f.x, -f.outerWidth>-2, TEaseOut, 0.1);
		p.onUpdateCb = ()->{
			if( p.stime>=durationS && !p.cd.hasSetS("done",Const.INFINITE) )
				p.tw.createS(f.x, -f.outerWidth, 0.2).end( p.destroy );
		}
		p.onDisposeCb = ()->{
			notifications.remove(f);
			f.remove();
		}

		// Move existing notifications
		var y = 4;
		for(f in notifications) {
			notifTw.terminateWithoutCallbacks(f.y);
			notifTw.createS(f.y, y, TEaseOut, 0.2);
			y+=f.outerHeight+1;
		}

	}

	public inline function invalidate() invalidated = true;

	function render() {}

	public function onLevelStart() {}

	override function preUpdate() {
		super.preUpdate();
		notifTw.update(tmod);
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}
