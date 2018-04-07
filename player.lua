pulseX = 0 --Memory Location 0x0713
pulseY = 0 --Memory Location 0x070C
pulseTrig = 0 --Memory Location 0x0712
playerX = 0 --Memory Location 0x070F

ButtonNames = {
    'A',
    'B',
    'Left',
    'Right'
}
white = 0xFFFFFFFF
red = 0xFFFF0000
green = 0xFF00FF00
blue = 0xFF0000FF

boxEdge = 100
nesHeight = 240
nesWidth = 255
pulsePos = {}
-------------Getters--------------------
function isPulseDead()
   pulseTrig = mainmemory.readbyte(0x0712);
   return pulseTrig
end
function GetPulsePos()
    pulseX = mainmemory.readbyte(0x0713)
    pulseY = mainmemory.readbyte(0x0710)
    pulsePos[0] = math.floor(pulseX)
    pulsePos[1] = math.floor(pulseY)
end
function GetPlayerX()
    playerX = mainmemory.readbyte(0x070F)
    return math.floor(playerX)
end

function GetPlayerY()
    return math.floor(mainmemory.readbyte(0x070C))
end
--------------Getters--------------------

--------------Cell Fns-------------------
cells = {}

function clearCells()
    for i = 1, boxEdge do
        for j = 1, boxEdge do
            cells[j*boxEdge+i] = 0
        end
    end

end

function LoadCells()
    clearCells()
    if(isPulseDead() == 0) then
        GetPulsePos()
        index = toCellX(pulsePos[0])+toCellY(pulsePos[1])*boxEdge
        cells[index] = 3
    end
    x = toCellX(GetPlayerX())
    y = toCellY(GetPlayerY())
    cells[y*boxEdge+x] = 1
    
end

function toCellX(pos)
    return math.floor(pos*boxEdge/nesWidth)
end

function toCellY(pos)
    return math.floor(pos*boxEdge/nesHeight)
end
function drawContainer(offset,containersize,col)
	gui.drawRectangle(offset,offset,containersize,containersize,col,col)
end


function DrawWorkMap()
	drawContainer(1,100,0x33FFFFFF)
     for i = 1, boxEdge do
        for j = 1, boxEdge do 
            if(cells[j*boxEdge + i]== 3) then
                gui.drawBox(i,j,i+1,j+1,white,white)
            end
        end
    end
     
     gui.drawBox(x,y,x+1,y+1,blue,blue)
end
--------------Cell Fns-------------------


-------------Game Loop------------------
while true do
    LoadCells()
    DrawWorkMap()
    emu.frameadvance()
end
------------Game Loop------------------