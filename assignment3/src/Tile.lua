--[[
    GD50
    Match-3 Remake

    -- Tile Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The individual tiles that make up our game board. Each Tile can have a
    color and a variety, with the varietes adding extra points to the matches.
]]

Tile = Class{}

function Tile:init(x, y, color, variety)

    -- board positions
    self.gridX = x
    self.gridY = y

    -- coordinate positions
    self.x = (self.gridX - 1) * 32
    self.y = (self.gridY - 1) * 32

    -- tile appearance/points
    self.color = color
    self.variety = variety
    self.score = self.variety * 50

    local random = math.random(1, 20)

    if random == 1 then
      self.shiny = true
    else
      self.shiny = false
    end

      psystem = love.graphics.newParticleSystem(gTextures['particle'], 1000)

      psystem:setParticleLifetime(0.5, 1)

      psystem:setLinearAcceleration(-math.random(5), -math.random(5), math.random(5), math.random(5))

      psystem:setAreaSpread('normal', 7, 7)

      psystem:setColors(255, 255, 255, 128)

      psystem:setEmissionRate(30)

      psystem:setEmitterLifetime(10000)

      psystem:emit(30)
end

function Tile:update(dt)
  psystem:update(dt)
end

function Tile:render(x, y)

    -- draw shadow
    love.graphics.setColor(34, 32, 52, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x + 2, self.y + y + 2)

    -- draw tile itself
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x, self.y + y)

    if self.shiny == true then
      love.graphics.setColor(255, 255, 255, 200)
      love.graphics.draw(psystem, self.x + 16 + x, self.y + 16 + y)
    end
end
