package ui;

class Bar extends h2d.Object {
	var cd : dn.Cooldown;
	var bg : h2d.ScaleGrid;
	var bar : h2d.ScaleGrid;
	var oldBar : Null<h2d.ScaleGrid>;

	public var innerBarMaxWidth(get,never) : Float;
	public var innerBarHeight(get,never) : Float;
	public var outerWidth(get,never) : Float;
	public var outerHeight(get,never) : Float;
	public var color(default,set) : Col;
	public var defaultColor(default,null) : Col;
	var padding : Int;
	var oldBarSpeed : Float = 1.;

	var blinkColor : h3d.Vector;
	var gradTg : Null<h2d.TileGroup>;

	var curValue : Float;
	var curMax : Float;

	public function new(wid:Int, hei:Int, c:Col, ?p:h2d.Object) {
		super(p);

		curValue = 0;
		curMax = 1;
		cd = new dn.Cooldown(Const.FPS);

		bg = new h2d.ScaleGrid( Assets.tiles.getTile(D.tiles.uiBarBg), 2, 2, this );
		bg.colorAdd = blinkColor = new h3d.Vector();

		bar = new h2d.ScaleGrid( Assets.tiles.getTile(D.tiles.uiBar), 1,1, this );

		setSize(wid,hei,1);
		defaultColor = color = c;
	}

	public function enableOldValue(oldBarColor:Col, speed=1.0) {
		if( oldBar!=null )
			oldBar.remove();
		oldBar = new h2d.ScaleGrid( h2d.Tile.fromColor(oldBarColor,3,3), 1, 1 );
		this.addChildAt( oldBar, this.getChildIndex(bar) );
		oldBar.height = bar.height;
		oldBar.width = 0;
		oldBar.setPosition(padding,padding);

		oldBarSpeed = speed;
	}

	public function setGraduationPx(step:Int, alpha=0.5) {
		if( step<=1 )
			throw "Invalid bar graduation "+step;

		if( gradTg!=null )
			gradTg.remove();

		gradTg = new h2d.TileGroup(Assets.tiles.tile, this);
		gradTg.colorAdd = blinkColor;
		gradTg.setDefaultColor(0x0, alpha);

		var x = step-1;
		var t = Assets.tiles.getTile(D.tiles.pixel);
		while( x<innerBarMaxWidth ) {
			gradTg.addTransform(bar.x+x, bar.y, 1, innerBarHeight, 0, t);
			x+=step;
		}
	}

	public function addGraduation(xRatio:Float, c:Col, alpha=1.0) {
		if( gradTg==null ) {
			gradTg = new h2d.TileGroup(Assets.tiles.tile, this);
			gradTg.colorAdd = blinkColor;
		}
		gradTg.setDefaultColor(c, alpha);
		gradTg.addTransform( bar.x+Std.int(innerBarMaxWidth*xRatio), bar.y, 1, innerBarHeight, 0, Assets.tiles.getTile(D.tiles.pixel) );
	}

	inline function set_color(c:Col) {
		bar.color.setColor( c.withAlpha(1) );
		bg.color.setColor( c.toBlack(0.8).withAlpha(1) );
		return color = c;
	}

	inline function get_innerBarMaxWidth() return outerWidth-padding*2;
	inline function get_innerBarHeight() return outerHeight-padding*2;

	inline function get_outerWidth() return bg.width;
	inline function get_outerHeight() return bg.height;

	public function setSize(wid:Int, hei:Int, pad:Int) {
		padding = pad;

		bar.setPosition(padding, padding);
		if( oldBar!=null )
			oldBar.setPosition(padding,padding);

		bg.width = wid+padding*2;
		bar.width = wid;

		bg.height = hei+padding*2;
		bar.height = hei;

		renderBar();
	}

	public function set(v:Float,max:Float) {
		var oldWidth = bar.width;
		curValue = v;
		curMax = max;
		renderBar();
		if( oldBar!=null && oldWidth>bar.width) {
			cd.setS("oldMaintain",0.06);
			oldBar.width = oldWidth;
		}
	}

	function renderBar() {
		bar.visible = curValue>0;
		bar.width = innerBarMaxWidth * (curValue/curMax);
	}

	public function skipOldValueBar() {
		if( oldBar!=null )
			oldBar.width = 0;
	}

	public function blink(?c:Col, a=1.0) {
		blinkColor.setColor( (c==null ? color : c).withAlpha(a) );
		cd.setS("blinkMaintain", 0.15 * 1/oldBarSpeed);
	}

	override function sync(ctx:h2d.RenderContext) {
		var tmod = Game.ME.tmod;
		cd.update(tmod);

		// Decrease oldValue bar
		if( oldBar!=null ) {
			if( !cd.has("oldMaintain") )
				oldBar.width = M.fmax(0, oldBar.width - oldBarSpeed*2*tmod);
			oldBar.visible = oldBar.width>0;
		}

		// Blink fade
		if( !cd.has("blinkMaintain") ) {
			blinkColor.r*=Math.pow(0.60, tmod);
			blinkColor.g*=Math.pow(0.55, tmod);
			blinkColor.b*=Math.pow(0.50, tmod);
		}

		super.sync(ctx);
	}
}