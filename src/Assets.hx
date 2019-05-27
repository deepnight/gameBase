import mt.heaps.slib.*;

class Assets {
	public static var font : h2d.Font;
	public static var gameElements : SpriteLib;

	static var initDone = false;
	public static function init() {
		if( initDone )
			return;
		initDone = true;

		font = hxd.Res.fonts.minecraftiaOutline.toFont();
		gameElements = mt.heaps.slib.assets.Atlas.load("atlas/gameElements.atlas");
	}
}