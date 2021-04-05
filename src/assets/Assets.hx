package assets;

import dn.heaps.slib.*;

class Assets {
	// Fonts
	public static var fontPixel : h2d.Font;
	public static var fontTiny : h2d.Font;
	public static var fontSmall : h2d.Font;
	public static var fontMedium : h2d.Font;
	public static var fontLarge : h2d.Font;

	// Sprite atlas
	public static var tiles : SpriteLib;

	// LDtk world data
	public static var worldData : World;

	static var initDone = false;
	public static function init() {
		if( initDone )
			return;
		initDone = true;

		// Fonts
		fontPixel = hxd.Res.fonts.minecraftiaOutline.toFont();
		fontTiny = hxd.Res.fonts.barlow_condensed_medium_regular_9.toFont();
		fontSmall = hxd.Res.fonts.barlow_condensed_medium_regular_11.toFont();
		fontMedium = hxd.Res.fonts.barlow_condensed_medium_regular_17.toFont();
		fontLarge = hxd.Res.fonts.barlow_condensed_medium_regular_32.toFont();

		// Atlas
		tiles = dn.heaps.assets.Atlas.load("atlas/tiles.atlas");

		// CastleDB file hot reloading
		#if debug
		hxd.Res.data.watch(function() {
			// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
			Main.ME.delayer.cancelById("cdb");
			Main.ME.delayer.addS("cdb", function() {
				Cdb.load( hxd.Res.data.entry.getBytes().toString() );
				if( Game.exists() )
					Game.ME.onCdbReload();
			}, 0.2);
		});
		#end

		// Parse castleDB JSON
		Cdb.load( hxd.Res.data.entry.getText() );

		// LDtk init & parsing
		worldData = new World();

		// LDtk file hot-reloading
		#if debug
		hxd.Res.world.world.watch(function() {
			// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
			Main.ME.delayer.cancelById("ldtk");
			Main.ME.delayer.addS("ldtk", function() {
				worldData.parseJson( hxd.Res.world.world.entry.getText() );
				if( Game.exists() )
					Game.ME.onLdtkReload();
			}, 0.2);
		});
		#end
	}


	public static function update(tmod) {
		tiles.tmod = tmod;
	}

}