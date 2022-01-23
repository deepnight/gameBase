
package solv;

import hxd.Math;
import h2d.SpriteBatch;

class DebugSolver {
    private var game(get,never) : Game; inline function get_game() return Game.ME;
	
    var solver: FluidSolver;
    var sw:Int;
    var sh:Int; 
    var boundOffset:Int;
    var caseOffset:Int;

    var sb : h2d.SpriteBatch;
    var sbCells : Array<h2d.SpriteBatch.BatchElement>;
    var sbDirections : Array<h2d.SpriteBatch.BatchElement>;
    
    public function new(fluidSolver:FluidSolver) {
        solver = fluidSolver;
        sbCells = [];
        sbDirections = [];
        sb = new h2d.SpriteBatch(h2d.Tile.fromColor(Color.makeColorRgb(1,1,1),Const.GRID,Const.GRID));
        game.scroller.add(sb,Const.DP_SOLVER);
        sb.blendMode = Add;
        sb.hasUpdate = true;
        sb.hasRotationScale = true;

        sw = solver.width;
        sh = solver.height;
        caseOffset = 1;
        boundOffset = Const.GRID * caseOffset;

        fillDebugSpriteBatch();

        sb.visible = false;
        
    }
    public function turnOffListOfCells(list:Array<Int>){
        for(index in list){
            turnOffCellVisibility(index);
        }
    }

    public function updateGridDebugDraw() {
    
        if( ui.Console.ME.hasFlag("grid")){
            sb.visible = true;
		    var index:Int;
        
            for(j in 0...sh) {
                for(i in 0...sw) {
                    index = solver.getIndexForCellPosition(i,j);
                    if (index < sbCells.length){
                        colorizeCellElement(index);
                        rotateVectorElement(index);
                    }
                }
            }
        } 
        if(!ui.Console.ME.hasFlag("grid"))
            sb.visible = false;
    }
    
    public function dispose() {
        sb.remove();
        sbCells = [];
        sbDirections = [];
    }

    private function fillDebugSpriteBatch(){
        for(j in 0...solver.height) {
			for(i in 0...solver.width) {
                var cellBatchElement = makeSpriteBatchCellElement(i,j);
                sb.add(cellBatchElement);
                sbCells.push(cellBatchElement);
                var vectorBatchElement = makeSpriteBatchVectorElement(i,j);
                sb.add(vectorBatchElement);
                sbDirections.push(vectorBatchElement);
			}
		}
    }
    private function makeSpriteBatchCellElement(i,j){
        var squareCell = new BatchElement(h2d.Tile.fromColor(Color.makeColorRgb(1,1,1),Const.GRID-1,Const.GRID-1));
                squareCell.x = i*Const.GRID+1 - boundOffset;
                squareCell.y = j*Const.GRID+1 - boundOffset;
                squareCell.a = 0.3;
        return squareCell;      
    }

    private function makeSpriteBatchVectorElement(i,j){
        var vec = new BatchElement(Assets.tiles.getTile(D.tiles.vector12));
        vec.x = i*Const.GRID-boundOffset + Const.GRID/2;
        vec.y = j*Const.GRID-boundOffset + Const.GRID/2;
        vec.rotation = 0;
        return vec;
    }

    private function rotateVectorElement(index) {
        var a = Math.atan2(solver.v[index],solver.u[index]);
        sbDirections[index].rotation = a;
        sbDirections[index].a =1*Math.sqrt((solver.u[index]*solver.u[index]+solver.v[index]*solver.v[index]));     
    }

    private function centerVectorElement(index,i,j){
        sbDirections[index].x = i*Const.GRID-boundOffset + Const.GRID/2;
        sbDirections[index].y = j*Const.GRID-boundOffset + Const.GRID/2;
    }

    private function colorizeCellElement(index){
        sbCells[index].r = Math.lerp(0,255,solver.r[index]);
        sbCells[index].g = Math.lerp(0,255,solver.g[index]);
        sbCells[index].b = Math.lerp(0,255,solver.b[index]);
    }

    private function turnOffCellVisibility(sIndex:Int) {
        sbCells[sIndex].visible = false;
    }
}