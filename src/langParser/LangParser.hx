import dn.data.GetText;

class LangParser {
	public static function main() {
		// Extract from source code
		var all = GetText.parseSourceCode("src");

		// Extract from LDtk
		all = all.concat( GetText.parseLdtk("res/levels/sampleWorld.ldtk", {
			entityFields: [], // fill this with Entity fields that should be extracted for localization
			levelFieldIds: [], // fill this with Level fields that should be extracted for localization
		}));

		// Extract from CastleDB
		all = all.concat( GetText.parseCastleDB("res/data.cdb") );

		// Write POT
		GetText.writePOT("res/lang/sourceTexts.pot",all);

		Sys.println("Done.");
	}
}