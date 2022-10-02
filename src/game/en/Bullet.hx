package en;

class Bullet extends Entity {
	public function new(x,y, ang:Float, speed:Float) {
		super();
		setPosPixel(x,y);
		dx = Math.cos(ang)*speed;
		dy = Math.sin(ang)*speed;
		frict = 1;
	}
}