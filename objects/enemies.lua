local grid = require 'utilities.grid'

local Enemies = {
	frame=1, 
	xSpawn = display.contentCenterX, 
	ySpawn = display.contentCenterY, 
	HP = 240,
	speed = 400,
	damage = 1,
	value = 60
}


function Enemies:new (o) --constructor
	o = o or {};

	setmetatable(o, self);
	self.__index = self;
	return o;
end
local soundTable = {
 -- shootSound = audio.loadSound( "shoot.wav" ),
 -- hitSound = audio.loadSound( "hit.wav" ),
 explodeSound = audio.loadSound( "Explosion8.wav" ),
}

local opt = 
{

	frames = { 
		{x = 100, y = 65, width = 25, height =30},--frame 1, value 75 
		{x = 60, y = 35, width = 35, height = 30}, --frame 2, HP 80, speed 400, 50 
		{x= 94, y = 35, width = 35, height = 30}, --frame 3, HP 800, speed 50, 150
		{x = 190, y = 224, width = 35, height = 30}, --frame 4
		{x = 225, y = 219, width = 35, height = 30}, --frame 5
	}
}

local sheet = graphics.newImageSheet( "spaceships2.png", opt)
function Enemies:spawn(game, startingId, shipType)
	local scale = 2.5

	if shipType == 'shipType1' then
		self.frame = 1
	elseif shipType == 'shipType2' then
		self.value = 30
		self.frame = 2
		self.HP = 120
		self.speed = 180
		scale = 2
	elseif shipType == 'shipType3' then
		self.value = 150
		self.frame = 3
		self.HP = 900
		self.speed = 600
		scale = 3.5
	end

	self.game = game
	self.startingId = startingId
	self.nodeId = startingId;
	self.shape= display.newImage( sheet, self.frame)
	self.shape.x = self.xSpawn
	self.shape.y = self.ySpawn
	self.shape.xScale = scale
	self.shape.yScale = scale
	self.shape.pp = self; -- parent object
	self.shape.tag = self.tag; -- “enemy”
	self.exploding = false
	self.destroy = false
	self.atGoal = false

	game.parentView:insert(self.shape)

	self:move(startingId)

	return self
end

function Enemies:hit(damage)
	self.HP = self.HP - damage
	if (self.HP <= 0) then
		-- die
		timer.cancel( self.timerRef )
		transition.cancel( self.transitionRef )
		
		self:explode()
	end
end

function Enemies:explode()
	local x = self.shape.x
	local y = self.shape.y
	self.exploding = true
	audio.play( soundTable["explodeSound"] )

	self.shape:removeSelf()
	self.shape = display.newImage( sheet, 4 )
	self.shape.x = x
	self.shape.y = y
	self.game.parentView:insert(self.shape)

	transition.to(self.shape, {
		alpha = 0,
		xScale = 2.5,
		yScale = 2.5,
		onComplete = function() 
			self.destroy = true
		end
	})
end

function Enemies:move()
	local current = self.game.grid[self.nodeId];
	local target = self.game.grid[current.cameFrom] or {};

	local x = grid.x(target.column)
	local y = grid.y(target.row)
	local it = self

	if x > self.shape.x then
		self.shape.rotation = 180
	elseif x < self.shape.x then
		self.shape.rotation = 0
	elseif y > self.shape.y then
		self.shape.rotation = 270
	elseif y < self.shape.y then
		self.shape.rotation = 90
	end


	self.timerRef = timer.performWithDelay( self.speed / 2, function() 
		self.nodeId = current.cameFrom
	end)

	self.transitionRef = transition.to(self.shape, {
		x = x,
		y = y,
		time = self.speed,
		onComplete = function()
			if target.type == 'goal' then
				self.atGoal = true
				self.destroy = true
			else
				it:move()
			end
		end
	})
end

function Enemies:dead()
	self.shape:removeSelf( )
	timer.cancel( self.timerRef )
	transition.cancel( self.transitionRef )
end

return Enemies