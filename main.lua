require 'vector'
require 'ball'
require 'paddle'

function initResources()
    font16 = love.graphics.newFont('resources/AtariClassic-Regular.ttf', 16)
    font32 = love.graphics.newFont('resources/AtariClassic-Regular.ttf', 32)
    font64 = love.graphics.newFont('resources/AtariClassic-Regular.ttf', 64)

    sounds = {
        ['hit'] = love.audio.newSource('resources/pong.wav', 'static'),
        ['victory'] = love.audio.newSource('resources/victory.wav', 'static'),
        ['gameover'] = love.audio.newSource('resources/gameover.wav', 'static')
    }

end

function love.load()
    gameState = 'start'

    width = love.graphics.getWidth()
    height = love.graphics.getHeight()

    ball = Ball:create(Vector:create(width / 2, height / 2), 10)

    player = Paddle:create(Vector:create(50, height / 2 - 45), 90, 20, 500)
    playerBot = Paddle:create(Vector:create(width - 50 - 10, height / 2 - 45), 90, 20, 500)

    initResources()

    playerScore = 0
    playerBotScore = 0

    finalScope = 8

    pitcherPlayer = 1
    winningPlayer = 0

    speedIncrease = 0.05

    maxBounceAngle = 60 * math.pi / 180

    ballSpeed = 4
    curSpeed = updateCurSpeed()
end

function updateCurSpeed()
    return ballSpeed + 0.1 * ballSpeed * (playerScore + playerBotScore)
end

function love.update(dt)
    if ball:paddle_hit(player) then
        ball.pos.x = player.pos.x + player.width + ball.radius
        local relIntersectY = player.pos.y + player.height / 2 - ball.pos.y
        relIntersectY = relIntersectY / (player.height / 2)

        updateBallPos('plus', relIntersectY)
    end

    if ball:paddle_hit(playerBot) then
        local relIntersectY = playerBot.pos.y + playerBot.height / 2 - ball.pos.y
        relIntersectY = relIntersectY / (playerBot.height / 2)

        updateBallPos('minus', relIntersectY)
    end

    checkBallGoal()

    playerMove(dt)
    playerBotMove(dt)

    ball:update(dt)
end

function checkBallGoal()
    if ball.pos.x < 0 then
        curSpeed = updateCurSpeed()
        ball:reset()
        pitcherPlayer = 1
        playerBotScore = playerBotScore + 1

        if playerBotScore > finalScope then
            gameState = 'done'
            winningPlayer = 2
            sounds['gameover']:play()
        else
            play()
        end
    end

    if ball.pos.x > width then
        curSpeed = updateCurSpeed()
        ball:reset()
        pitcherPlayer = 2
        playerScore = playerScore + 1

        if playerScore > finalScope then
            gameState = 'done'
            winningPlayer = 1
            sounds['victory']:play()
        else
            play()
        end
    end
end

function play()
    bounceAngle = math.random(-100, 100) / 100 * maxBounceAngle

    ballVX = curSpeed * math.cos(bounceAngle)
    ballVY = curSpeed * -math.sin(bounceAngle)

    if pitcherPlayer == 1 then
        ball:applyForce(Vector:create(ballVX, ballVY))
    else
        ball:applyForce(Vector:create(-ballVX, ballVY))
    end
end

function updateBallPos(move, relIntersectY)
    bounceAngle = relIntersectY * maxBounceAngle

    local ballVX = curSpeed * math.cos(bounceAngle)
    local ballVY = curSpeed * -math.sin(bounceAngle)

    ball.velocity = Vector:create(0, 0)

    if move == 'minus' then
        ball:applyForce(Vector:create(-ballVX, ballVY))
    elseif move == 'plus' then
        ball:applyForce(Vector:create(ballVX, ballVY))
    end

    sounds['hit']:play()
end

function playerMove(dt)
    if love.keyboard.isDown('w') then
        player:move('up', dt)
    elseif love.keyboard.isDown('s') then
        player:move('down', dt)
    end

end

function playerBotMove(dt)
    if ball.velocity.x > 0 and ball.pos.x > width / 3 then
        diff = math.abs((playerBot.pos.y + playerBot.height / 2) - ball.pos.y) / (playerBot.height)
        diff = math.min(diff, 1)
        if ball.pos.y > playerBot.pos.y + playerBot.height / 2 then
            playerBot:move('down', dt * diff)
        elseif ball.pos.y < playerBot.pos.y + playerBot.height / 2 then
            playerBot:move("up", dt * diff)
        end
    end
end

function startText()
    love.graphics.setFont(font16)
    love.graphics.printf('Welcome', 0, 10, width, 'center')
    love.graphics.printf('Press Enter to begin', 0, 30, width, 'center')
end

function doneText()
    love.graphics.setFont(font32)
    love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!', 0, 10, width, 'center')

    love.graphics.setFont(font16)
    love.graphics.printf('Press Enter to restart!', 0, 50, width, 'center')
end

function scopeText()
    love.graphics.setFont(font64)

    love.graphics.print(tostring(playerScore), width / 2 - 100, height / 5)
    love.graphics.print(tostring(playerBotScore), width / 2 + 30, height / 5)
end

function love.draw()
    ball:draw()
    player:draw()
    playerBot:draw()

    if gameState == 'start' then
        startText()
    elseif gameState == 'done' then
        doneText()
    end

    scopeText()

end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'play'
            play()
        elseif gameState == 'done' then
            gameState = 'start'
            ball:reset()
            pitcherPlayer = 1
            playerScore = 0
            playerBotScore = 0
            curSpeed = ballSpeed
        end
    end
end
