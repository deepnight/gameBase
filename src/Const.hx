class Const {
	public static var FPS = 60;
	public static var AUTO_SCALE_TARGET_HEIGHT = 256; // -1 to disable auto-scaling
	public static var SCALE = 2.0; // ignored if auto-scaling
	public static var GRID = 16;

	static var _uniq = 0;
	public static var NEXT_UNIQ(get,never) : Int; static inline function get_NEXT_UNIQ() return _uniq++;
	public static var INFINITE = 999999;

	static var _inc = 0;
	public static var DP_BG = _inc++;
	public static var DP_FX_BG = _inc++;
	public static var DP_MAIN = _inc++;
	public static var DP_TOP = _inc++;
	public static var DP_FX_TOP = _inc++;
	public static var DP_UI = _inc++;
}
