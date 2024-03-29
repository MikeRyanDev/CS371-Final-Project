local Enemy = require 'objects.enemies'
local grid = require 'utilities.grid'
local composer = require 'composer'
local levelcounter = 1

local Spawn = {}

function Spawn:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	return o
end

function Spawn:init(id, node, game)
	self.timers = {}
	self.id = id
	self.node = node
	self.enemies = game.waves 

	self.game = game

	self:createWaves()
	local opt = {
		frames = {
			{x = 0, y = 0, width = 60, height = 60}
		}
	}
	
	local sheet = graphics.newImageSheet( "portalspawnpoint.png", opt)
	self.shape = display.newImage( sheet, self.frame)
	self.shape.x = grid.x(node.column)
	self.shape.y = grid.y(node.row)
	self.shape.xScale = 2.25
	self.shape.yScale = 2.25

	game.parentView:insert(self.shape)
end

function Spawn:createWaves()
	math.randomseed( os.time() )

	local function shuffleTable( t )
	    local rand = math.random 
	    local iterations = #t
	    local j
	    
	    for i = iterations, 2, -1 do
	        j = rand(i)
	        t[i], t[j] = t[j], t[i]
	    end

	    return t
	end

	local waves = {}
	
	for index,wave in ipairs(self.enemies) do
		local targetWave = {}

		for shipType, count in pairs(wave) do
			local i = 1;

			while i <= count do
				table.insert(targetWave, shipType)
				i = i + 1
			end
		end

		table.insert(waves, shuffleTable(targetWave))
	end

	self.waves = waves;
end

function Spawn:begin()
	local index = 1
	local movetonextlevel = 1
		local function wave()
		local time = 0
		for index,shipType in ipairs(self.waves[index]) do
			local function spawn()
				local enemy = Enemy:new()
				enemy.xSpawn = grid.x(self.node.column)
				enemy.ySpawn = grid.y(self.node.row)

				enemy:spawn(self.game, self.id, shipType)
				table.insert(self.game.enemies, enemy)
			end

			time = time + 900

			table.insert(self.timers, timer.performWithDelay(time, spawn))
		end
		index = index + 1
		movetonextlevel = movetonextlevel + 1
	end
	if movetonextlevel ~= 10 then
		wave()
    elseif levelcounter == 2 and movetonextlevel == 10 then
    	composer.gotoScene( 'views.level', {
			params = {
				level = 2
			}
		})
    elseif movetonextlevel == 10 and levelcounter == 3 then
    	composer.gotoScene( 'views.level', {
			params = {
				level = 3
			}
		})
    end
    	self.timerRef = timer.performWithDelay(30000, wave, 9)
end

function Spawn:stop()
	timer.cancel(self.timerRef)
	for index,timerRef in ipairs(self.timers) do
		timer.cancel(timerRef)
	end
end

return Spawn