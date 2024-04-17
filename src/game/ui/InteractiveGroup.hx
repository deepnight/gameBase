package ui;

enum abstract GroupDir(Int) {
	var North;
	var East;
	var South;
	var West;
}


@:allow(ui.InteractiveGroupElement)
class InteractiveGroup extends dn.Process {
	static var UID = 0;

	public var content : h2d.Flow;
	var uid : Int;
	var ca : ControllerAccess<GameAction>;
	var current : Null<InteractiveGroupElement>;

	var elements : Array<InteractiveGroupElement> = [];
	var connectionsInvalidated = false;
	var connectedGroups : Map<GroupDir, InteractiveGroup> = new Map();

	var focused = true;
	var useMouse : Bool;


	public function new(parent:h2d.Object, process:dn.Process, useMouse=true) {
		super(process);

		this.useMouse = useMouse;

		content = new h2d.Flow(parent);
		content.layout = Vertical;
		content.onAfterReflow = invalidateConnections;

		uid = UID++;
		ca = App.ME.controller.createAccess();
		ca.lockCondition = ()->!focused || customControllerLock();
		ca.lock(0.1);
	}


	public dynamic function customControllerLock() return false;


	public function addNonInteractive(f:h2d.Flow) {
		content.addChild(f);
		switch content.layout {
			case Horizontal: f.fillHeight = true;
			case Vertical: f.fillWidth = true;
			case Stack:
		}
	}


	public function addInteractive<T:h2d.Flow>(f:T, cb:T->Void) : InteractiveGroupElement {
		content.addChild(f);

		var ge = new InteractiveGroupElement(this, f, cast cb);
		elements.push(ge);

		if( useMouse ) {
			f.enableInteractive = true;
			f.interactive.cursor = Button;

			f.interactive.onOver = _->{
				focusElement(ge);
				focusGroup();
			}

			f.interactive.onOut = _->{
				blurElement(ge);
			}

			f.interactive.onClick = ev->{
				if( ev.button==0 )
					cb(f);
			}

			f.interactive.enableRightButton = true;
		}

		return ge;
	}


	public function focusGroup() {
		var wasFocus = focused;
		focused = true;
		ca.lock(0.2);
		blurAllConnectedGroups();
		if( !wasFocus )
			onGroupFocus();
	}

	public function blurGroup() {
		var wasFocus = focused;
		focused = false;
		if( current!=null ) {
			current.onBlur();
			current = null;
		}
		if( wasFocus )
			onGroupBlur();
	}

	public dynamic function onGroupFocus() {}
	public dynamic function onGroupBlur() {}

	function blurAllConnectedGroups(?ignoredGroup:InteractiveGroup) {
		var pending = [this];
		var dones = new Map();
		dones.set(uid,true);

		while( pending.length>0 ) {
			var cur = pending.pop();
			dones.set(cur.uid, true);
			for(g in cur.connectedGroups) {
				if( dones.exists(g.uid) )
					continue;
				g.blurGroup();
				pending.push(g);
			}
		}
	}

	public inline function invalidateConnections() {
		connectionsInvalidated = true;
	}

	function buildConnections() {
		content.reflow();
		for(t in elements)
			t.clearConnections();

		// Build connections with closest aligned elements
		for(from in elements)
			for(dir in [North,East,South,West]) {
				var other = findElementRaycast(from,dir);
				if( other!=null )
					from.connectNext(dir,other);
			}

		// Fix missing connections
		for(from in elements)
			for(dir in [North,East,South,West]) {
				if( from.hasConnection(dir) )
					continue;
				var next = findElementFromAng(from, dirToAng(dir), M.PI*0.8, true);
				if( next!=null )
					from.connectNext(dir, next, false);
			}
	}


	// Returns closest Element using an angle range
	function findElementFromAng(from:InteractiveGroupElement, ang:Float, angRange:Float, ignoreConnecteds:Bool) : Null<InteractiveGroupElement> {
		var best = null;
		for( other in elements ) {
			if( other==from || from.isConnectedTo(other) )
				continue;

			if( M.radDistance(ang, from.angTo(other)) < angRange*0.5 ) {
				if( best==null )
					best = other;
				else {
					if( from.globalDistTo(other) < from.globalDistTo(best) )
						best = other;
				}
			}
		}
		return best;


	}

	// Returns closest Element using a collider-raycast
	function findElementRaycast(from:InteractiveGroupElement, dir:GroupDir) : Null<InteractiveGroupElement> {
		var ang = dirToAng(dir);
		var step = switch dir {
			case North, South: from.globalHeight;
			case East,West: from.globalWidth;
		}
		var x = from.globalLeft + Math.cos(ang)*step;
		var y = from.globalTop + Math.sin(ang)*step;
		var elapsedDist = step;

		var possibleNexts = [];
		while( elapsedDist<step*3 ) {
			for( other in elements )
				if( other!=from && other.overlapsRect(x, y, from.globalWidth, from.globalHeight ) )
					possibleNexts.push(other);

			if( possibleNexts.length>0 )
				return dn.Lib.findBestInArray(possibleNexts, (t)->-t.globalDistTo(from) );

			x += Math.cos(ang)*step;
			y += Math.sin(ang)*step;
			elapsedDist+=step;
		}


		return null;
	}


