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
		this.addCommand("fps", [], ()->{
			if( stats!=null ) {
				stats.destroy();
				stats = null;
			}
			else
				stats = new dn.heaps.StatsBox(App.ME);
		});
		this.addAlias("stats","fps");

		// Misc flag aliases
		addFlagCommandAlias("bounds");
		addFlagCommandAlias("affect");
		addFlagCommandAlias("scroll");
		addFlagCommandAlias("cam");
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
		log("[ERROR] "+Std.string(msg), 0xff0000);
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