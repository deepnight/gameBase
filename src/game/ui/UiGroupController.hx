package ui;

enum abstract GroupDir(Int) {
	var North;
	var East;
	var South;
	var West;
}

/**
	This process takes care of interactions with a group of UiComponents.
	This includes:
	- user interaction with a component,
	- focus/blur of a component,
	- supports gamepad, keyboard and mouse.

	USAGE:
	- Add some UiComponents to your scene,
	- Create a UiGroupController instance,
	- Register all these UiComponents in the UiGroupController.
**/
class UiGroupController extends dn.Process {
	var uid : Int;
	var ca : ControllerAccess<GameAction>;
	public var currentComp(default,null) : Null<UiComponent>;

	var components : Array<UiComponent> = [];

	var connectionsNeedRebuild = false;
	var uiGroupsConnections : Map<GroupDir, UiGroupController> = new Map();
	var componentsConnections : Map<Int, Map<GroupDir, UiComponent>> = new Map();

	var groupFocused = true;
	var useMouse : Bool;


	public function new(parentProcess:dn.Process, useMouse=true) {
		super(parentProcess);

		this.useMouse = useMouse;

		uid = Const.makeUniqueId();
		ca = App.ME.controller.createAccess();
		ca.lockCondition = ()->!groupFocused || customControllerLock();
		ca.lock(0.1);
	}


	public dynamic function customControllerLock() return false;


	public function registerComponent(comp:ui.UiComponent) {
		components.push(comp);
		comp.onAfterReflow = invalidateConnections; // TODO not a reliable solution

		if( useMouse ) {
			comp.enableInteractive = true;
			comp.interactive.cursor = Button;

			comp.interactive.onOver = _->{
				focusComponent(comp);
				focusGroup();
			}

			comp.interactive.onOut = _->{
				blurComponent(comp);
			}

			comp.interactive.onClick = ev->{
				if( ev.button==0 )
					comp.use();
			}

			comp.interactive.enableRightButton = true;
		}
	}


	public function focusGroup() {
		var wasFocused = groupFocused;
		groupFocused = true;
		ca.lock(0.2);
		blurAllConnectedGroups();
		if( !wasFocused )
			onGroupFocusCb();
	}

	public function blurGroup() {
		var wasFocused = groupFocused;
		groupFocused = false;
		if( currentComp!=null ) {
			currentComp.onBlur();
			currentComp = null;
		}
		if( wasFocused )
			onGroupBlurCb();
	}

	public dynamic function onGroupFocusCb() {}
	public dynamic function onGroupBlurCb() {}

	function blurAllConnectedGroups(?ignoredGroup:UiGroupController) {
		var pending = [this];
		var dones = new Map();
		dones.set(uid,true);

		while( pending.length>0 ) {
			var cur = pending.pop();
			dones.set(cur.uid, true);
			for(g in cur.uiGroupsConnections) {
				if( dones.exists(g.uid) )
					continue;
				g.blurGroup();
				pending.push(g);
			}
		}
	}

	public function connectComponents(from:UiComponent, to:UiComponent, dir:GroupDir) {
		if( !componentsConnections.exists(from.uid) )
			componentsConnections.set(from.uid, new Map());
		componentsConnections.get(from.uid).set(dir, to);
	}

	public function countComponentConnections(c:UiComponent) {
		if( !componentsConnections.exists(c.uid) )
			return 0;

		var n = 0;
		for( next in componentsConnections.get(c.uid) )
			n++;
		return n;
	}

	public inline function hasComponentConnectionDir(c:UiComponent, dir:GroupDir) {
		return componentsConnections.exists(c.uid) && componentsConnections.get(c.uid).exists(dir);
	}

	public function hasComponentConnection(from:UiComponent, to:UiComponent) {
		if( !componentsConnections.exists(from.uid) )
			return false;

		for(next in componentsConnections.get(from.uid))
			if( next==to )
				return true;
		return false;
	}

	public inline function getComponentConnectionDir(from:UiComponent, dir:GroupDir) {
		return componentsConnections.exists(from.uid)
			? componentsConnections.get(from.uid).get(dir)
			: null;
	}



	public inline function invalidateConnections() {
		connectionsNeedRebuild = true;
	}

