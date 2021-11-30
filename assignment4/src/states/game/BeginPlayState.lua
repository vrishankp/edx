BeginPlayState = Class{__includes = BaseState}

function BeginPlayState:init()
  self.level = LevelMaker.generate(100, 10)
  self.tileMap = self.level.tileMap
  self.background = math.random(3)
end

function BeginPlayState:update(dt)

end
