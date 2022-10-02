package en;

class Message extends Entity {
	public static var ALL : FixedArray<Message> = new FixedArray(10);
	var wrapper : h2d.Object;

	public function new(d:Entity_Message) {
		super();
		ALL.push(this);
		setPosCase(d.cx, d.cy);
		spr.set(D.tiles.empty);
		circularRadius = 0;

		wrapper = new h2d.Object();
		game.scroller.add(wrapper, Const.DP_BG);
		var bg = new h2d.ScaleGrid(Assets.tiles.getTile(D.tiles.uiMessage), 4,4, wrapper);
		bg.tileBorders = true;

		var tf = new h2d.Text(Assets.fontPixel, wrapper);
		tf.x = 5;
		tf.y = 0;
		tf.textColor = d.f_color_int;
		tf.text = d.f_text;
		tf.dropShadow = { dx:0, dy:1, color:0x0, alpha:0.6 }
		tf.colorMatrix = spr.colorMatrix;

		bg.width = tf.x*2 + tf.textWidth;
		bg.height = 4 + tf.textHeight;
		bg.visible = d.f_showBackground;
		bg.colorMatrix = spr.colorMatrix;

		wrapper.x = Std.int( (cx+d.f_pivotX)*G - bg.width*d.f_pivotX );
		wrapper.y = Std.int( (cy+d.f_pivotY)*G - bg.height*d.f_pivotY );
	}

	override function dispose() {
		super.dispose();
		wrapper.remove();
		ALL.remove(this);
	}
}