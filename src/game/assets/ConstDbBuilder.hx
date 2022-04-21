package assets;

#if( macro || display )
import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.Tools;
#end

// Rough CastleDB JSON typedef
typedef CastleDbJson = {
	sheets : Array<{
		name : String,
		columns : Array<{
			typeStr: String,
			name: String,
		}>,
		lines:Array<{
			constId: String,
			values: Array<{
				value : Dynamic,
				valueName : String,
				subValues: Dynamic,
				isInteger : Bool,
				doc : String,
			}>,
		}>,
	}>,
}

class ConstDbBuilder {

	/**
		Generate a class based on fields extracted from provided source files (JSON or CastleDB). Then return an instance of this class to be stored in some static var. Typically:
		```haxe
		public static var db = ConstDbBuilder.buildVar(["data.cdb", "const.json"]);
		```
	**/
	public static macro function buildVar(dbFileNames:Array<String>) {
		var pos = Context.currentPos();
		var rawMod = Context.getLocalModule();
		var modPack = rawMod.split(".");
		var modName = modPack.pop();

		// Create class type
		var classTypeDef : TypeDefinition = {
			pos : pos,
			name : cleanupIdentifier('Db_${dbFileNames.join("_")}'),
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

		// Parse given files and create class fields
		for(f in dbFileNames) {
			var fileFields = switch dn.FilePath.extractExtension(f) {
				case "cdb": readCdb(f);
				case "json": readJson(f);
				case _: Context.fatalError("Unsupported database file "+f, pos);
			}
			classTypeDef.fields = fileFields.concat(classTypeDef.fields);
		}

		// Register stuff
		Context.defineModule(rawMod, [classTypeDef]);
		for(f in dbFileNames)
			Context.registerModuleDependency(rawMod, resolveFilePath(f));

		// Return class constructor
		var classTypePath : TypePath = { pack:classTypeDef.pack, name:classTypeDef.name }
		return macro new $classTypePath();
	}


	#if( macro || display )

	/**
		Parse a JSON and create class fields using its root values
	**/
	static function readJson(fileName:String) : Array<Field> {
		var uid = cleanupIdentifier(fileName);
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
					Context.warning('Unsupported JSON type "${Type.typeof(val)}" for $k', jsonPos);
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
			name: "reload_"+uid,
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
	static function readCdb(fileName:String) : Array<Field> {
		var uid = cleanupIdentifier(fileName);
		var pos = Context.currentPos();

		// Read file
		var path = resolveFilePath(fileName);
		if( path==null ) {
			Context.fatalError("File not found: "+fileName, pos);
			return [];
		}
		Context.registerModuleDependency(Context.getLocalModule(), path);

		// Parse JSON
		var raw = sys.io.File.getContent(path);
		var json : CastleDbJson = try haxe.Json.parse(raw) catch(_) null;
		if( json==null ) {
			Context.fatalError("CastleDB JSON parsing failed!", pos);
			return [];
		}

		// List sub-values types
		var subValueTypes : Map<String,{ ct:ComplexType, typeStr:String }> = new Map();
		for(sheet in json.sheets) {
			if( sheet.name.indexOf("ConstDb")<0 || sheet.name.indexOf("@subValues")<0 )
				continue;
			inline function _unsupported(typeName:String, valueName:String) {
				Context.fatalError("Unsupported CastleDB type "+typeName+" for sub-value "+valueName, pos);
				return null;
			}
			for(col in sheet.columns) {
				var ct : ComplexType = switch col.typeStr {
					case "1": macro:String;
					case "2": macro:Bool;
					case "3": macro:Int;
					case "4": macro:Float;
					case "11": macro:Int;
					case _: _unsupported(col.typeStr, col.name);
				}
				if( ct!=null )
					subValueTypes.set(col.name, { ct:ct, typeStr:col.typeStr });
			}
		}

		// List constants
		var fields : Array<Field> = [];
		var valid = false;
		for(sheet in json.sheets)
			if( sheet.name=="ConstDb" ) {
				if( sheet.columns.filter(c->c.name=="constId").length==0 )
					continue;

				if( sheet.columns.filter(c->c.name=="values").length==0 )
					continue;

				valid = true;
				for(l in sheet.lines) {
					var id = Reflect.field(l, "constId");
					var doc = Reflect.field(l,"doc");

					// List sub values
					var valuesFields : Array<Field> = [];
					var valuesIniters : Array<ObjectField> = [];
					for( v in l.values ) {
						var doc = (v.doc==null ? v.valueName : v.doc ) + '\n\n*From $fileName* ';
						var vid = cleanupIdentifier(v.valueName);

						if( v.subValues!=null && Reflect.fields(v.subValues).length>0 ) {
							// Value is an object with sub fields
							var fields : Array<Field> = [];
							var initers : Array<ObjectField> = [];

							// Read sub values
							for(k in Reflect.fields(v.subValues)) {
								if( k=="_value" )
									Context.fatalError('[$fileName] "${l.constId}.${v.valueName}" value name "_value" is not allowed.', pos);

								var ct = subValueTypes.exists(k) ? subValueTypes.get(k).ct : (macro:Float);
								fields.push({
									name: k,
									kind: FVar(ct),
									pos: pos,
									doc: doc,
								});

								var rawVal = Reflect.field(v.subValues, k);
								var const : Constant = !subValueTypes.exists(k)
									? CFloat( Std.string(rawVal) )
									: switch subValueTypes.get(k).typeStr {
										case "1": CString(rawVal);
										case "2": CIdent( Std.string(rawVal) );
										case "3": CInt( Std.string(rawVal) );
										case "4": CFloat( Std.string(rawVal) );
										case "11": CInt( Std.string(rawVal) );
										case _:
											Context.fatalError("Unexpected CastleDB typeStr "+subValueTypes.get(k).typeStr+" for sub-value init expr", pos);
									}
								initers.push({
									field: k,
									expr: { expr:EConst(const), pos:pos },
								});
							}

							// Also include column value if it's not zero
							if( v.value!=0 ) {
								fields.push({
									name: "_value",
									pos: pos,
									doc: doc,
									kind: FVar( v.isInteger ? macro:Int : macro:Float ),
								});
								if( v.isInteger && v.value != Std.int(v.value) )
									Context.warning('[$fileName] "${l.constId}.${v.valueName}" is a Float instead of an Int', pos);
								var cleanVal = Std.string( v.isInteger ? Std.int(v.value) : v.value );
								initers.push({
									field: "_value",
									expr: {
										pos: pos,
										expr: EConst( v.isInteger ? CInt(cleanVal) : CFloat(cleanVal) ),
									},
								});
							}

							// Value definition
							valuesFields.push({
								name: vid,
								pos: pos,
								doc: (v.doc==null ? v.valueName : v.doc ) + '\n\n*From $fileName* ',
								kind: FVar( TAnonymous(fields) ),
							});
							// Value init
							valuesIniters.push({
								field: vid,
								expr: {
									pos: pos,
									expr: EObjectDecl(initers),
								},
							});
						}
						else {
							// Simple value (int/float)
							valuesFields.push({
								name: vid,
								pos: pos,
								doc: doc,
								kind: FVar( v.isInteger ? macro:Int : macro:Float ),
							});

							// Initial value setter
							if( v.isInteger && v.value!=Std.int(v.value) )
								Context.warning('[$fileName] "${l.constId}.${v.valueName}" is a Float instead of an Int', pos);
							var cleanVal = Std.string( v.isInteger ? Std.int(v.value) : v.value );
							valuesIniters.push({
								field: vid,
								expr: {
									pos: pos,
									expr: EConst( v.isInteger ? CInt(cleanVal) : CFloat(cleanVal) ),
								},
							});
						}
					}

					fields.push({
						name: id,
						pos: pos,
						access: [APublic],
						doc: ( doc==null ? id : doc ) + '\n\n*From $fileName* ',
						kind: FVar( TAnonymous(valuesFields), {
							pos:pos,
							expr: EObjectDecl(valuesIniters),
						} ),
					});
				}
			}

		// Check CDB sheets
		if( !valid ) {
			Context.fatalError('$fileName CastleDB file should contain a valid "ConstDb" sheet.', pos);
			return [];
		}

		// CDB hot reloader
		var cdbJsonType = Context.getType("ConstDbBuilder.CastleDbJson").toComplexType();
		fields.push({
			pos:pos,
			name: "reload_"+uid,
			doc: "Update class values using the content of the CastleDB file (useful if you want to support hot-reloading of the CastleDB file)",
			access: [ APublic ],
			kind: FFun({
				args: [{ name:"updatedCdbJson", type:macro:String}],
				expr: macro {
					var json : $cdbJsonType = try haxe.Json.parse(updatedCdbJson) catch(_) null;
					if( json==null )
						return;

					for(s in json.sheets) {
						if( s.name!="ConstDb" )
							continue;

						for(l in s.lines) {
							var obj = Reflect.field(this, l.constId);
							if( obj==null ) {
								obj = {}
								Reflect.setField(this, l.constId, obj);
							}
							for(v in l.values) {
								var subValues = v.subValues==null ? [] : Reflect.fields(v.subValues);
								if( subValues.length>0 ) {
									// Reload sub values object
									var subObj = Reflect.field(obj, v.valueName);
									if( subObj==null ) {
										subObj = {};
										Reflect.setField(obj, v.valueName, subObj);
									}
									for(k in subValues)
										Reflect.setField(subObj, k, Reflect.field(v.subValues, k));

									// Also include (or remove) _value
									if( v.value!=0 )
										Reflect.setField(subObj, "_value", v.isInteger ? Std.int(v.value) : v.value );
									else
										Reflect.deleteField(subObj, "_value");
								}
								else {
									// Reload int/float value
									Reflect.setField(obj, v.valueName, v.isInteger ? Std.int(v.value) : v.value );
								}
							}
						}
					}
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