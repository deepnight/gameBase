
package solv;

import hxd.Math;
import h2d.SpriteBatch;

class DebugSolver {
    private var game(get,never) : Game; inline function get_game() return Game.ME;
	
    
    var solver: FluidSolver;
    var selectedCells:Array<Int>;

    var sb : h2d.SpriteBatch;
    var sbCells : Array<h2d.SpriteBatch.BatchElement>;
    var sbDirections : Array<h2d.SpriteBatch.BatchElement>;
    
    

    public function new(fluidSolver:FluidSolver) {
        solver = fluidSolver;
        sbCells = [];
        sbDirections = [];
        selectedCells = [];
        
        sb = new h2d.SpriteBatch(h2d.Tile.fromColor(Color.makeColorRgb(1,1,1),Const.GRID,Const.GRID));
        game.scroller.add(sb,Const.DP_SOLVER);
        sb.blendMode = Add;
        sb.hasUpdate = true;
        sb.hasRotationScale = true;
        
        fillDebugSpriteBatch();

        sb.visible = false;
        
    }
    
    public function renderDebugGrid() {
        
        if( ui.Console.ME.hasFlag("grid")){
            sb.visible = true;
            
            for(index in 0...sbCells.length){
                colorizeCellElement(index);
                rotateVectorElement(index);
            }
            
            lightSelectedCells();
            
        } 
        if(!ui.Console.ME.hasFlag("grid"))
            sb.visible = false;
    }
    
    public function turnOffListOfCells(list:Array<Int>){
        for(index in list){
            turnOffCellVisibility(index);
        }
    }

    public function pushSelectedCell(index:Int) {
        for (c in selectedCells){
            if (c == index)
                selectedCells.shift();
        }
        selectedCells.push(index);    
    }

    public function dispose() {
        sb.remove();
        sbCells = [];
        sbDirections = [];
        selectedCells = [];
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
    private function makeSpriteBatchCellElement(i:Int,j:Int){
        var squareCell = new BatchElement(h2d.Tile.fromColor(Color.makeColorRgb(1,1,1),Const.GRID-1,Const.GRID-1));
                squareCell.x = i*Const.GRID;
                squareCell.y = j*Const.GRID;
                squareCell.a = 0.3;
        return squareCell;      
    }

    private function makeSpriteBatchVectorElement(i:Int,j:Int){
        var vec = new BatchElement(Assets.tiles.getTile(D.tiles.vector12));
        vec.x = i*Const.GRID + Const.GRID/2;
        vec.y = j*Const.GRID + Const.GRID/2;
        vec.rotation = 0;
        return vec;
    }

    private function rotateVectorElement(index:Int) {
        var a = Math.atan2(solver.v[index],solver.u[index]);
        sbDirections[index].rotation = a;
        sbDirections[index].a =1*Math.sqrt((solver.u[index]*solver.u[index]+solver.v[index]*solver.v[index]));     
    }

    private function colorizeCellElement(index:Int){
        sbCells[index].r = Math.lerp(0,255,solver.v[index]);
        sbCells[index].g = 0 ;
        sbCells[index].b = Math.lerp(0,255,-solver.v[index]);
    }

    private function turnOffCellVisibility(index:Int) {
        sbCells[index].visible = false;
    }

    private function lightSelectedCells() {
        for (index in selectedCells){
            sbCells[index].r = 1;
            sbCells[index].g = 1;
            sbCells[index].b = 1;
        }
    }

}