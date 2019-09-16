import dn.data.GetText;

class LangParser {
	public static function main() {
		var name = "sourceTexts";
		Sys.println("Building "+name+" file...");
		var data = GetText.doParseGlobal({
			codePath: "src",
			codeIgnore: null,
			cdbFiles: [],
			cdbSpecialId: [],
			potFile: "res/lang/"+name+".pot",
		});
		Sys.println("Done.");
	}
}