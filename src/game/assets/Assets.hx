package assets;

import dn.heaps.slib.*;

/**
	This class centralizes all assets management (ie. art, sounds, fonts etc.)
**/
class Assets {
	// Fonts
	public static var fontPixel : h2d.Font;
	public static var fontPixelMono : h2d.Font;

	public static var tiles : SpriteLib;
	public static var entities : SpriteLib;
	public static var world : SpriteLib;
	static var palette : Array<Col> = [];

	public static var worldData : World;



	static var _initDone = false;
	public static function init() {
		if( _initDone )
			return;
		_initDone = true;

		// Fonts
		fontPixel = new hxd.res.BitmapFont( hxd.Res.fonts.pixel_unicode_regular_12_xml.entry ).toFont();
		fontPixelMono = new hxd.res.BitmapFont( hxd.Res.fonts.pixica_mono_regular_16_xml.entry ).toFont();

		// Palette
		var pal = hxd.Res.atlas.sweetie_16_1x.getPixels(ARGB);
		var sizePx = 1;
		palette = [];
		for(i in 0...16) {
			var c : Col = pal.getPixel(i*sizePx, 0);
			c = c.withoutAlpha();
			palette.push(c);
			trace(c);
		}

		// Atlas
		tiles = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.tiles.toAseprite());
		entities = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.entities.toAseprite());
		world = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.world.toAseprite());

		// Hot-reloading of CastleDB
		#if debug
		hxd.Res.data.watch(function() {
			// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
			App.ME.delayer.cancelById("cdb");
			App.ME.delayer.addS("cdb", function() {
				CastleDb.load( hxd.Res.data.entry.getBytes().toString() );
				Const.db.reload_data_cdb( hxd.Res.data.entry.getText() );
			}, 0.2);
		});
		#end

		// Parse castleDB JSON
		CastleDb.load( hxd.Res.data.entry.getText() );

		// Hot-reloading of `const.json`
		hxd.Res.const.watch(function() {
			// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
			App.ME.delayer.cancelById("constJson");
			App.ME.delayer.addS("constJson", function() {
				Const.db.reload_const_json( hxd.Res.const.entry.getBytes().toString() );
			}, 0.2);
		});

		// LDtk init & parsing
		worldData = new World();

		// LDtk file hot-reloading
		#if debug
		var res = try hxd.Res.load(worldData.projectFilePath.substr(4)) catch(_) null; // assume the LDtk file is in "res/" subfolder
		if( res!=null )
			res.watch( ()->{
				// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
				App.ME.delayer.cancelById("ldtk");
				App.ME.delayer.addS("ldtk", function() {
					worldData.parseJson( res.entry.getText() );
					if( Game.exists() )
						Game.ME.onLdtkReload();
				}, 0.2);
			});
		#end
	}

	public static inline function getCol(idx:Int) : Col {
		return palette[ M.iclamp(idx,0,palette.length-1) ];
	}
	public static inline function black() return getCol(0);
	public static inline function dark() return getCol(15);
	public static inline function white() return getCol(12);
	public static inline function yellow() return getCol(4);
	public static inline function green() return getCol(5);
	public static inline function blue() return getCol(10);
	public static inline function red() return getCol(2);


	/**
		Pass `tmod` value from the game to atlases, to allow them to play animations at the same speed as the Game.
		For example, if the game has some slow-mo running, all atlas anims should also play in slow-mo
	**/
	public static function update(tmod:Float) {
		if( Game.exists() && Game.ME.isPaused() )
			tmod = 0;

		tiles.tmod = tmod;
		entities.tmod = tmod;
		world.tmod = tmod;
	}

}