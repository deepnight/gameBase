package assets;

#if( macro || display )
import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.Tools;
#end

class ConstDbBuilder {

	public static macro function build(cdbFileName:String, jsonFileName:String, cdbClass:ExprOf<Class<Dynamic>>) {
		var pos = Context.currentPos();
		var rawMod = Context.getLocalModule();
		var modPack = rawMod.split(".");
		var modName = modPack.pop();

		// Create class type
		var classTypeDef : TypeDefinition = {
			pos : pos,
			name : cleanupIdentifier('Db_${cdbFileName}_${jsonFileName}'),
			pack : modPack,
			meta: [{ name:":keep", pos:pos }],
			doc: "Project specific Level class",
			kind : TDClass(),
			fields : (macro class {
				public function new() {}

				/** This callback will trigger when one of the files is reloaded. **/
				public dynamic function onReload() {}
			}).fields,
		}

		// Castle DB
		var extraFields = readCdb(cdbFileName, cdbClass);
		classTypeDef.fields = extraFields.concat(classTypeDef.fields);

		// Generic JSON
		var jsonFields = readJson(jsonFileName);
		classTypeDef.fields = jsonFields.concat(classTypeDef.fields);

		Context.defineModule(rawMod, [classTypeDef]);
		Context.registerModuleDependency(rawMod, resolveFilePath(cdbFileName));
		Context.registerModuleDependency(rawMod, resolveFilePath(jsonFileName));

		// Return constructor
		var classTypePath : TypePath = { pack:classTypeDef.pack, name:classTypeDef.name }
		return macro new $classTypePath();
	}


	#if( macro || display )

	/**
		Parse a JSON and create class fields using its root values
	**/
	static function readJson(fileName:String) : Array<Field> {
		var pos = Context.currentPos();

		// Read file
		var path = resolveFilePath(fileName);
		if( path==null ) {
			Context.fatalError("File not found: "+fileName, pos);
			return [];
		}

		var fileName = dn.FilePath.extractFileWithExt(path);
		Context.registerModuleDependency(Context.getLocalModule(), path);


		// Parse JSON
		var raw = sys.io.File.getContent(path);
		var jsonPos = Context.makePosition({ file:path, min:1, max:1 });
		var json = try haxe.Json.parse(raw) catch(_) null;
		if( json==null ) {
			Context.fatalError("Couldn't parse JSON: "+path, jsonPos);
			return [];
		}

		// List all supported fields in JSON
		var fields : Array<Field> = [];
		var initializers : Array<Expr> = [];
		for(k in Reflect.fields(json)) {
			var val = Reflect.field(json, k);
			var kind : FieldType = null;

			// Build field type
			switch Type.typeof(val) {
				case TNull:
					kind = FVar(null);

				case TInt:
					kind = FVar(macro:Int, macro $v{val});

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
				fields.push({
					name: k,
					pos: pos,
					kind: kind,
					doc: '$k\n\n*From $fileName* ',
					access: [APublic],
				});
				initializers.push( macro trace("hello "+$v{k}) );
			}
		}

		// Update class fields using given JSON string (used for hot-reloading support)
		fields.push({
			name: "reloadJson",
			doc: "Update class values using given JSON (useful if you want to support hot-reloading of the JSON db file)",
			pos: pos,
			access: [APublic],
			kind: FFun({
				args: [{ name:"updatedJsonStr", type:macro:String }],
				expr: macro {
					var json = try haxe.Json.parse(updatedJsonStr) catch(_) null;
					if( json==null )
						return;

					for(k in Reflect.fields(json))
						if( Reflect.hasField(this, k) ) {
							try Reflect.setField( this, k, Reflect.field(json,k) )
							catch(_) trace("ERROR: couldn't update JSON const "+k);
						}

					onReload();
				},
			}),
		});

		return fields;
	}



