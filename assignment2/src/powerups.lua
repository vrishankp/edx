powerups = Class{}

function powerups:init(skin)

  self.width = 16
  self.height = 16

  self.dx = 0
  self.dy = 0

  self.skin = skin

  self.show = false
  self.powerupUsed = false
  self.inPlay = false

  self.x = 0
  self.y = 0

end

function powerups:collides(target)

  if self.x > target.x + target.width or target.x > self.x + self.width then
    return false
  end

  if self.y > target.y + target.height or target.y > self.y + self.height then
    return false
  end

  return true

end

function powerups:reset()
  self.x = VIRTUAL_WIDTH / 5 - 2
  self.y = VIRTUAL_HEIGHT / 2 - 2
  self.dx = 0
  self.dy = 0
  self.shown = false
end

function powerups:spawn(x, y)

  self.x = x
  self.y = y

  self.dx = 0
  self.dy = 0.5

  self.shown = true
end

function powerups:update(dt)
  self.y = self.y + self.dy
  self.x = self.x + self.dx
end

function powerups:render()
  love.graphics.draw(gTextures['main'], gFrames['powerups'][self.skin], self.x, self.y)
end
