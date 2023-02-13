package ui;

enum abstract ConsoleFlag(Int) to Int from Int {
	var F_Camera;
	var F_CameraScrolling;
	var F_Bounds;
	var F_Affects;
}

class Console extends h2d.Console {
	public static var ME : Console;
	#if debug
	var flags : Map<ConsoleFlag,Bool>;
	var allFlags : Array<{ name:String, value:Int }> = [];
	#end

	var stats : Null<dn.heaps.StatsBox>;

	public function new(f:h2d.Font, p:h2d.Object) {
		super(f, p);

		logTxt.filter = new dn.heaps.filter.PixelOutline();
		scale(2); // TODO smarter scaling for 4k screens
		logTxt.condenseWhite = false;
		errorColor = 0xff6666;

		// Settings
		ME = this;
		h2d.Console.HIDE_LOG_TIMEOUT = #if debug 60 #else 5 #end;
		Lib.redirectTracesToH2dConsole(this);

		#if debug
			// Debug console flags
			flags = new Map();
			allFlags = dn.MacroTools.getAbstractEnumValues(ConsoleFlag);
			allFlags.sort( (a,b)->Reflect.compare(a.name, b.name) );
			this.addCommand("flags", "Open the console flags window", [], function() {
				this.hide();
				var w = new ui.win.Menu();
				for(f in allFlags)
					w.addButton("["+(hasFlag(f.value)?"X":" ")+"] "+f.name.substr(2), ()->{
						setFlag( f.value, !hasFlag(f.value) );
					});
			});
			this.addAlias("f","flags");
			this.addAlias("flag","flags");

			// List all console flags
			this.addCommand("list", [], function() {
				for(f in allFlags)
					log( (hasFlag(f.value) ? "+" : "-")+f.name, hasFlag(f.value)?0x80ff00:0xff8888 );
			});

			// Controller debugger
			this.addCommand("ctrl", [], ()->{
				App.ME.ca.toggleDebugger(App.ME, dbg->{
					dbg.root.filter = new dn.heaps.filter.PixelOutline();
				});
			});

			// Garbage collector
			this.addCommand("gc", [{ name:"state", t:AInt, opt:true }], (?state:Int)->{
				if( !dn.Gc.isSupported() )
					log("GC is not supported on this platform", Red);
				else {
					if( state!=null )
						dn.Gc.setState(state!=0);
					dn.Gc.runNow();
					log("GC forced (current state: "+(dn.Gc.isActive() ? "active" : "inactive" )+")", dn.Gc.isActive()?Green:Yellow);
				}
			});

			// Level marks
			var allLevelMarks : Array<{ name:String, value:Int }>;
			allLevelMarks = dn.MacroTools.getAbstractEnumValues(Types.LevelMark);
			this.addCommand(
				"mark",
				[
					{ name:"levelMark", t:AEnum( allLevelMarks.map(m->m.name) ), opt:true },
					{ name:"bit", t:AInt, opt:true },
				],
				(k:String, bit:Null<Int>)->{
					if( !Game.exists() ) {
						error('Game is not running');
						return;
					}
					if( k==null ) {
						// Game.ME.level.clearDebug();
						return;
					}

					var bit : Null<LevelSubMark> = cast bit;
					var mark = -1;
					for(m in allLevelMarks)
						if( m.name==k ) {
							mark = m.value;
							break;
						}
					if( mark<0 ) {
						error('Unknown level mark $k');
						return;
					}

					var col = 0xffcc00;
					log('Displaying $mark (bit=$bit)...', col);
					// Game.ME.level.renderDebugMark(cast mark, bit);
				}
			);
			this.addAlias("m","mark");
		#end

		// List all active dn.Process
		this.addCommand("process", [], ()->{
			for( l in App.ME.rprintChildren().split("\n") )
				log(l);
		});
		this.addAlias("p", "process");

		// Show build info
		this.addCommand("build", [], ()->log( Const.BUILD_INFO ) );

		// Create a debug drone
		#if debug
		this.addCommand("drone", [], ()->{
			new en.DebugDrone();
		});
		#end

		// Create a stats box
		this.addCommand("fps", [], ()->toggleStats());
		this.addAlias("stats","fps");

		// All flag aliases
		#if debug
		for(f in allFlags)
			addCommand(f.name.substr(2), [], ()->{
				setFlag(f.value, !hasFlag(f.value));
			});
		#end
	}

	public function disableStats() {
		if( stats!=null ) {
			stats.destroy();
			stats = null;
		}
	}

	public function enableStats() {
		disableStats();
		stats = new dn.heaps.StatsBox(App.ME);
		stats.addFpsChart();
		stats.addDrawCallsChart();
		#if hl
		stats.addMemoryChart();
		#end
	}

	public function toggleStats() {
		if( stats!=null )
			disableStats();
		else
			enableStats();
	}

	override function getCommandSuggestion(cmd:String):String {
		var sugg = super.getCommandSuggestion(cmd);
		if( sugg.length>0 )
			return sugg;

		if( cmd.length==0 )
			return "";

		// Simplistic argument auto-complete
		for(c in commands.keys()) {
			var reg = new EReg("([ \t\\/]*"+c+"[ \t]+)(.*)", "gi");
			if( reg.match(cmd) ) {
				var lowArg = reg.matched(2).toLowerCase();
				for(a in commands.get(c).args)
					switch a.t {
						case AInt:
						case AArray(_):
						case AFloat:
						case AString:
						case ABool:
						case AEnum(values):
							for(v in values)
								if( v.toLowerCase().indexOf(lowArg)==0 )
									return reg.matched(1) + v;
					}
			}
		}

		return "";
	}

	/** Creates a shortcut command "/flag" to toggle specified flag state **/
	// inline function addFlagCommandAlias(flag:ConsoleFlag) {
	// 	#if debug
	// 	var str = Std.string(flag);
	// 	for(f in allFlags)
	// 		if( f.value==flag ) {
	// 			str = f.name;
	// 			break;
	// 		}
	// 	addCommand(str, [], ()->{
	// 		setFlag(flag, !hasFlag(flag));
	// 	});
	// 	#end
	// }

	override function handleCommand(command:String) {
		var flagReg = ~/[\/ \t]*\+[ \t]*([\w]+)/g; // cleanup missing spaces
		super.handleCommand( flagReg.replace(command, "/+ $1") );
	}

	public function error(msg:Dynamic) {
		log("[ERROR] "+Std.string(msg), errorColor);
		h2d.Console.HIDE_LOG_TIMEOUT = Const.INFINITE;
	}

	#if debug
	public function setFlag(f:ConsoleFlag, v:Bool) {
		var hadBefore = hasFlag(f);

		if( v )
			flags.set(f,v);
		else
			flags.remove(f);

		if( v && !hadBefore || !v && hadBefore )
			onFlagChange(f,v);
		return v;
	}
	public function hasFlag(f:ConsoleFlag) return flags.get(f)==true;
	#else
	public inline function hasFlag(f:ConsoleFlag) return false;
	#end

	public function onFlagChange(f:ConsoleFlag, v:Bool) {}


	override function log(text:String, ?color:Int) {
		if( !App.ME.screenshotMode )
			super.log(text, color);
	}

	public inline function clearAndLog(str:Dynamic) {
		runCommand("cls");
		log( Std.string(str) );
	}
}