	/**
		Parse CastleDB and create class fields using its "ConstDb" sheet
	**/
	static function readCdb(fileName:String, cdbClass:Expr) : Array<Field> {
		var cdbClassIdentifier : String = switch cdbClass.expr {
			case EConst( CIdent(s) ): s;
			case EField( e, field):
				switch e.expr {
					case EConst( CIdent(s)): s +"."+ field;
					case _: null;
				}
			case _: null;
		}
		if( cdbClassIdentifier==null )
			Context.fatalError('Unable to resolve class identifier', cdbClass.pos);

		var pos = Context.currentPos();

		// Read file
		var path = resolveFilePath(fileName);
		if( path==null ) {
			Context.fatalError("File not found: "+fileName, pos);
			return [];
		}

		var fileName = dn.FilePath.extractFileWithExt(path);
		Context.registerModuleDependency(Context.getLocalModule(), path);

		var raw = sys.io.File.getContent(path);
		if( raw.indexOf('"ConstDb"')<0 ) {
			Context.fatalError('$fileName file should contain a ConstDb sheet.', pos);
			return [];
		}

		var fields : Array<Field> = [];


		// Float value resolver
		fields.push({
			name: "_resolveCdbValue",
			access: [APublic, AInline],
			pos: pos,
			kind: FFun({
				args: [
					{ name:"constId", type:Context.getType(cdbClassIdentifier+".ConstDbKind").toComplexType() },
					{ name:"valueId", type:Context.getType("String").toComplexType() },
				],
				ret: macro:Float,
				expr: macro {
					var out = 0.;
					var all : Array<Dynamic> = Reflect.field( (cast $cdbClass).ConstDb.get(constId), "values" );
					if( all!=null )
						for(v in all)
							if( v.valueName==valueId ) {
								out = v.value;
								break;
							}
					return out;
				},
			}),
			meta: [
				{ name:":keep", pos:pos },
				{ name:":noCompletion", pos:pos },
			],
		});

		// Parse JSON
		var json : { sheets:Array<{name:String, lines:Array<{values:Array<Dynamic>}>}> } = try haxe.Json.parse(raw) catch(_) null;
		if( json==null ) {
			Context.fatalError("CastleDB JSON parsing failed!", pos);
			return [];
		}

		// List constants
		var fillExprs : Array<Expr> = [];
		for(sheet in json.sheets)
			if( sheet.name=="ConstDb" ) {
				for(l in sheet.lines) {
					var id = Reflect.field(l, "constId");
					var doc = Reflect.field(l,"doc");

					// List sub values
					var valuesFields : Array<Field> = [];
					for( v in l.values ) {
						var vid = cleanupIdentifier(v.valueName);
						valuesFields.push({
							name: vid,
							pos: pos,
							doc: (v.doc==null ? v.valueName : v.doc ) + '\n\n*From $fileName* ',
							kind: FVar( v.isInteger ? macro:Int : macro:Float ),
						});
						var resolveExpr = v.isInteger
							? macro Std.int( _resolveCdbValue( cast $v{id}, $v{vid} ) )
							: macro _resolveCdbValue( cast $v{id}, $v{vid} );
						fillExprs.push( macro {
							if( this.$id==null )
								this.$id = cast {};
							this.$id.$vid = $e{resolveExpr};
						 } );
					}

					fields.push({
						name: id,
						pos: pos,
						access: [APublic],
						doc: ( doc==null ? id : doc ) + '\n\n*From $fileName* ',
						kind: FVar( TAnonymous(valuesFields) ),
					});
				}
			}

		// Public method
		fields.push({
			pos:pos,
			name: "reloadCdb",
			doc: "Update class values using the content of the CastleDB file (useful if you want to support hot-reloading of the CastleDB file)",
			access: [ APublic ],
			kind: FFun({
				args: [{ name:"triggerCallback", type:macro:Bool, value:macro true}],
				expr: macro {
					$a{fillExprs}
					if( triggerCallback )
						onReload();
				},
			}),
		});

		return fields;
	}



	/** Lookup a file in all known project paths **/
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


	/** Remove invalid characters from a given string **/
	static inline function cleanupIdentifier(str:String) {
		if( str==null )
			return "";
		else
			return ~/[^a-z0-9_]/gi.replace(str, "_");
	}



	#end

}