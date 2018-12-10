import mt.data.GetText;

class Lang {
    public static var CUR = "??";

    public static function init(lid:String) {
        CUR = lid;
    }

    public static function untranslated(str:Dynamic) : LocaleString {
        return cast str;
    }
}