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

enum Affect {
	Stun;
}

enum LevelMark {
}