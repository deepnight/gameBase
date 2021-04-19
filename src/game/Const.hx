class Const {
	/** Default engine framerate (60) **/
	public static var FPS(get,never) : Int;
		static inline function get_FPS() return Std.int( hxd.System.getDefaultFrameRate() );

	/**
		"Fixed" updates framerate. 30fps is a good value here, as it's almost guaranteed to work on any decent setup, and it's more than enough to run any gameplay related physics.
	**/
	public static final FIXED_UPDATE_FPS = 30;

	/** Grid size in pixels **/
	public static final GRID = 16;

	/** "Infinite", sort-of. More like a "big number" **/
	public static final INFINITE : Int = 0xfffFfff;

	static var _nextUniqueId = 0;
	/** Unique value generator **/
	public static inline function makeUniqueId() {
		return _nextUniqueId++;
	}

	/** Viewport scaling **/
	public static var SCALE(get,never) : Int;
		static inline function get_SCALE() {
			// can be replaced with another way to determine the game scaling
			return dn.heaps.Scaler.bestFit_i(200,200);
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
