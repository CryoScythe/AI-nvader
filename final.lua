ButtonNames = {
    "A",
    "Right",
    "Left",
}
boxEdge = 100
nesHeight = 240
nesWidth = 255
pulsePos = {}
enemyPulse = {}
enemyPulsePos = {}
Outputs = #ButtonNames
Inputs = 10101

time=0
Population = 300
DeltaDisjoint = 2.0
DeltaWeights = 0.4
DeltaThreshold = 1.0

StaleSpecies = 15

MutateConnectionsChance = 0.25
PerturbChance = 0.90
CrossoverChance = 0.75
LinkMutationChance = 2.0
NodeMutationChance = 0.50
BiasMutationChance = 0.40
StepSize = 0.1
DisableMutationChance = 0.4
EnableMutationChance = 0.2

TimeoutConstant = 20

MaxNodes = 10100


function update(i, val)
	varVal[i] = val
end
function register(name)
	table.insert(varName,name)
	return (#varName - 1)
end

function drawText()
    if #varName == #varVal then
        for i = 0, #varName do
            forms.drawText(pbox,offsetX,offsetY+20*(i),varName[i])
            forms.drawText(pbox,offsetX+100,offsetY+20*(i),varVal[i])
        end
    end

end
function clearDebugger()
	varName = {}
	varVal = {}
end
SaveName = "SI.State"
ButtonNames = {
      "A",
	  "Left",
      "Right",
}
boxEdge = 100
nesHeight = 240
nesWidth = 255
pulsePos = {}
enemyPulse = {}
enemyPulsePos = {}
Outputs = #ButtonNames


-------------Getters--------------------
function UpdateEnemyArray()
	baserotation = mainmemory.readbyte(0x00B9)+1
	basevalue = (math.floor((baserotation+(math.floor(baserotation)/12)%2)/4)%3)*((-1)^(math.floor((baserotation)/12))) + 2*((math.floor((baserotation)/12))%2)
	for i=0, 19 do
		EnemyArray[i] = {}
		for j=0, 22 do
			EnemyArray[i][j] = mainmemory.readbyte(0x0242 + i*32 + j)
		end
	end
end


function checkEnemyPulse()
    enemyPulse[0] = mainmemory.readbyte(0x0716)
    enemyPulse[1] = mainmemory.readbyte(0x071A)
    enemyPulse[2] = mainmemory.readbyte(0x071E)
    enemyPulse[3] = mainmemory.readbyte(0x0722)
    enemyPulse[4] = mainmemory.readbyte(0x0726)
end
function getEnemyPulsePos(i)
    local pos = {}
    pos[0] = mainmemory.readbyte(0x0717 + i*4)
    pos[1] = mainmemory.readbyte(0x0714 + i*4)
    return pos
end
function isPlayerAlive()
	return mainmemory.readbyte(0x22D)
end
function checkPulse()
   pulseTrig = mainmemory.readbyte(0x0712);
   return pulseTrig
end
function getPulsePos()
    pulseX = mainmemory.readbyte(0x0713)
    pulseY = mainmemory.readbyte(0x0710)
    pulsePos[0] = pulseX
    pulsePos[1] = pulseY
end
function getPlayerX()
    playerX = mainmemory.readbyte(0x070F)
    return playerX
end

function getPlayerY()
    return mainmemory.readbyte(0x070C)
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
clearCells()
function isPlayerAlive()
    val = mainmemory.readbyte(0x022D)
    return val == 42
end
function LoadCells()
    cells = {}
    clearCells()
	UpdateEnemyArray();
    if(checkPulse() == 0) then
        pos = getPulsePos()
        index = toCellX(pulsePos[0])+toCellY(pulsePos[1])*boxEdge
        cells[index] = 3
    end
    checkEnemyPulse()
    for i = 0, 4 do
        if(enemyPulse[i]==0) then
            pos = getEnemyPulsePos(i)
            index = toCellX(pos[0])+toCellY(pos[1])*boxEdge
            cells[index] = 4
        end
    end
    x = toCellX(getPlayerX())
    y = toCellY(getPlayerY())
    cells[y*boxEdge+x] = 1
end

function toCellX(pos)
    return math.floor(pos*boxEdge/nesWidth)
end

function toCellY(pos)
    return math.floor(pos*boxEdge/nesHeight)
end


function DrawBox()
     gui.drawRectangle(0,0,100,100,0x33FFFFFF,0x33FFFFFF)
     local val = 0
     for i = 1, boxEdge do
        for j = 1, boxEdge do 
            val = cells[j*boxEdge + i]
            if(val == 2) then
                gui.drawBox(i,j,i+1,j+1,blue,blue)
            end
            if(val == 3) then
                gui.drawBox(i,j,i+1,j+1,red,blue)
            end
            if(val == 4) then
                gui.drawBox(i,j,i+1,j+1,green,blue)
            end
        end
    end


     x = toCellX(getPlayerX())
     y = toCellY(getPlayerY())
     
     gui.drawBox(x,y,x+1,y+1,blue,red)
end
function getScore()
	return mainmemory.readbyte(0x0022)
end
--------------Cell Fns-------------------
function executeInputs()
	drawText()
	joypad.set(controller)
	table = joypad.getimmediate()
	console.writeline(tostring(table["P1 A"]))
	emu.frameadvance();
	clearCells()
	joypad.set(controller)
	table = joypad.getimmediate()
	console.writeline(tostring(table["P1 A"]))
	emu.frameadvance()
	clearDebugger()
	forms.refresh(pbox)
end

-------------NEAT Algorithm Code-----------
function getInputs()
	LoadCells()
	local inputs = {}
    inputs  = cells	
	return inputs
end


function sigmoid(x)
	return 2/(1+math.exp(-4.9*x))-1
end

function newInnovation()
	pool.innovation = pool.innovation + 1
	return pool.innovation
end

function newPool()
	local pool = {}
	pool.species = {}
	pool.generation = 0
	pool.innovation = Outputs
	pool.currentSpecies = 1
	pool.currentGenome = 1
	pool.currentFrame = 0
	pool.maxFitness = 0
	
	return pool
end

function newSpecies()
	local species = {}
	species.topFitness = 0
	species.staleness = 0
	species.genomes = {}
	species.averageFitness = 0
	
	return species
end

function newGenome()
	local genome = {}
	genome.genes = {}
	genome.fitness = 0
	genome.adjustedFitness = 0
	genome.network = {}
	genome.maxneuron = 0
	genome.globalRank = 0
	genome.mutationRates = {}
	genome.mutationRates["connections"] = MutateConnectionsChance
	genome.mutationRates["link"] = LinkMutationChance
	genome.mutationRates["bias"] = BiasMutationChance
	genome.mutationRates["node"] = NodeMutationChance
	genome.mutationRates["enable"] = EnableMutationChance
	genome.mutationRates["disable"] = DisableMutationChance
	genome.mutationRates["step"] = StepSize
	
	return genome
end

function copyGenome(genome)
	local genome2 = newGenome()
	for g=1,#genome.genes do
		table.insert(genome2.genes, copyGene(genome.genes[g]))
	end
	genome2.maxneuron = genome.maxneuron
	genome2.mutationRates["connections"] = genome.mutationRates["connections"]
	genome2.mutationRates["link"] = genome.mutationRates["link"]
	genome2.mutationRates["bias"] = genome.mutationRates["bias"]
	genome2.mutationRates["node"] = genome.mutationRates["node"]
	genome2.mutationRates["enable"] = genome.mutationRates["enable"]
	genome2.mutationRates["disable"] = genome.mutationRates["disable"]
	
	return genome2
end


function basicGenome()
	local genome = newGenome()
	local innovation = 1

	genome.maxneuron = Inputs
	mutate(genome)
	
	return genome
end

function newGene()
	local gene = {}
	gene.into = 0
	gene.out = 0
	gene.weight = 0.0
	gene.enabled = true
	gene.innovation = 0
	
	return gene
end

function copyGene(gene)
	local gene2 = newGene()
	gene2.into = gene.into
	gene2.out = gene.out
	gene2.weight = gene.weight
	gene2.enabled = gene.enabled
	gene2.innovation = gene.innovation
	
	return gene2
end

function newNeuron()
	local neuron = {}
	neuron.incoming = {}
	neuron.value = 0.0
	
	return neuron
end

function generateNetwork(genome)
	local network = {}
	network.neurons = {}
	
	for i=1,Inputs do
		network.neurons[i] = newNeuron()
	end
	
	for o=1,Outputs do
		network.neurons[MaxNodes+o] = newNeuron()
	end
	
	table.sort(genome.genes, function (a,b)
		return (a.out < b.out)
	end)
	for i=1,#genome.genes do
		local gene = genome.genes[i]
		if gene.enabled then
			if network.neurons[gene.out] == nil then
				network.neurons[gene.out] = newNeuron()
			end
			local neuron = network.neurons[gene.out]
			table.insert(neuron.incoming, gene)
			if network.neurons[gene.into] == nil then
				network.neurons[gene.into] = newNeuron()
			end
		end
	end
	
	genome.network = network
end

function evaluateNetwork(network, inputs)
   
	table.insert(inputs,1)
	if #inputs ~= Inputs then
        console.writeline("Incorrect number of neural network inputs. #inputs: "..#inputs)
        console.writeline("Number of Inputs"..Inputs)
		return {}
	end
	
	for i=1,Inputs do
		network.neurons[i].value = inputs[i]
	end
	
	for _,neuron in pairs(network.neurons) do
		local sum = 0
		for j = 1,#neuron.incoming do
			local incoming = neuron.incoming[j]
			local other = network.neurons[incoming.into]
			sum = sum + incoming.weight * other.value
		end
		
		if #neuron.incoming > 0 then
			neuron.value = sigmoid(sum)
		end
	end
	
	local outputs = {}
	for o=1,Outputs do
		local button = "P1 " .. ButtonNames[o]
		if network.neurons[MaxNodes+o].value > 0 then
			outputs[button] = true
		else
			outputs[button] = false
		end
	end
	
	return outputs
end

function crossover(g1, g2)
        -- Make sure g1 is the higher fitness genome
        if g2.fitness > g1.fitness then
                tempg = g1
                g1 = g2
                g2 = tempg
        end
 
        local child = newGenome()
       
        local innovations2 = {}
        for i=1,#g2.genes do
                local gene = g2.genes[i]
                innovations2[gene.innovation] = gene
        end
       
        for i=1,#g1.genes do
                local gene1 = g1.genes[i]
                local gene2 = innovations2[gene1.innovation]
                if gene2 ~= nil and math.random(2) == 1 and gene2.enabled then
                        table.insert(child.genes, copyGene(gene2))
                else
                        table.insert(child.genes, copyGene(gene1))
                end
        end
       
        child.maxneuron = math.max(g1.maxneuron,g2.maxneuron)
       
        for mutation,rate in pairs(g1.mutationRates) do
                child.mutationRates[mutation] = rate
        end
       
        return child
end

function randomNeuron(genes, nonInput)
	local neurons = {}
	if not nonInput then
		for i=1,Inputs do
			neurons[i] = true
		end
	end
	for o=1,Outputs do
		neurons[MaxNodes+o] = true
	end
	for i=1,#genes do
		if (not nonInput) or genes[i].into > Inputs then
			neurons[genes[i].into] = true
		end
		if (not nonInput) or genes[i].out > Inputs then
			neurons[genes[i].out] = true
		end
	end

	local count = 0
	for _,_ in pairs(neurons) do
		count = count + 1
	end
	local n = math.random(1, count)
	
	for k,v in pairs(neurons) do
		n = n-1
		if n == 0 then
			return k
		end
	end
	
	return 0
end


function containsLink(genes, link)
	for i=1,#genes do
		local gene = genes[i]
		if gene.into == link.into and gene.out == link.out then
			return true
		end
	end
end

function pointMutate(genome)
	local step = genome.mutationRates["step"]
	
	for i=1,#genome.genes do
		local gene = genome.genes[i]
		if math.random() < PerturbChance then
			gene.weight = gene.weight + math.random() * step*2 - step
		else
			gene.weight = math.random()*4-2
		end
	end
end

function linkMutate(genome, forceBias)
	local neuron1 = randomNeuron(genome.genes, false)
	local neuron2 = randomNeuron(genome.genes, true)
	 
	local newLink = newGene()
	if neuron1 <= Inputs and neuron2 <= Inputs then
		--Both input nodes
		return
	end
	if neuron2 <= Inputs then
		-- Swap output and input
		local temp = neuron1
		neuron1 = neuron2
		neuron2 = temp
	end

	newLink.into = neuron1
	newLink.out = neuron2
	if forceBias then
		newLink.into = Inputs
	end
	
	if containsLink(genome.genes, newLink) then
		return
	end
	newLink.innovation = newInnovation()
	newLink.weight = math.random()*4-2
	
	table.insert(genome.genes, newLink)
end

function nodeMutate(genome)
	if #genome.genes == 0 then
		return
	end

	genome.maxneuron = genome.maxneuron + 1

	local gene = genome.genes[math.random(1,#genome.genes)]
	if not gene.enabled then
		return
	end
	gene.enabled = false
	
	local gene1 = copyGene(gene)
	gene1.out = genome.maxneuron
	gene1.weight = 1.0
	gene1.innovation = newInnovation()
	gene1.enabled = true
	table.insert(genome.genes, gene1)
	
	local gene2 = copyGene(gene)
	gene2.into = genome.maxneuron
	gene2.innovation = newInnovation()
	gene2.enabled = true
	table.insert(genome.genes, gene2)
end

function enableDisableMutate(genome, enable)
	local candidates = {}
	for _,gene in pairs(genome.genes) do
		if gene.enabled == not enable then
			table.insert(candidates, gene)
		end
	end
	
	if #candidates == 0 then
		return
	end
	
	local gene = candidates[math.random(1,#candidates)]
	gene.enabled = not gene.enabled
end

function mutate(genome)
	for mutation,rate in pairs(genome.mutationRates) do
		if math.random(1,2) == 1 then
			genome.mutationRates[mutation] = 0.95*rate
		else
			genome.mutationRates[mutation] = 1.05263*rate
		end
	end

	if math.random() < genome.mutationRates["connections"] then
		pointMutate(genome)
	end
	
	local p = genome.mutationRates["link"]
	while p > 0 do
		if math.random() < p then
			linkMutate(genome, false)
		end
		p = p - 1
	end

	p = genome.mutationRates["bias"]
	while p > 0 do
		if math.random() < p then
			linkMutate(genome, true)
		end
		p = p - 1
	end
	
	p = genome.mutationRates["node"]
	while p > 0 do
		if math.random() < p then
			nodeMutate(genome)
		end
		p = p - 1
	end
	
	p = genome.mutationRates["enable"]
	while p > 0 do
		if math.random() < p then
			enableDisableMutate(genome, true)
		end
		p = p - 1
	end

	p = genome.mutationRates["disable"]
	while p > 0 do
		if math.random() < p then
			enableDisableMutate(genome, false)
		end
		p = p - 1
	end
end




---------------------------Compatibility----------------------------
function disjoint(genes1, genes2)
	local i1 = {}
	for i = 1,#genes1 do
		local gene = genes1[i]
		i1[gene.innovation] = true
	end

	local i2 = {}
	for i = 1,#genes2 do
		local gene = genes2[i]
		i2[gene.innovation] = true
	end
	
	local disjointGenes = 0
	for i = 1,#genes1 do
		local gene = genes1[i]
		if not i2[gene.innovation] then
			disjointGenes = disjointGenes+1
		end
	end
	
	for i = 1,#genes2 do
		local gene = genes2[i]
		if not i1[gene.innovation] then
			disjointGenes = disjointGenes+1
		end
	end
	
	local n = math.max(#genes1, #genes2)
	
	return disjointGenes / n
end

function weights(genes1, genes2)
	local i2 = {}
	for i = 1,#genes2 do
		local gene = genes2[i]
		i2[gene.innovation] = gene
	end

	local sum = 0
	local coincident = 0
	for i = 1,#genes1 do
		local gene = genes1[i]
		if i2[gene.innovation] ~= nil then
			local gene2 = i2[gene.innovation]
			sum = sum + math.abs(gene.weight - gene2.weight)
			coincident = coincident + 1
		end
	end
	
	return sum / coincident
end
	
function sameSpecies(genome1, genome2)
	local dd = DeltaDisjoint*disjoint(genome1.genes, genome2.genes)
	local dw = DeltaWeights*weights(genome1.genes, genome2.genes) 
	return dd + dw < DeltaThreshold
end

---------------------------/Compatibility----------------------------


--------------------------Ranking and Weeding------------------------
function rankGlobally()
	local global = {}
	for s = 1,#pool.species do
		local species = pool.species[s]
		for g = 1,#species.genomes do
			table.insert(global, species.genomes[g])
		end
	end
	table.sort(global, function (a,b)
		return (a.fitness < b.fitness)
	end)
	
	for g=1,#global do
		global[g].globalRank = g
	end
end

function calculateAverageFitness(species)
	local total = 0
	
	for g=1,#species.genomes do
		local genome = species.genomes[g]
		total = total + genome.globalRank
	end
	
	species.averageFitness = total / #species.genomes
end

function totalAverageFitness()
	local total = 0
	for s = 1,#pool.species do
		local species = pool.species[s]
		total = total + species.averageFitness
	end

	return total
end

function cullSpecies(cutToOne)
	for s = 1,#pool.species do
		local species = pool.species[s]
		
		table.sort(species.genomes, function (a,b)
			return (a.fitness > b.fitness)
		end)
		
		local remaining = math.ceil(#species.genomes/2)
		if cutToOne then
			remaining = 1
		end
		while #species.genomes > remaining do
			table.remove(species.genomes)
		end
	end
end

function breedChild(species)
	local child = {}
	if math.random() < CrossoverChance then
		g1 = species.genomes[math.random(1, #species.genomes)]
		g2 = species.genomes[math.random(1, #species.genomes)]
		child = crossover(g1, g2)
	else
		g = species.genomes[math.random(1, #species.genomes)]
		child = copyGenome(g)
	end
	
	mutate(child)
	
	return child
end

function removeStaleSpecies()
	local survived = {}

	for s = 1,#pool.species do
		local species = pool.species[s]
		
		table.sort(species.genomes, function (a,b)
			return (a.fitness > b.fitness)
		end)
		
		if species.genomes[1].fitness > species.topFitness then
			species.topFitness = species.genomes[1].fitness
			species.staleness = 0
		else
			species.staleness = species.staleness + 1
		end
		if species.staleness < StaleSpecies or species.topFitness >= pool.maxFitness then
			table.insert(survived, species)
		end
	end

	pool.species = survived
end

function removeWeakSpecies()
	local survived = {}

	local sum = totalAverageFitness()
	for s = 1,#pool.species do
		local species = pool.species[s]
		breed = math.floor(species.averageFitness / sum * Population)
		if breed >= 1 then
			table.insert(survived, species)
		end
	end

	pool.species = survived
end


function addToSpecies(child)
	local foundSpecies = false
	for s=1,#pool.species do
		local species = pool.species[s]
		if not foundSpecies and sameSpecies(child, species.genomes[1]) then
			table.insert(species.genomes, child)
			foundSpecies = true
		end
	end
	
	if not foundSpecies then
		local childSpecies = newSpecies()
		table.insert(childSpecies.genomes, child)
		table.insert(pool.species, childSpecies)
	end
end
-------------------------/Ranking and Weeding------------------------
function newGeneration()
	cullSpecies(false) -- Cull the bottom half of each species
	rankGlobally()
	removeStaleSpecies()
	rankGlobally()
	for s = 1,#pool.species do
		local species = pool.species[s]
		calculateAverageFitness(species)
	end
	removeWeakSpecies()
	local sum = totalAverageFitness()
	local children = {}
	for s = 1,#pool.species do
		local species = pool.species[s]
		breed = math.floor(species.averageFitness / sum * Population) - 1
		for i=1,breed do
			table.insert(children, breedChild(species))
		end
	end
	cullSpecies(true) -- Cull all but the top member of each species
	while #children + #pool.species < Population do
		local species = pool.species[math.random(1, #pool.species)]
		table.insert(children, breedChild(species))
	end
	for c=1,#children do
		local child = children[c]
		addToSpecies(child)
	end
	
	pool.generation = pool.generation + 1
	
	writeFile("backup." .. pool.generation .. "." .. forms.gettext(saveLoadFile))
end
	
function initializePool()
	pool = newPool()

	for i=1,Population do
		basic = basicGenome()
		addToSpecies(basic)
	end

	initializeRun()
end

function clearJoypad()
	controller = {}
	for b = 1,#ButtonNames do
		controller["P1 " .. ButtonNames[b]] = false
	end
	joypad.set(controller)
end

function initializeRun()
    savestate.load(SaveName)
	time = 0;
    previousX = getPlayerX()
	pool.currentFrame = 0
	timeout = TimeoutConstant
	clearJoypad()
	
	local species = pool.species[pool.currentSpecies]
	local genome = species.genomes[pool.currentGenome]
	generateNetwork(genome)
	evaluateCurrent()
end
function evaluateCurrent()
	local species = pool.species[pool.currentSpecies]
	local genome = species.genomes[pool.currentGenome]

	inputs = getInputs()
	controller = evaluateNetwork(genome.network, inputs)
	
	if controller["P1 Left"] and controller["P1 Right"] then
		controller["P1 Left"] = false
		controller["P1 Right"] = false
    end
    
    joypad.set(controller)
    
    if controller["P1 A"] then
        hasPressedA = true
    end

end

if pool == nil then
        initializePool()
end

function nextGenome()
	pool.currentGenome = pool.currentGenome + 1
	if pool.currentGenome > #pool.species[pool.currentSpecies].genomes then
		pool.currentGenome = 1
		pool.currentSpecies = pool.currentSpecies+1
		if pool.currentSpecies > #pool.species then
			newGeneration()
			pool.currentSpecies = 1
		end
	end
end

function fitnessAlreadyMeasured()
	local species = pool.species[pool.currentSpecies]
	local genome = species.genomes[pool.currentGenome]
	return genome.fitness ~= 0
end

while true do
  	local species = pool.species[pool.currentSpecies]
    local genome = species.genomes[pool.currentGenome]
    
    if pool.currentFrame%5 == 0 then
		evaluateCurrent()
	end
    
  	joypad.set(controller)
	
	local timeoutBonus = pool.currentFrame / 4
    
    if timeout + timeoutBonus <= 0 then
        local fitness = time - pool.currentFrame / 2
		if fitness <= 0 then
			fitness = -1
		end
		genome.fitness = fitness
       
		if mainmemory.readbyte(0x29) == 1 then
			genome.fitness = genome.fitness - 800
			initializeRun()
		end
	   
		if fitness > pool.maxFitness then
			pool.maxFitness = fitness
		end
		pool.currentSpecies = 1
        pool.currentGenome = 1
        
        while fitnessAlreadyMeasured() do
            nextGenome()
		end
		initializeRun()
	end
	
	local measured = 0
    local total = 0
    
	for _,species in pairs(pool.species) do
		for _,genome in pairs(species.genomes) do
			total = total + 1
			if genome.fitness ~= 0 then
				measured = measured + 1
			end
		end
	end
    
    if(pool.currentFrame % 50 == 0) then
		console.writeline("Gen " .. pool.generation .. " species " .. pool.currentSpecies .. " genome " .. pool.currentGenome .. " (" .. math.floor(measured/total*100) .. "%)")
		console.writeline("Fitness: " .. math.floor(time - (pool.currentFrame) / 2 - (timeout + timeoutBonus)*2/3))
        console.writeline("Max Fitness: " .. math.floor(pool.maxFitness))
    end
    
    
    if(isPlayerAlive) then
    	time = time + 1	
    end
    
    pool.currentFrame = pool.currentFrame + 1

    DrawBox()
    
    emu.frameadvance()

    
    
    previousX = playerX
    if hasPressedA then
        clearJoypad()
        hasPressedA = false
    end

end