package assets;

#if( macro || display )
import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.Tools;
#end

/**
	This macro will create a `db` field to the Const class, and fill it with all values found in JSON and CastleDB sources.
**/
class ConstDbBuilder {
	#if( macro || display )

	/**
		Build the class fields.
		If a provided file path is `null`, this source will just be ignored.
	**/
	macro public static function build(cdbFile:Null<String>, jsonFile:Null<String>) : Array<Field> {
		var pos = Context.currentPos();
		var baseFields = Context.getBuildFields(); // base Const fields
		var dbTypeDef : Array<Field> = []; // type definition of "db" field
		var dbDefaults : Array<ObjectField> = []; // "db" field initialization

		// Create fields from files
		if( cdbFile!=null )
			buildFromCdb(cdbFile, baseFields, dbTypeDef, dbDefaults);

		if( jsonFile!=null )
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


	/** Remove invalid characters from a given string **/
	static inline function cleanupIdentifier(str:String) {
		if( str==null )
			return "";
		else
			return ~/[^a-z0-9_]/gi.replace(str, "_");
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
				dbTypeDef.push({ name:k, pos:pos, kind:kind, doc: "[JSON] "+k });
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

		// Parse JSON
		var json : { sheets:Array<{name:String, lines:Array<Dynamic>}> } = try haxe.Json.parse(raw) catch(_) null;
		if( json==null ) {
			Context.fatalError("CastleDB JSON parsing failed!", pos);
			return;
		}

		// List constants
		var fillExprs : Array<Expr> = [];
		for(sheet in json.sheets)
			if( sheet.name=="ConstDb" ) {
				for(l in sheet.lines) {
					var id = Reflect.field(l, "constId");

					// List used values
					var values = [];
					for(i in 1...3+1)
						if( Reflect.hasField(l, "value"+i) )
							values.push(i);

					// Create value fields
					for(i in values) {
						var desc = Reflect.field(l,"valueName"+i);
						var subId = values.length==1 ? id : id+"_"+( desc==null ? Std.string(i) : cleanupIdentifier(desc) );
						dbTypeDef.push({
							name: subId,
							pos: pos,
							doc: "[CDB] " + ( desc==null ? id : desc ),
							kind: FVar(macro:Float),
						});
						dbDefaults.push({ field:subId, expr:macro 0. });
						fillExprs.push( macro db.$subId = _resolveCdbValue( cast $v{id}, $v{i} ) );
					}
				}
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
