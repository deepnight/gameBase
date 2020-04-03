import dn.data.GetText;

class LangParser {
	public static function main() {
		var name = "sourceTexts";
		Sys.println("Building "+name+" file...");
		var cdbs = findAll("res", "cdb");
		try {
			var data = GetText.doParseGlobal({
				codePath: "src",
				codeIgnore: null,
				cdbFiles: cdbs,
				cdbSpecialId: [],
				potFile: "res/lang/"+name+".pot",
			});
		}
		catch(e:String) {
			Sys.println("");
			Sys.println(e);
			Sys.println("Extraction failed: fatal error!");
			Sys.println("");
			Sys.exit(1);
		}
		Sys.println("Done.");
	}

	static function findAll(path:String, ext:String, ?cur:Array<String>) {
		var ext = "."+ext;
		var all = cur==null ? [] : cur;
		for(e in sys.FileSystem.readDirectory(path)) {
			e = path+"/"+e;
			if( e.indexOf(ext)>=0 && e.lastIndexOf(ext)==e.length-ext.length )
				all.push(e);
			if( sys.FileSystem.isDirectory(e) && e.indexOf(".tmp")<0 )
				findAll(e, ext, all);
		}
		return all;
	}
}