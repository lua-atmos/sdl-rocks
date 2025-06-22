local SHIP_FRAMES   = 4
local SHIP_ACC_DIV  = 10
local SHIP_VEL_MAX  = { x=W/2.5, y=H/2.5 }
local SHOT_DIM      = { w=math.floor(W/50), h=math.floor(H/100) }
local SHOT_COLOR    = 0xFFFF88
local METEOR_FRAMES = 6
local METEOR_AWAIT  = 5000

function random_signal ()
    return ((math.random(0,1)==1) and 1) or -1
end

function Meteor ()
    local sfc = assert(IMG.load("imgs/meteor.gif"))
    local tex = assert(REN:createTextureFromSurface(sfc))
    local ww,h = sfc:getSize()

    local y_sig = random_signal()

    local vx = (1 + (math.random(0,W/5))) * random_signal()
    local vy = (1 + (math.random(0,H/5))) * y_sig

    local w = ww / METEOR_FRAMES
    local dx = 0

    local x = math.random(0,W)
    local y = (y_sig == 1) and 0 or H
    local rect = { x=x, y=y, w=w, h=h }
    me().rect = rect

    par_or(function ()
        local dt = math.random(1, METEOR_AWAIT)
        await(clock{ms=dt})
        par_or(function ()
            await(spawn (Move_T, rect, {x=vx,y=vy}))
        end, function ()
            await('collided')
            --pico.output.sound("snds/meteor.wav")
        end)
    end, function ()
        every('sdl.draw', function ()
            local crop = { x=dx, y=0, w=w, h=h }
            REN:copy(tex, crop, rect)
        end)
    end, function ()
        local v = ((vx^2) + (vy^2)) ^ (1/2)
        local x = 0
        every('step', function (_,ms)
            x = x + ((v * ms) / 1000)
            dx = (x % ww) - (x % w)
        end)
    end)
    --pub
end

function Shot (tag, pos, vy)
    --pico.output.sound("snds/shot.wav")
    local rect = { x=pos.x, y=pos.y, w=SHOT_DIM.w, h=SHOT_DIM.h }
    me().tag = tag
    me().rect = rect
    par_or(function ()
        await('collided')
    end, function ()
        -- TODO: move out
        local sig = (tag=='Shot.L' and 1) or -1
        await(spawn (Move_T, rect, {x=(W/3)*sig, y=vy}))
    end, function ()
        every('sdl.draw', function ()
            REN:setDrawColor(SHOT_COLOR)
            REN:fillRect(rect)
        end)
    end)
    --pub
end

function Ship (tag, pos, ctl, shots, path)
    local sfc = assert(IMG.load(path))
    local tex = assert(REN:createTextureFromSurface(sfc))
    local w,h = sfc:getSize()
    local vel = {x=0,y=0}
    local dy = h / SHIP_FRAMES
    local rect = { x=pos.x, y=pos.y, w=w, h=dy }
    me().tag = tag
    me().rect = rect

    local acc = {x=0,y=0}
    local key
    spawn(function ()
        par(function ()
            every(SDL.event.KeyDown, function (evt)
                if false then
                elseif evt.name == ctl.mov.l then
                    acc.x = -W/SHIP_ACC_DIV
                elseif evt.name == ctl.mov.r then
                    acc.x =  W/SHIP_ACC_DIV
                elseif evt.name == ctl.mov.u then
                    acc.y = -H/SHIP_ACC_DIV
                elseif evt.name == ctl.mov.d then
                    acc.y =  H/SHIP_ACC_DIV
                elseif evt.name == ctl.shot then
                    -- TODO: move out
                    local tpx = ((tag == 'Ship.L') and 'Shot.L') or 'Shot.R'
                    spawn_in(shots, Shot, tpx, {x=rect.x,y=rect.y}, vel.y)
                end
                key = evt
            end)
        end, function ()
            every(SDL.event.KeyUp, function ()
                key = nil
                acc = {x=0,y=0}
            end)
        end)
    end)

    watching('collided', function ()
        par(function ()
            every('sdl.draw', function ()
                local frame = 0; do
                    if false then
                    elseif key == ctl.mov.left then
                        frame = ((tag=='Ship.L') and 0) or 1
                    elseif key == ctl.mov.right then
                        frame = ((tag=='Ship.R') and 0) or 1
                    elseif key == ctl.mov.up then
                        frame = 2
                    elseif key == ctl.mov.down then
                        frame = 3
                    end
                end
                local crop = { x=0, y=frame*dy, w=rect.w, h=dy }
                REN:copy(tex, crop, rect)
            end)
        end, function ()
            every('step', function (_,ms)
                local dt = ms / 1000
                vel.x = between(-SHIP_VEL_MAX.x, vel.x+(acc.x*dt), SHIP_VEL_MAX.x)
                vel.y = between(-SHIP_VEL_MAX.y, vel.y+(acc.y*dt), SHIP_VEL_MAX.y)

                -- TODO: lims out
                local x = rect.x + (vel.x*dt)
                local y = rect.y + (vel.y*dt)
                if tag == 'Ship.L' then
                    rect.x = math.floor(between(0, x, W/2))
                else
                    rect.x = math.floor(between(W/2, x, W))
                end
                rect.y = math.floor(between(0, y, H))
            end)
        end)
    end)

    --pico.output.sound("snds/explosion.wav")
    watching(clock{ms=150}, function ()
        local d = dy / 2;
        par(function ()
            every('step', function (_,ms)
                d = d + (((40*d)*ms)/1000)
            end)
        end, function ()
            every('sdl.draw', function ()
                REN:setDrawColor(0xFF0000)
                REN:fillRect { x=rect.x, y=rect.y, w=d, h=d }
            end)
        end)
    end)
end
