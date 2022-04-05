package tools.script;

class Script {
	public static var log : dn.Log;
	public static var parser : hscript.Parser;

	/**
		Execute provided hscript.
		USAGE:
			Script.run('var a=1 ; a++ ; log(a) ; return a');
	**/
	public static function run(script:String) {
		// Init script
		init();
		log.clear();
		log.add("exec", "Script started.");

		// API
		var interp = new hscript.Interp();
		interp.variables.set("api", new tools.script.Api());
		interp.variables.set("log", (v:Dynamic)->log.add("run", Std.string(v)));

		// Execute
		var program = parser.parseString(script);
		var out : Dynamic = try interp.execute(program)
		catch( e:hscript.Expr.Error ) {
			log.error( Std.string(e) );
			null;
		}

		// Returned value
		if( out!=null )
			log.add("exec", "Returned: "+out);

		if( log.containsAnyCriticalEntry() ) {
			// Error
			printLastLog();
			return false;
		}
		else {
			// Done!
			log.add("exec", "Script completed.");
			return true;
		}
	}


	/**
		Print last script log to default output
	**/
	public static function printLastLog() {
		log.printAll();
	}


	static var initDone = false;
	static function init() {
		if( initDone )
			return;
		initDone = true;

		parser = new hscript.Parser();

		log = new dn.Log();
		log.outputConsole = Console.ME;
		log.tagColors.set("error", "#ff6c6c");
		log.tagColors.set("exec", "#a1b2db");
		log.tagColors.set("run", "#3affe5");
	}
}