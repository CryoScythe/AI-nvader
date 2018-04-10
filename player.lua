--------Player Variables-----------
PlayerPulseX = 0 --Memory Location 0x0713
PlayerPulseY = 0 --Memory Location 0x070C
playerX = 0 --Memory Location 0x070F
PlayerPulseTrig = 0 --Memory Location 0x0712
-----------------------------------

--------Enemy Variables------------
--Enemy location=basevalue+max(0,(variance-32))-- enemies 8 cells away
EnemyArray = {}
EnemyPulse = {} --X Memory Location 0x0717,0x071B,0x071F,0x0723,0x0727--Y Memory Location 0x0714,0x0718,0x072C,0x0720,0x0724
EnemyPulseTrig = {} --Memory Location 0x0716,0x071A,0x071E,0x0722,0x0726
-----------------------------------

--------Controller Input-----------
ButtonNames = {
    'A',
    'B',
    'Left',
    'Right'
}
-----------------------------------

--------General Color Codes--------
white = 0xFFFFFFFF
red = 0xFFFF0000
green = 0xFF00FF00
blue = 0xFF0000FF
yellow = 0xFFFFFF00
-----------------------------------

--------Window Specs---------------
boxEdge = 100
jump = 1
WindowHeight = 240
WindowWidth = 255
pulsePos = {}
separation = 4
initdist = 2004

------------Input Functions------------
function UpdateEnemyArray()
	baserotation = mainmemory.readbyte(0x00B9)
	if(math.floor(baserotation/12-1)%2==0) then
		basevalue = math.floor(baserotation/4)
	else
		basevalue = 5-math.floor(mainmemory.readbyte(0x00B9)/4)
	end
	for i=0, 19 do
		EnemyArray[i] = {}
		for j=0, 22 do
			EnemyArray[i][j] = mainmemory.readbyte(0x0242 + i*32 + j)
		end
	end
end

function GetSpriteState(val)
	return val-((math.floor(val/16))*16)
end

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
    pulsePos[0] = math.floor(pulseX-1)+1
    pulsePos[1] = math.floor(pulseY-1)+1
end

function GetEnemyPulsePos(i)
	local posloc = {}
    posloc[0] = mainmemory.readbyte(0x0717 + i*4)
    posloc[1] = mainmemory.readbyte(0x0714 + i*4)
	return posloc
end

function GetPlayerX()
    playerX = mainmemory.readbyte(0x070F)
    return math.floor(playerX-1)+1
end

function GetPlayerY()
    playerY = mainmemory.readbyte(0x070C)
    return math.floor(playerY-1)+1
end
---------------------------------------------------

--------------Cell and Visual------------------
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
	UpdateEnemyArray()
	console.clear()
	for i=0, 19 do
		for j=basevalue, 19+basevalue do
			if(EnemyArray[i][j] ~= 0) then
				index = initdist + i*boxEdge*separation + j*separation + (GetSpriteState(EnemyArray[i][j]))*(-1)^(math.floor(baserotation/12)) + 3*((math.floor(baserotation/12))%2)
				cells[index] = 2
			end
		end
	end
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
    return math.floor((pos*boxEdge/WindowWidth)-1)+1
end

function toCellY(pos)
    return math.floor((pos*boxEdge/WindowHeight)-1)+1
end

function drawContainer(offset,containersize,col)
	gui.drawRectangle(offset,offset,containersize,containersize,col,col)
end

function DrawWorkMap()
	drawContainer(1,boxEdge,0x33FFFFFF)
    for i = 1, boxEdge do
        for j = 1, boxEdge do
			if(cells[j*boxEdge + i]== 2) then --for enemy
                gui.drawBox(i,j,i+1,j+1,yellow,yellow)
			end
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
--------------------------------------------


-------------Game Loop------------------
while true do
    LoadCells()
    DrawWorkMap()
    emu.frameadvance()
end
------------Game Loop------------------
