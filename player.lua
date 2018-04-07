PlayerPulseX = 0 --Memory Location 0x0713
PlayerPulseY = 0 --Memory Location 0x070C
playerX = 0 --Memory Location 0x070F
EnemyX = 0 --
PlayerPulseTrig = 0 --Memory Location 0x0712
EnemyPulse = {} --X Memory Location 0x0717,0x071B,0x071F,0x0723,0x0727--Y Memory Location 0x0714,0x0718,0x072C,0x0720,0x0724
EnemyPulseTrig = {} --Memory Location 0x0716,0x071A,0x071E,0x0722,0x0726

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
WindowHeight = 240
WindowWidth = 255
pulsePos = {}
-------------Getters--------------------
function isPlayerPulseDead()
   PlayerPulseTrig = mainmemory.readbyte(0x0712)
   return PlayerPulseTrig
end

function isEnemyPulseDead()
	for i=0, 4 do
		EnemyPulseTrig[i] = mainmemory.readbyte(0x0716 + i*4)
	end
end

function GetPlayerPulsePos()
    pulseX = mainmemory.readbyte(0x0713)
    pulseY = mainmemory.readbyte(0x0710)
    pulsePos[0] = math.floor(pulseX)
    pulsePos[1] = math.floor(pulseY)
end

function GetEnemyPulsePos(i)
	local posloc = {}
    posloc[0] = mainmemory.readbyte(0x0717 + i*4)
    posloc[1] = mainmemory.readbyte(0x0714 + i*4)
	return posloc
end

function GetPlayerX()
    playerX = mainmemory.readbyte(0x070F)
    return math.floor(playerX)
end

function GetPlayerY()
    playerX = mainmemory.readbyte(0x070F)
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
    if(isPlayerPulseDead() == 0) then
        posloc = GetPlayerPulsePos()
        index = toCellX(pulsePos[0])+toCellY(pulsePos[1])*boxEdge
        cells[index] = 3
    end
	isEnemyPulseDead()
	for i=0, 4 do
		if(EnemyPulseTrig[i] == 0) then
			posloc = GetEnemyPulsePos(i)
			index = toCellX(posloc[0])+toCellY(posloc[1])*boxEdge
			cells[index] = 4
		end
    end
    x = toCellX(GetPlayerX())
    y = toCellY(GetPlayerY())
    cells[y*boxEdge+x] = 1
    
end

function toCellX(pos)
    return math.floor(pos*boxEdge/WindowWidth)
end

function toCellY(pos)
    return math.floor(pos*boxEdge/WindowHeight)
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
            if(cells[j*boxEdge + i]== 4) then
                gui.drawBox(i,j,i+1,j+1,green,green)
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
