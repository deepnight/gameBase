package ui;

class Console extends h2d.Console {
	public static var ME : Console;
	#if debug
	var flags : Map<String,Bool>;
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
			// Debug flags (/set, /unset, /list commands)
			flags = new Map();
			this.addCommand("set", [{ name:"k", t:AString }], function(k:String) {
				setFlag(k,true);
				log("+ "+k.toLowerCase(), 0x80FF00);
			});
			this.addCommand("unset", [{ name:"k", t:AString, opt:true } ], function(?k:String) {
				if( k==null ) {
					log("Reset all.",0xFF0000);
					for(k in flags.keys())
						setFlag(k,false);
				}
				else {
					log("- "+k,0xFF8000);
					setFlag(k,false);
				}
			});
			this.addCommand("list", [], function() {
				for(k in flags.keys())
					log(k, 0x80ff00);
			});
			this.addAlias("+","set");
			this.addAlias("-","unset");

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

		// Misc flag aliases
		addFlagCommandAlias("bounds");
		addFlagCommandAlias("affect");
		addFlagCommandAlias("scroll");
		addFlagCommandAlias("cam");
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
	inline function addFlagCommandAlias(flag:String) {
		#if debug
		addCommand(flag, [], ()->{
			setFlag(flag, !hasFlag(flag));
		});
		#end
	}

	override function handleCommand(command:String) {
		var flagReg = ~/[\/ \t]*\+[ \t]*([\w]+)/g; // cleanup missing spaces
		super.handleCommand( flagReg.replace(command, "/+ $1") );
	}

	public function error(msg:Dynamic) {
		log("[ERROR] "+Std.string(msg), errorColor);
		h2d.Console.HIDE_LOG_TIMEOUT = Const.INFINITE;
	}

	#if debug
	public function setFlag(k:String,v) {
		k = k.toLowerCase();
		var hadBefore = hasFlag(k);

		if( v )
			flags.set(k,v);
		else
			flags.remove(k);

		if( v && !hadBefore || !v && hadBefore )
			onFlagChange(k,v);
		return v;
	}
	public function hasFlag(k:String) return flags.get( k.toLowerCase() )==true;
	#else
	public function hasFlag(k:String) return false;
	#end

	public function onFlagChange(k:String, v:Bool) {}


	public inline function clearAndLog(str:Dynamic) {
		runCommand("cls");
		log( Std.string(str) );
	}
}