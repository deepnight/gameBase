package assets;

import dn.heaps.slib.*;

typedef AttachInfo = { rot:Bool, x:Int, y:Int }

class Assets {
	public static var SLIB = dn.heaps.assets.SfxDirectory.load("sfx",true);
	// Fonts
	public static var fontPixel : h2d.Font;
	public static var fontPixelMono : h2d.Font;

	public static var tiles : SpriteLib;
	public static var entities : SpriteLib;
	public static var world : SpriteLib;
	static var palette : Array<Col> = [];

	public static var worldData : World;

	static var entitiesAttachPts: Map< String, Map<Int,AttachInfo> >;


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
		palette = [];
		for(i in 0...pal.width) {
			var c : Col = pal.getPixel(i, 0);
			c = c.withoutAlpha();
			palette.push(c);
		}

		// Atlas
		tiles = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.tiles.toAseprite());
		entities = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.entities.toAseprite());
		world = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.world.toAseprite());

		// tiles.defineAnim("fxStun", "0,1,2");

		// Parse attach points entities
		entitiesAttachPts = new Map();
		var pixels = entities.tile.getTexture().capturePixels();
		var attachCol = Col.fromInt(0xff00ff).withAlpha(1);
		var attachRotCol = Col.fromInt(0xff0000).withAlpha(1);
		var p = 0x0;
		for(g in entities.getGroups()) {
			var i = 0;
			for(f in g.frames) {
				for(y in 0...f.hei)
				for(x in 0...f.wid) {
					p = pixels.getPixel(f.x+x, f.y+y);
					if( p==attachCol || p==attachRotCol ) {
						if( !entitiesAttachPts.exists(g.id) )
							entitiesAttachPts.set(g.id, new Map());
						entitiesAttachPts.get(g.id).set(i, { rot:p==attachRotCol, x:x, y:y });
					}
				}
				i++;
			}
		}

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
	public static inline function walls() return getCol(17);


	public static inline function getAttach(group:String, frame:Int) : Null<AttachInfo> {
		return entitiesAttachPts.exists(group) && entitiesAttachPts.get(group).exists(frame)
			? entitiesAttachPts.get(group).get(frame)
			: null;
	}


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