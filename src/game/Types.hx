/**	This enum is used by the Controller class to bind general game actions to actual keyboard keys or gamepad buttons. **/
enum GameAction {
	MoveLeft;
	MoveRight;
	MoveUp;
	MoveDown;

	Jump;
	Restart;

	MenuCancel;
	Pause;

	ToggleDebugDrone;
	DebugDroneZoomIn;
	DebugDroneZoomOut;
	DebugTurbo;
	DebugSlowMo;
	ScreenshotMode;
}

/** Entity state machine. Each entity can only have 1 active State at a time. **/
enum State {
	Normal;
}


/** Entity Affects have a limited duration in time and you can stack different affects. **/
enum Affect {
	Stun;
}

enum LevelMark {
}

enum abstract LevelSubMark(Int) to Int {
	var None; // 0
}