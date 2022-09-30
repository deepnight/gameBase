import dn.data.GetText;

class LangParser {
	public static function main() {
		var allEntries : Array<PoEntry> = [];

		// Extract from source code
		GetText.parseSourceCode(allEntries, "src");

		// Extract from LDtk
		GetText.parseLdtk(allEntries, "res/levels/sampleWorld.ldtk", {
			entityFields: [], // fill this with Entity fields that should be extracted for localization
			levelFieldIds: [], // fill this with Level fields that should be extracted for localization
		});

		// Extract from CastleDB
		GetText.parseCastleDB(allEntries, "res/data.cdb");

		// Write POT
		GetText.writePOT("res/lang/sourceTexts.pot", allEntries);

		Sys.println("Done.");
	}
}