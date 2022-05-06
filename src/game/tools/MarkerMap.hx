package tools;

class MarkerMap<T:EnumValue> {
	var wid : Int;
	var hei : Int;
	var marks : Map<T, Map<Int,Int>> = new Map();


	public function new(wid:Int, hei:Int) {
		this.wid = wid;
		this.hei = hei;
	}


	public function dispose() {
		marks = null;
	}


	/** TRUE if given coords are in level bounds **/
	inline function isValid(cx,cy) return cx>=0 && cx<wid && cy>=0 && cy<hei;

	/** Gets the integer ID of a given level grid coord **/
	inline function coordId(cx,cy) return cx + cy*wid;


	/** Return TRUE if the mark (including any bits) is present at coordinates **/
	public inline function has(mark:T, cx:Int, cy:Int) {
		if( !isValid(cx,cy) || !marks.exists(mark) )
			return false;
		else
			return marks.get(mark).exists( coordId(cx,cy) );
	}


	/** Return TRUE if both mark and specified bit are present at coordinates **/
	public inline function hasWithBit(mark:T, subBit:Int, cx:Int, cy:Int) {
		if( !isValid(cx,cy) || !marks.exists(mark) )
			return false;
		else {
			if( !marks.get(mark).exists( coordId(cx,cy) ) )
				return false;
			else
				return M.hasBit( marks.get(mark).get(coordId(cx,cy)), subBit );
		}
	}


	/** Add a mark at coordinates **/
	public inline function set(mark:T, cx:Int, cy:Int) {
		if( isValid(cx,cy) && !has(mark, cx,cy) ) {
			if( !marks.exists(mark) )
				marks.set(mark, new Map());

			var markMap = marks.get(mark);
			if( !markMap.exists( coordId(cx,cy) ) )
				markMap.set( coordId(cx,cy), 0 );
		}
	}


	/** Add a mark + a specific bit at coordinates **/
	public inline function setWithBit(mark:T, subBit:Int, cx:Int, cy:Int, clearExistingBits=false) {
		if( isValid(cx,cy) && !hasWithBit(mark, subBit, cx,cy) ) {
			if( !marks.exists(mark) )
				marks.set(mark, new Map());

			var markMap = marks.get(mark);
			if( clearExistingBits || !markMap.exists( coordId(cx,cy) ) )
				markMap.set( coordId(cx,cy), M.setBit(0,subBit) );
			else
				markMap.set( coordId(cx,cy), M.setBit(markMap.get(coordId(cx,cy)), subBit) );
		}
	}


	/** Remove a mark at coordinates **/
	public inline function remove(mark:T, cx:Int, cy:Int) {
		if( isValid(cx,cy) && has(mark, cx,cy) )
			marks.get(mark).remove( coordId(cx,cy) );
	}


	/** Remove a specific bit from a mark at coordinates **/
	public inline function removeBit(mark:T, subBit:Int, cx:Int, cy:Int) {
		if( isValid(cx,cy) && hasWithBit(mark, subBit, cx,cy) )
			marks.get(mark).set(
				coordId(cx,cy),
				M.unsetBit( marks.get(mark).get(coordId(cx,cy)), subBit )
			);
	}

}