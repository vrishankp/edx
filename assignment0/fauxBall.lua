--Fake ball that precedes the other balll and used in order for the Computer to seem more human-like


fauxBall = Class{}

function fauxBall:init(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height

  self.dy = 0
  self.dx = 0
end


--Called to relocate the faux ball (usually to the real ball)
function fauxBall:lead(x, y)
  self.x = x
  self.y = y
end

function fauxBall:reset()
  self.dx = 0
  self.dy = 0

end

function fauxBall:update(dt)

  self.x = self.x + self.dx * dt
  self.y = self.y + self.dy * dt

end

function fauxBall:render()
  --This color is used to see the faux ball (during development)
--  love.graphics.setColor(255, 0, 0, 255)
  --When not in development, the faux ball matches the background, allowing it
  --becomes invisibile
  love.graphics.setColor(40, 45, 52, 255)
  love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
  love.graphics.setColor(255, 255, 255, 255)
end
