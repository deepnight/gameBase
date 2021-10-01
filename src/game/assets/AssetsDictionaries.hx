package assets;

/** Fully typed access to slice names present in Aseprite files (eg. `trace( tiles.fxStar )` )**/
class AssetsDictionaries {
	public static var tiles = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.tiles );
}