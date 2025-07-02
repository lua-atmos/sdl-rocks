local SHIP_FRAMES   = 4
local SHIP_ACC_DIV  = 10
local SHIP_VEL_MAX  = { x=W/2.5, y=H/2.5 }
local SHOT_DIM      = { w=math.floor(W/50), h=math.floor(H/100) }
local SHOT_COLOR    = 0xFFFF88
local METEOR_FRAMES = 6
local METEOR_AWAIT  = 5000

function between (min, v, max)
    if v < min then
        return min
    elseif v > max then
        return max
    else
        return v
    end
end

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
    me().tag  = 'M'
    me().rect = rect

    par_or(function ()
        local dt = math.random(1, METEOR_AWAIT)
        await(clock{ms=dt})
        par_or(function ()
            await(spawn (Move_T, rect, {x=vx,y=vy}))
        end, function ()
            await('collided')
            sdl.play "snds/meteor.wav"
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

function Shot (V, pos, vy)
    sdl.play "snds/shot.wav"
    local rect = { x=pos.x, y=pos.y-SHOT_DIM.h/2, w=SHOT_DIM.w, h=SHOT_DIM.h }
    me().tag = V.tag
    me().rect = rect
    par_or(function ()
        await('collided')
    end, function ()
        await(spawn (Move_T, rect, {x=(W/3)*V.x, y=vy}))
    end, function ()
        every('sdl.draw', function ()
            REN:setDrawColor(SHOT_COLOR)
            REN:fillRect(rect)
        end)
    end)
    --pub
end

function Ship (V, shots, path)
    local sfc = assert(IMG.load(path))
    local tex = assert(REN:createTextureFromSurface(sfc))
    local w,h = sfc:getSize()
    local vel = {x=0,y=0}
    local dy = h / SHIP_FRAMES
    local rect = { x=V.pos.x-w/2, y=V.pos.y-dy/2, w=w, h=dy }
    me().tag = V.tag
    me().rect = rect

    local acc = {x=0,y=0}
    local key
    spawn(function ()
        par(function ()
            every(SDL.event.KeyDown, function (evt)
                if false then
                elseif evt.name == V.ctl.move.l then
                    acc.x = -W/SHIP_ACC_DIV
                elseif evt.name == V.ctl.move.r then
                    acc.x =  W/SHIP_ACC_DIV
                elseif evt.name == V.ctl.move.u then
                    acc.y = -H/SHIP_ACC_DIV
                elseif evt.name == V.ctl.move.d then
                    acc.y =  H/SHIP_ACC_DIV
                elseif evt.name == V.ctl.shot then
                    spawn_in(shots, Shot, V.shot, {x=rect.x+rect.w/2,y=rect.y+rect.h/2}, vel.y)
                end
                key = evt.name
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
                    elseif key == V.ctl.move.l then
                        frame = V.ctl.frame.l
                    elseif key == V.ctl.move.r then
                        frame = V.ctl.frame.r
                    elseif key == V.ctl.move.u then
                        frame = V.ctl.frame.u
                    elseif key == V.ctl.move.d then
                        frame = V.ctl.frame.d
                    end
                end
                local crop = { x=0, y=frame*dy, w=rect.w, h=dy }
                REN:copy(tex, crop, rect)
            end)
        end, function ()
            V.lim.x2 = V.lim.x2 - w
            every('step', function (_,ms)
                local dt = ms / 1000
                vel.x = between(-SHIP_VEL_MAX.x, vel.x+(acc.x*dt), SHIP_VEL_MAX.x)
                vel.y = between(-SHIP_VEL_MAX.y, vel.y+(acc.y*dt), SHIP_VEL_MAX.y)

                local x = math.floor(rect.x + (vel.x*dt))
                local y = math.floor(rect.y + (vel.y*dt))
                rect.x = math.floor(between(V.lim.x1, x, V.lim.x2))
                rect.y = math.floor(between(0, y, H-dy))
            end)
        end)
    end)

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