	function findClosest(from:InteractiveGroupElement) : Null<InteractiveGroupElement> {
		var best = null;
		for(other in elements)
			if( other!=from && ( best==null || from.globalDistTo(other) < from.globalDistTo(best) ) )
				best = other;
		return best;
	}


	public function createDebugger() {
		var g = new h2d.Graphics(App.ME.root);
		var debugProc = createChildProcess();
		debugProc.onUpdateCb = ()->{
			if( !debugProc.cd.hasSetS("tick",0.1) )
				renderDebugToGraphics(g);
		}
		debugProc.onDisposeCb = ()->{
			g.remove();
		}
	}

	/**
		Draw a debug render of the group structure into an existing Graphics object.
		NOTE: the render uses global coordinates, so the Graphics object should be attached to the scene root.
	**/
	public function renderDebugToGraphics(g:h2d.Graphics) {
		g.clear();
		g.removeChildren();
		buildConnections();
		var font = hxd.res.DefaultFont.get();
		for(from in elements) {
			// Bounds
			g.lineStyle(2, Pink);
			g.beginFill(Pink, 0.5);
			g.drawRect(from.globalLeft, from.globalTop, from.globalWidth, from.globalHeight);
			g.endFill();
			// Connections
			for(dir in [North,East,South,West]) {
				if( !from.hasConnection(dir) )
					continue;

				var next = from.getConnectedElement(dir);
				var ang = from.angTo(next);
				g.lineStyle(2, Yellow);
				g.moveTo(from.globalCenterX, from.globalCenterY);
				g.lineTo(next.globalCenterX, next.globalCenterY);

				// Arrow head
				var arrowDist = 16;
				var arrowAng = M.PI*0.95;
				g.moveTo(next.globalCenterX, next.globalCenterY);
				g.lineTo(next.globalCenterX+Math.cos(ang+arrowAng)*arrowDist, next.globalCenterY+Math.sin(ang+arrowAng)*arrowDist);

				g.moveTo(next.globalCenterX, next.globalCenterY);
				g.lineTo(next.globalCenterX+Math.cos(ang-arrowAng)*arrowDist, next.globalCenterY+Math.sin(ang-arrowAng)*arrowDist);

				var tf = new h2d.Text(font,g);
				tf.text = switch dir {
					case North: 'N';
					case East: 'E';
					case South: 'S';
					case West: 'W';
				}
				tf.x = Std.int( ( from.globalCenterX*0.3 + next.globalCenterX*0.7 ) - tf.textWidth*0.5 );
				tf.y = Std.int( ( from.globalCenterY*0.3 + next.globalCenterY*0.7 ) - tf.textHeight*0.5 );
				tf.filter = new dn.heaps.filter.PixelOutline();
			}
		}
	}


	override function onDispose() {
		super.onDispose();

		ca.dispose();
		ca = null;

		elements = null;
		current = null;
	}

	function focusClosestElementFromGlobal(x:Float, y:Float) {
		var best = Lib.findBestInArray(elements, e->{
			return -M.dist(x, y, e.globalCenterX, e.globalCenterY);
		});
		if( best!=null )
			focusElement(best);
	}

	function blurElement(ge:InteractiveGroupElement) {
		if( current==ge ) {
			current.onBlur();
			current = null;
		}
	}

	function focusElement(ge:InteractiveGroupElement) {
		if( current==ge )
			return;

		if( current!=null )
			current.onBlur();
		current = ge;
		current.onFocus();
	}

	public dynamic function defaultOnFocus(ge:InteractiveGroupElement) {
		ge.f.filter = new dn.heaps.filter.Invert();
	}

	public dynamic function defaultOnBlur(ge:InteractiveGroupElement) {
		ge.f.filter = null;
	}

	inline function getOppositeDir(dir:GroupDir) {
		return switch dir {
			case North: South;
			case East: West;
			case South: North;
			case West: East;
		}
	}

	inline function dirToAng(dir:GroupDir) : Float {
		return switch dir {
			case North: -M.PIHALF;
			case East: 0;
			case South: M.PIHALF;
			case West: M.PI;
		}
	}

	function angToDir(ang:Float) : GroupDir {
		return  M.radDistance(ang,0)<=M.PIHALF*0.5 ? East
			: M.radDistance(ang,M.PIHALF)<=M.PIHALF*0.5 ? South
			: M.radDistance(ang,M.PI)<=M.PIHALF*0.5 ? West
			: North;
	}


	function gotoNextDir(dir:GroupDir) {
		if( current==null )
			return;

		if( current.hasConnection(dir) )
			focusElement( current.getConnectedElement(dir) );
		else
			gotoConnectedGroup(dir);
	}


	function gotoConnectedGroup(dir:GroupDir) : Bool {
		if( !connectedGroups.exists(dir) )
			return false;

		if( connectedGroups.get(dir).elements.length==0 )
			return false;

		var g = connectedGroups.get(dir);
		var from = current;
		// var pt = new h2d.col.Point(from.width*0.5, from.height*0.5);
		// from.f.localToGlobal(pt);
		blurGroup();
		g.focusGroup();
		g.focusClosestElementFromGlobal(from.globalCenterX, from.globalCenterY);
		return true;
	}


