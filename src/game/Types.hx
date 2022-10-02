/**	This abstract enum is used by the Controller class to bind general game actions to actual keyboard keys or gamepad buttons. **/
enum abstract GameAction(Int) to Int {
	var MoveLeft;
	var MoveRight;
	var MoveUp;
	var MoveDown;

	var Atk;
	var Dodge;

	var Restart;

	var MenuUp;
	var MenuDown;
	var MenuOk;
	var MenuCancel;
	var Pause;

	var ToggleDebugDrone;
	var DebugDroneZoomIn;
	var DebugDroneZoomOut;
	var DebugTurbo;
	var DebugSlowMo;
	var ScreenshotMode;
}

/** Entity state machine. Each entity can only have 1 active State at a time. **/
enum abstract State(Int) {
	var Normal;
}


/** Entity Affects have a limited duration in time and you can stack different affects. **/
enum abstract Affect(Int) {
	var Stun;
	var Dodge;
	var Shield;
}

enum abstract LevelMark(Int) to Int {
	var Coll_Wall;
	var Coll_Temp;
}

enum abstract LevelSubMark(Int) to Int {
	var None; // 0
}

enum MobType {
	MT_Melee;
	MT_Gun;
	MT_Trash;
}

enum ItemType {
	RageCharge;
}