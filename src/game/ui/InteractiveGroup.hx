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
		ca.lockCondition = ()->!focused;
	}


	public function addNonInteractive(f:h2d.Flow) {
		content.addChild(f);
		switch content.layout {
			case Horizontal: f.fillHeight = true;
			case Vertical: f.fillWidth = true;
			case Stack:
		}
	}


	public function addInteractive(f:h2d.Flow, cb:Void->Void) : InteractiveGroupElement {
		content.addChild(f);
		switch content.layout {
			case Horizontal: f.fillHeight = true;
			case Vertical: f.fillWidth = true;
			case Stack:
		}

		var ge = new InteractiveGroupElement(this, f, cb);
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
					cb();
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
					if( from.distTo(other) < from.distTo(best) )
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
			case North, South: from.height;
			case East,West: from.width;
		}
		var x = from.left + Math.cos(ang)*step;
		var y = from.top + Math.sin(ang)*step;
		var elapsedDist = step;

		var possibleNexts = [];
		while( elapsedDist<step*3 ) {
			for( other in elements )
				if( other!=from && dn.Geom.rectOverlapsRect(x,y,from.width,from.height, other.left,other.top,other.width,other.height) )
					possibleNexts.push(other);

			if( possibleNexts.length>0 )
				return dn.Lib.findBestInArray(possibleNexts, (t)->-t.distTo(from) );

			x += Math.cos(ang)*step;
			y += Math.sin(ang)*step;
			elapsedDist+=step;
		}


		return null;
	}


	function findClosest(from:InteractiveGroupElement) : Null<InteractiveGroupElement> {
		var best = null;
		for(other in elements)
			if( other!=from && ( best==null || from.distTo(other) < from.distTo(best) ) )
				best = other;
		return best;
	}


	public function renderConnectionsDebug(g:h2d.Graphics) {
		g.clear();
		g.removeChildren();
		buildConnections();
		var font = hxd.res.DefaultFont.get();
		for(from in elements) {
			for(dir in [North,East,South,West]) {
				if( !from.hasConnection(dir) )
					continue;

				var next = from.getConnectedElement(dir);
				var ang = from.angTo(next);
				g.lineStyle(2, Yellow);
				g.moveTo(from.centerX, from.centerY);
				g.lineTo(next.centerX, next.centerY);

				// Arrow head
				var arrowDist = 16;
				var arrowAng = M.PI*0.95;
				g.moveTo(next.centerX, next.centerY);
				g.lineTo(next.centerX+Math.cos(ang+arrowAng)*arrowDist, next.centerY+Math.sin(ang+arrowAng)*arrowDist);

				g.moveTo(next.centerX, next.centerY);
				g.lineTo(next.centerX+Math.cos(ang-arrowAng)*arrowDist, next.centerY+Math.sin(ang-arrowAng)*arrowDist);

				var tf = new h2d.Text(font,g);
				tf.text = switch dir {
					case North: 'N';
					case East: 'E';
					case South: 'S';
					case West: 'W';
				}
				tf.x = Std.int( ( from.centerX*0.3 + next.centerX*0.7 ) - tf.textWidth*0.5 );
				tf.y = Std.int( ( from.centerY*0.3 + next.centerY*0.7 ) - tf.textHeight*0.5 );
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
		var pt = new h2d.col.Point(0,0);
		var best = Lib.findBestInArray(elements, e->{
			pt.set(e.width*0.5, e.height*0.5);
			e.f.localToGlobal(pt);
			return -M.dist(x, y, pt.x, pt.y);
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
		var pt = new h2d.col.Point(from.width*0.5, from.height*0.5);
		from.f.localToGlobal(pt);
		blurGroup();
		g.focusGroup();
		g.focusClosestElementFromGlobal(pt.x, pt.y);
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
				current.cb();

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
	var uid : Int;
	var group : InteractiveGroup;

	public var f: h2d.Flow;
	public var cb: Void->Void;

	var connections : Map<GroupDir, InteractiveGroupElement> = new Map();

	public var width(get,never) : Int;
	public var height(get,never) : Int;

	public var left(get,never) : Float;
	public var right(get,never) : Float;
	public var top(get,never) : Float;
	public var bottom(get,never) : Float;

	public var centerX(get,never) : Float;
	public var centerY(get,never) : Float;


	public function new(g,f,cb) {
		uid = InteractiveGroup.UID++;
		group = g;
		this.f = f;
		this.cb = cb;
		f.onAfterReflow = group.invalidateConnections;
	}

	@:keep public function toString() {
		return 'InteractiveGroupElement#$uid';
	}

	inline function get_width() return f.outerWidth;
	inline function get_height() return f.outerHeight;

	inline function get_left() return f.x;
	inline function get_right() return left+width;
	inline function get_top() return f.y;
	inline function get_bottom() return top+height;

	inline function get_centerX() return left + width*0.5;
	inline function get_centerY() return top + height*0.5;


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
		return Math.atan2(t.centerY-centerY, t.centerX-centerX);
	}

	public inline function distTo(t:InteractiveGroupElement) {
		return M.dist(centerX, centerY, t.centerX, t.centerY);
	}

	public dynamic function onFocus() {
		group.defaultOnFocus(this);
	}

	public dynamic function onBlur() {
		group.defaultOnBlur(this);
	}
}
