package ui.win;

class DebugWindow extends ui.Window {
	public var updateCooldownS = 0.0;

	public function new(?renderCb:DebugWindow->Void) {
		super(false);

		if( renderCb!=null )
			this.renderCb = renderCb;

		content.backgroundTile = Col.white().toTile(1,1, 0.5);
		content.padding = 4;
		content.horizontalSpacing = 4;
		content.verticalSpacing = 0;
		content.layout = Vertical;
		setAlign(End,Start);
	}

	public dynamic function renderCb(thisWin:DebugWindow) {}

	override function onResize() {
		super.onResize();
		switch verticalAlign {
			case Start,End: content.maxHeight = Std.int( 0.4 * stageHei/Const.UI_SCALE );
			case Center: content.maxHeight = Std.int( 0.8 * stageHei/Const.UI_SCALE );
			case Fill: content.maxHeight = Std.int( stageHei/Const.UI_SCALE );
		}
	}

	override function update() {
		super.update();
		if( updateCooldownS<=0 || !cd.hasSetS("updateLock",updateCooldownS) )
			renderCb(this);
	}
}