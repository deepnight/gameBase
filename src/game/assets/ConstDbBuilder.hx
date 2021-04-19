package assets;

#if( macro || display )
import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.Tools;
#end

/**
	This macro will create a `db` field to the Const class, and fill it with all values found in both:
	- "res/const.json" simple JSON file,
	- "res/data.cdb" CastleDB file, in sheet named "ConstDb".

	This allows easy access to your game constants. Example:
		With `res/const.json` containing:
			{ "myValue":5, "someText":"hello" }

		You may use:
			Const.db.myValue; // equals to 5
			Const.db.someText; // equals to "hello"

		If the JSON changes on runtime, the `myValue` field is kept up-to-date, allowing real-time testing. This hot-reloading only works if the project was built using the `-debug` flag. In release builds, values are constant.
**/
class ConstDbBuilder {
	#if( macro || display )

	macro public static function build(cdbFile:String, jsonFile:String) : Array<Field> {
		var pos = Context.currentPos();
		var baseFields = Context.getBuildFields(); // base Const fields
		var dbTypeDef : Array<Field> = []; // type definition of "db" field
		var dbDefaults : Array<ObjectField> = []; // "db" field initialization

		// Create fields from files
		buildFromCdb(cdbFile, baseFields, dbTypeDef, dbDefaults);
		buildFromJson(jsonFile, baseFields, dbTypeDef, dbDefaults);

		// Add "db" field
		baseFields.push({
			name: "db",
			meta: [{ name:":keep", pos:Context.currentPos() }],
			access: [ APublic, AStatic ],
			pos: Context.currentPos(),
			kind: FVar( TAnonymous(dbTypeDef), { pos:pos, expr:EObjectDecl(dbDefaults) } ),
		});
		return baseFields;
	}


	/**
		Lookup a file in all known paths
	**/
	static function resolveFilePath(basePath:String) : Null<String> {
		// Look in class paths
		var path = try Context.resolvePath(basePath) catch( e : Dynamic ) null;

		// Look in resourcesPath define
		if( path == null ) {
			var r = Context.definedValue("resourcesPath");
			if( r != null ) {
				r = r.split("\\").join("/");
				if( !StringTools.endsWith(r, "/") ) r += "/";
				try path = Context.resolvePath(r + basePath) catch( e : Dynamic ) null;
			}
		}

		// Look in default Heaps resource dir
		if( path == null )
			try path = Context.resolvePath("res/" + basePath) catch( e : Dynamic ) null;

		return path;
	}




	/**
		Proxy over JSON file
	**/
	static function buildFromJson(basePath:String, baseFields:Array<Field>, dbTypeDef:Array<Field>, dbDefaults:Array<ObjectField>) {
		var pos = Context.currentPos();

		// Read file
		var path = resolveFilePath(basePath);
		if( path==null ) {
			Context.fatalError("File not found: "+basePath, pos);
			return;
		}
		Context.registerModuleDependency(Context.getLocalModule(), path);
		var raw = sys.io.File.getContent(path);

		// Parse JSON
		var jsonPos = Context.makePosition({ file:path, min:1, max:1 });
		var json = try haxe.Json.parse(raw) catch(_) null;
		if( json==null ) {
			Context.fatalError("Couldn't parse JSON: "+path, jsonPos);
			return;
		}

		// List all supported fields in JSON
		for(k in Reflect.fields(json)) {
			var val = Reflect.field(json, k);
			var kind : FieldType = null;

			// Build field type
			switch Type.typeof(val) {
				case TNull:
					kind = FVar(null);

				case TInt:
					kind = FVar(macro:Int);

				case TFloat:
					kind = FVar(macro:Float);

				case TBool:
					kind = FVar(macro:Bool);

				case TClass(String):
					kind = FVar(macro:String);

				case _:
					Context.warning('Unsupported value type "${Type.typeof(val)}" for $k', jsonPos);
			}

			// Add field and default value
			if( kind!=null ) {
				dbTypeDef.push({ name:k, pos:pos, kind:kind });
				dbDefaults.push({ field:k, expr:macro $v{val} });
			}
		}


		// Add hot-reload parser method
		baseFields.push({
			name: "fillJsonValues",
			access: [ AStatic, APublic ],
			meta: [{ name:":keep", pos:pos }, { name:":noCompletion", pos:pos }],
			pos: pos,
			kind: FFun({
				args: [{ name:"rawJson", type:macro:String }],
				expr: macro {
					var json = try haxe.Json.parse(rawJson) catch(_) null;
					if( json==null )
						return;

					for(k in Reflect.fields(json)) {
						if( Reflect.hasField(Const.db, k) )
							try Reflect.setField(Const.db, k, Reflect.field(json,k))
							catch(_) trace("ERROR: couldn't update JSON const "+k);
					}
				},
			}),
		});

	}



