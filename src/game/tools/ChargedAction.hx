package tools;

/** An utility class to manage Entity charged actions, with a very low memory footprint (garbage collector friendly) **/
class ChargedAction implements dn.struct.RecyclablePool.Recyclable {
	public var id : ChargedActionId;
	public var durationS = 0.;
	public var elapsedS(default,null) = 0.;
	public var remainS(get,never) : Float; inline function get_remainS() return M.fclamp(durationS-elapsedS, 0, durationS);

	public var onComplete : ChargedAction->Void;
	public var onProgress : ChargedAction->Void;

	/** From 0 (start) to 1 (end) **/
	public var elapsedRatio(get,never) : Float;
		inline function get_elapsedRatio() return durationS<=0 ? 1 : M.fclamp(elapsedS/durationS, 0, 1);

	/** From 1 (start) to 0 (end) **/
	public var remainingRatio(get,never) : Float;
		inline function get_remainingRatio() return durationS<=0 ? 0 : M.fclamp(1-elapsedS/durationS, 0, 1);


	public inline function new() {
		recycle();
	}

	public inline function recycle() {
		id = CA_Unknown;
		durationS = 0;
		elapsedS = 0;
		onComplete = _doNothing;
		onProgress = _doNothing;
	}

	public inline function resetProgress() {
		elapsedS = 0;
		onProgress(this);
	}

	public inline function reduceProgressS(lossS:Float) {
		elapsedS = M.fmax(0, elapsedS-lossS);
		onProgress(this);
	}

	public inline function isComplete() {
		return elapsedS>=durationS;
	}

	function _doNothing(a:ChargedAction) {}


	/** Update progress and return TRUE if completed **/
	public inline function update(tmod:Float) {
		elapsedS = M.fmin( elapsedS + tmod/Const.FPS, durationS );
		onProgress(this);
		if( isComplete() ) {
			onComplete(this);
			if( isComplete() )
				recycle(); // breaks possibles mem refs, for GC
			return true;
		}
		else
			return false;
	}
}