	public function connectGroup(dir:GroupDir, targetGroup:InteractiveGroup, symetric=true) {
		connectedGroups.set(dir,targetGroup);
		if( symetric )
			targetGroup.connectGroup(getOppositeDir(dir), this, false);

		if( focused )
			blurAllConnectedGroups();
	}


	override function preUpdate() {
		super.preUpdate();

		if( !focused )
			return;

		// Build elements connections
		if( connectionsInvalidated ) {
			buildConnections();
			connectionsInvalidated = false;
		}

		// Init current
		if( current==null && elements.length>0 )
			if( !cd.hasSetS("firstInitDone",Const.INFINITE) || ca.isDown(MenuLeft) || ca.isDown(MenuRight) || ca.isDown(MenuUp) || ca.isDown(MenuDown) )
				focusElement(elements[0]);

		// Move current
		if( current!=null ) {
			if( ca.isPressed(MenuOk) )
				current.cb(current.f);

			if( ca.isPressedAutoFire(MenuLeft) )
				gotoNextDir(West);
			else if( ca.isPressedAutoFire(MenuRight) )
				gotoNextDir(East);

			if( ca.isPressedAutoFire(MenuUp) )
				gotoNextDir(North);
			else if( ca.isPressedAutoFire(MenuDown) )
				gotoNextDir(South);
		}
	}
}



private class InteractiveGroupElement {
	var _pt : h2d.col.Point;

	var uid : Int;
	var group : InteractiveGroup;

	public var f: h2d.Flow;
	public var cb: h2d.Flow->Void;

	var connections : Map<GroupDir, InteractiveGroupElement> = new Map();

	public var globalLeft(get,never) : Float;
	public var globalRight(get,never) : Float;
	public var globalTop(get,never) : Float;
	public var globalBottom(get,never) : Float;

	public var globalWidth(get,never) : Int;
	public var globalHeight(get,never) : Int;

	public var globalCenterX(get,never) : Float;
	public var globalCenterY(get,never) : Float;


	public function new(g,f,cb) {
		uid = InteractiveGroup.UID++;
		_pt = new h2d.col.Point();
		this.cb = cb;
		group = g;
		this.f = f;
		f.onAfterReflow = group.invalidateConnections;
	}

	@:keep public function toString() {
		return 'InteractiveGroupElement#$uid';
	}

	function get_globalLeft() {
		_pt.set();
		f.localToGlobal(_pt);
		return _pt.x;
	}

	function get_globalRight() {
		_pt.set(f.outerWidth,f.outerHeight);
		f.localToGlobal(_pt);
		return _pt.x;
	}

	function get_globalTop() {
		_pt.set();
		f.localToGlobal(_pt);
		return _pt.y;
	}

	function get_globalBottom() {
		_pt.set(f.outerWidth,f.outerHeight);
		f.localToGlobal(_pt);
		return _pt.y;
	}

	inline function get_globalWidth() return Std.int( globalRight - globalLeft );
	inline function get_globalHeight() return Std.int( globalBottom - globalTop );
	inline function get_globalCenterX() return ( globalLeft + globalRight ) * 0.5;
	inline function get_globalCenterY() return ( globalTop + globalBottom ) * 0.5;


	public function connectNext(dir:GroupDir, to:InteractiveGroupElement, symetric=true) {
		connections.set(dir, to);
		if( symetric )
			to.connections.set(group.getOppositeDir(dir), this);
	}

	public function clearConnections() {
		connections = new Map();
	}

	public function countConnections() {
		var n = 0;
		for(next in connections)
			n++;
		return n;
	}

	public inline function hasConnection(dir:GroupDir) {
		return connections.exists(dir);
	}

	public function isConnectedTo(ge:InteractiveGroupElement) {
		for(next in connections)
			if( next==ge )
				return true;
		return false;
	}

	public inline function getConnectedElement(dir:GroupDir) {
		return connections.get(dir);
	}

	public inline function angTo(t:InteractiveGroupElement) {
		return Math.atan2(t.globalCenterY-globalCenterY, t.globalCenterX-globalCenterX);
	}

	public inline function globalDistTo(t:InteractiveGroupElement) {
		return M.dist(globalCenterX, globalCenterY, t.globalCenterX, t.globalCenterY);
	}

	public dynamic function onFocus() {
		group.defaultOnFocus(this);
	}

	public dynamic function onBlur() {
		group.defaultOnBlur(this);
	}

	public function overlapsElement(other:InteractiveGroupElement) {
		return dn.Geom.rectOverlapsRect(
			globalLeft, globalTop, globalWidth, globalHeight,
			other.globalLeft, other.globalTop, other.globalWidth, other.globalHeight
		);
	}

	public function overlapsRect(x:Float, y:Float, w:Int, h:Int) {
		return dn.Geom.rectOverlapsRect(
			globalLeft, globalTop, globalWidth, globalHeight,
			x, y, w, h
		);
	}

}