	/**
		Proxy over "ConstDb" sheet in CastleDB file.
	**/
	static function buildFromCdb(basePath:String, baseFields:Array<Field>, dbTypeDef:Array<Field>, dbDefaults:Array<ObjectField>) {
		var pos = Context.currentPos();

		// Read file
		var path = resolveFilePath(basePath);
		if( path==null ) {
			Context.fatalError("File not found: "+basePath, pos);
			return;
		}
		var raw = sys.io.File.getContent(path);
		if( raw.indexOf('"ConstDb"')<0 ) {
			Context.fatalError("CastleDB file should contain a ConstDb sheet.", pos);
			return;
		}


		// Float value resolver
		baseFields.push({
			name: "_resolveCdbValue",
			access: [AStatic, APublic, AInline],
			pos: pos,
			kind: FFun({
				args: [
					{ name:"constId", type:Context.getType("CastleDb.ConstDbKind").toComplexType() },
					{ name:"valueIdx", type: macro:Int, opt:true, value:macro 1 },
				],
				ret: macro:Float,
				expr: macro {
					return valueIdx<1 || valueIdx>3 ? 0 : Reflect.field( CastleDb.ConstDb.get(constId), "value"+valueIdx );
				},
			}),
			meta: [
				{ name:":keep", pos:pos },
				{ name:":noCompletion", pos:pos },
			],
		});

		// String desc resolver
		baseFields.push({
			name: "_resolveCdbDesc",
			access: [AStatic, APublic, AInline],
			pos: pos,
			kind: FFun({
				args: [
					// { name:"constId", type: macro:String },
					{ name:"constId", type:Context.getType("CastleDb.ConstDbKind").toComplexType() },
					{ name:"valueIdx", type: macro:Int, opt:true, value:macro 1 },
				],
				ret: macro:Null<String>,
				expr: macro {
					return valueIdx<1 || valueIdx>3 ? null : Reflect.field( CastleDb.ConstDb.get(constId), "desc"+valueIdx );
				},
			}),
			meta: [{ name:":noCompletion", pos:pos }, { name:":keep", pos:pos }],
		});

		// Iterate all const IDs
		var settingIdReg = ~/"constId"\s*:\s*"(.*?)"/gim;
		var fillExprs : Array<Expr> = [];
		while( settingIdReg.match(raw) ) {
			var id = settingIdReg.matched(1);

			for(i in 1...4) {
				var subId = id+"_"+i;

				// Float value getter
				dbTypeDef.push({
					name: subId,
					pos: pos,
					kind: FVar(macro:Float),
				});
				dbDefaults.push({ field:subId, expr: macro 0. });
				fillExprs.push( macro {
					db.$subId = _resolveCdbValue( cast $v{id}, $v{i} );
					trace($v{id});
				});
			}

			// String desc getter
			dbTypeDef.push({
				name: id+"_desc",
				pos: pos,
				kind: FVar(macro:Int->Null<String>),
			});
			dbDefaults.push({
				field:id+"_desc",
				expr: macro function(valueIndex:Int) { return _resolveCdbDesc( cast $v{id}, valueIndex); }
			});

			// Continue on next ID
			raw = settingIdReg.matchedRight();
		}

		// Create
		baseFields.push({
			pos:pos,
			name: "fillCdbValues",
			meta: [ {name:":noCompletion",pos:pos} ],
			access: [ AStatic, APublic ],
			kind: FFun({
				args: [],
				expr: macro $a{fillExprs},
			}),
		});
	}

	#end
}
