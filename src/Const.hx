class Const {
	// Various constants
	public static inline var FPS = 60;
	public static inline var FIXED_FPS = 30;
	public static inline var GRID = 16;
	public static inline var INFINITE = 999999;

	/** Unique value generator **/
	public static var NEXT_UNIQ(get,never) : Int; static inline function get_NEXT_UNIQ() return _uniq++;
	static var _uniq = 0;

	/** Viewport scaling **/
	public static var SCALE(get,never) : Int;
		static inline function get_SCALE() {
			// can be replaced with another way to determine the game scaling
			return dn.heaps.Scaler.bestFit_i(256,256);
		}

	/** Specific scaling for top UI elements **/
	public static var UI_SCALE(get,never) : Float;
		static inline function get_UI_SCALE() {
			// can be replaced with another way to determine the UI scaling
			return SCALE;
		}

	/** Game layers indexes **/
	static var _inc = 0;
	public static var DP_BG = _inc++;
	public static var DP_FX_BG = _inc++;
	public static var DP_MAIN = _inc++;
	public static var DP_FRONT = _inc++;
	public static var DP_FX_FRONT = _inc++;
	public static var DP_TOP = _inc++;
	public static var DP_UI = _inc++;
}
