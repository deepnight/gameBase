import mt.data.GetText;

class Lang {
    public static var CUR = "??";
    static var initDone = false;

    public static function init(lid:String) {
        CUR = lid;
        initDone = true;
    }

    public static function untranslated(str:Dynamic) : LocaleString {
        if( !initDone )
            throw "Lang.init() required.";
        return cast str;
    }
}