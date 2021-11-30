--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.level = params.level

    self.ball = {
      [1] = params.ball1,
      [2] = params.ball2,
      [3] = params.ball3
    }

    self.ball[1].dx = math.random(-200, 200)
    self.ball[1].dy = math.random(-60, -50)


    -- give ball random starting velocity



    --initilize powerups
    self.powerups = {
      ['key'] = powerups(10),
      ['ball'] = powerups(9)

    }


--    powerups:init(10)

end

function PlayState:load()

end

function PlayState:update(dt)

  if not self.paused then
    self.powerups['key']:update(dt)
    self.powerups['ball']:update(dt)

    self.ball[1]:update(dt)
    self.ball[2]:update(dt)
    self.ball[3]:update(dt)
  end

    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
            love.audio.resume()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        love.audio.pause()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    function ballCollision(x)
        if self.ball[x]:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            self.ball[x].y = self.paddle.y - 8
            self.ball[x].dy = -self.ball[x].dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if self.ball[x].x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                self.ball[x].dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball[x].x))

            -- else if we hit the paddle on its right side while moving right...
            elseif self.ball[x].x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                self.ball[x].dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball[x].x))
            end

            gSounds['paddle-hit']:play()
        end


    -- detect collision across all bricks with the ball
        for k, brick in pairs(self.bricks) do

        --  if self.powerups['key'].powerupUsed == true then
        --    brick.Locked = false
        --  end

            -- only check collision if we're in play
            if brick.inPlay and self.ball[x]:collides(brick) then
              -- trigger the brick's hit function, which removes it from play
              brick:hit()

              if brick.inPlay == false then

                local randomNumberGen = math.random(1, 5)

                if randomNumberGen == 1 then
                  self.powerups['key'].show = true
                elseif randomNumberGen == 5 then
                  self.powerups['ball'].show = true
                end

                if self.powerups['key'].show == true and self.powerups['key'].shown ~= false then
                    if self.powerups['key'].inPlay == false then
                      self.powerups['key']:spawn(self.ball[x].x, self.ball[x].y)
                      self.powerups['key'].inPlay = true
                    end
    --              self.powerups['key'].shown = true
                end

                if self.powerups['ball'].show == true and self.powerups['ball'].shown ~= false then
                  if self.powerups['ball'].inPlay == false then
                    self.powerups['ball']:spawn(self.ball[x].x, self.ball[x].y)
                    self.powerups['ball'].inPlay = true
                  end

                end
              end


                -- add to score
               if brick.Locked ~= true then
                 self.score = self.score + (brick.tier * 200 + brick.color * 25)
               end



                -- if we have enough points, recover a point of health
                if self.score >= recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    recoverPoints = recoverPoints * 2

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                --Paddle growth at 10,000 paddlePoints

                if self.score >= paddlePoints then

                  self.paddle.size = math.min(4, self.paddle.size + 1)
                  gSounds['paddle_grow']:play()


                  paddlePoints = paddlePoints * 2

                end
                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.ball[x],
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if self.ball[x].x + 2 < brick.x and self.ball[x].dx > 0 then

                    -- flip x velocity and reset position outside of brick
                    self.ball[x].dx = -self.ball[x].dx
                    self.ball[x].x = brick.x - 8

                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
              elseif self.ball[x].x + 6 > brick.x + brick.width and self.ball[x].dx < 0 then

                    -- flip x velocity and reset position outside of brick
                    self.ball[x].dx = -self.ball[x].dx
                    self.ball[x].x = brick.x + 32

                -- top edge if no X collisions, always check
              elseif self.ball[x].y < brick.y then

                    -- flip y velocity and reset position outside of brick
                    self.ball[x].dy = -self.ball[x].dy
                    self.ball[x].y = brick.y - 8

                -- bottom edge if no X collisions or top collision, last possibility
                else

                    -- flip y velocity and reset position outside of brick
                    self.ball[x].dy = -self.ball[x].dy
                    self.ball[x].y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(self.ball[x].dy) < 150 then
                    self.ball[x].dy = self.ball[x].dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end --End of function ballCollision


    if self.powerups['key']:collides(self.paddle) == true then
      self.powerups['key'].powerupUsed = true
      self.powerups['key']:reset()
      gSounds['powerup']:play()

      for k, brick in pairs(self.bricks) do
            brick.Locked = false
      end
    end

    if self.powerups['ball']:collides(self.paddle) == true then
      self.powerups['ball'].powerupUsed = true
      self.powerups['ball']:reset()
      gSounds['powerup']:play()
    end

    if self.powerups['key'].y >= VIRTUAL_HEIGHT then
       self.powerups['key'].powerupUsed = false
       self.powerups['key']:reset()
    end

    if self.powerups['ball'].y >= VIRTUAL_HEIGHT then
      self.powerups['ball'].powerupUsed = false
      self.powerups['ball']:reset()
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    function hurt()
        self.health = self.health - 1

        BALLSSPAWNED = false
        RENDERBALLS = false

        self.paddle.size = math.max(1, self.paddle.size - 1)
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end

    ballCollision(1)

  if self.powerups['ball'].powerupUsed == true then

    RENDERBALLS = true

    if BALLSSPAWNED ~= true then
      self.ball[2].x = self.paddle.x + self.paddle.width / 2 - 8
      self.ball[2].y = self.paddle.y + 1

      self.ball[3].x = self.paddle.x + self.paddle.width / 2 - 8
      self.ball[3].y = self.paddle.y + 1

      self.ball[2].dx = math.random(-200, 200)
      self.ball[2].dy = math.random(50, 100)

      self.ball[3].dx = math.random(-200, 200)
      self.ball[3].dy = math.random(50, 100)

      BALLSSPAWNED = true
    end


    ballCollision(2)
    ballCollision(3)


    if self.ball[1].y >= VIRTUAL_HEIGHT and self.ball[2].y >= VIRTUAL_HEIGHT and self.ball[3].y >= VIRTUAL_HEIGHT then
      hurt()
    end
  else

    if self.ball[1].y >= VIRTUAL_HEIGHT then
      hurt()
    end

  end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    if self.ball[1].y >= VIRTUAL_HEIGHT then
      self.ball[1].y = VIRTUAL_HEIGHT + 10
      self.ball[1].dy = 0
    end

    if self.ball[2].y >= VIRTUAL_HEIGHT then
      self.ball[2].y = VIRTUAL_HEIGHT + 10
      self.ball[2].dy = 0
    end

    if self.ball[3].y >= VIRTUAL_HEIGHT then
      self.ball[3].y = VIRTUAL_HEIGHT + 10
      self.ball[3].dy = 0
    end

end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    if self.powerups['key'].shown == true then
      self.powerups['key']:render()
    end

    if self.powerups['ball'].shown == true then
      self.powerups['ball']:render()
    end
    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    self.ball[1]:render()

    if RENDERBALLS == true then
      self.ball[2]:render()
      self.ball[3]:render()
    end

    renderScore(self.score)
    renderHealth(self.health)
    -- pause text, if paused


    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end

    return true
end