	function buildConnections() {
		// Clear
		componentsConnections = new Map();

		// Build connections with closest aligned components
		for(from in components)
			for(dir in [North,East,South,West]) {
				var other = findComponentRaycast(from,dir);
				if( other!=null ) {
					connectComponents(from, other, dir);
					connectComponents(other, from, getOppositeDir(dir));
				}
			}

		// Fix missing connections
		for(from in components)
			for(dir in [North,East,South,West]) {
				if( hasComponentConnectionDir(from,dir) )
					continue;
				var next = findComponentFromAng(from, dirToAng(dir), M.PI*0.8, true);
				if( next!=null )
					connectComponents(from,next,dir);
			}
	}


	// Returns closest UiComponent using an angle range
	function findComponentFromAng(from:UiComponent, ang:Float, angRange:Float, ignoreConnecteds:Bool) : Null<UiComponent> {
		var best = null;
		for( other in components ) {
			if( other==from || hasComponentConnection(from,other) )
				continue;

			if( M.radDistance(ang, from.globalAngTo(other)) < angRange*0.5 ) {
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

	// Returns closest UiComponent using a collider-raycast
	function findComponentRaycast(from:UiComponent, dir:GroupDir) : Null<UiComponent> {
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
			for( other in components )
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


	function findClosest(from:UiComponent) : Null<UiComponent> {
		var best = null;
		for(other in components)
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
		for(from in components) {
			// Bounds
			g.lineStyle(2, Pink);
			g.beginFill(Pink, 0.5);
			g.drawRect(from.globalLeft, from.globalTop, from.globalWidth, from.globalHeight);
			g.endFill();
			// Connections
			for(dir in [North,East,South,West]) {
				if( !hasComponentConnectionDir(from,dir) )
					continue;

				var next = getComponentConnectionDir(from,dir);
				var ang = from.globalAngTo(next);
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

		components = null;
		currentComp = null;
	}

	public function clearAllRegisteredComponents() {
		currentComp = null;
		components = [];
		invalidateConnections();
	}

	function focusClosestComponentFromGlobalCoord(x:Float, y:Float) {
		var best = Lib.findBestInArray(components, e->{
			return -M.dist(x, y, e.globalCenterX, e.globalCenterY);
		});
		if( best!=null )
			focusComponent(best);
	}

	function blurComponent(ge:UiComponent) {
		if( currentComp==ge ) {
			currentComp.onBlur();
			currentComp = null;
		}
	}

	function focusComponent(ge:UiComponent) {
		if( currentComp==ge )
			return;

		if( currentComp!=null )
			currentComp.onBlur();
		currentComp = ge;
		currentComp.onFocus();
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
		if( currentComp==null )
			return;

		if( hasComponentConnectionDir(currentComp,dir) )
			focusComponent( getComponentConnectionDir(currentComp,dir) );
		else
			gotoConnectedGroup(dir);
	}


	function gotoConnectedGroup(dir:GroupDir) : Bool {
		if( !uiGroupsConnections.exists(dir) )
			return false;

		if( uiGroupsConnections.get(dir).components.length==0 )
			return false;

		var g = uiGroupsConnections.get(dir);
		var from = currentComp;
		// var pt = new h2d.col.Point(from.width*0.5, from.height*0.5);
		// from.f.localToGlobal(pt);
		blurGroup();
		g.focusGroup();
		g.focusClosestComponentFromGlobalCoord(from.globalCenterX, from.globalCenterY);
		return true;
	}


	public function connectGroup(dir:GroupDir, targetGroup:UiGroupController, symetric=true) {
		uiGroupsConnections.set(dir,targetGroup);
		if( symetric )
			targetGroup.connectGroup(getOppositeDir(dir), this, false);

		if( groupFocused )
			blurAllConnectedGroups();
	}


	override function preUpdate() {
		super.preUpdate();

		if( !groupFocused )
			return;

		// Build components connections
		if( connectionsNeedRebuild ) {
			connectionsNeedRebuild = false;
			buildConnections();
		}

		// Init default currentComp
		if( currentComp==null && components.length>0 )
			if( !cd.hasSetS("firstInitDone",Const.INFINITE) || ca.isDown(MenuLeft) || ca.isDown(MenuRight) || ca.isDown(MenuUp) || ca.isDown(MenuDown) )
				focusComponent(components[0]);

		if( currentComp!=null ) {
			// Use current
			if( ca.isPressed(MenuOk) )
				currentComp.use();

			// Move current
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

