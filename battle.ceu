local METEOR_MS  = 5000   -- average period to spawn a new meteor
local SHIP_SHOTS = 3      -- maximum number of simultaneous shots

function Move_T (rect, vel)
    --[[
    ;; Updates the given `rect` position according to its `vel` speed.
    ;;  - Updates on every :Frame.
    ;;  - Terminates when leaving the screen.
    ]]
    local function out_of_screen ()
        return (
            rect.x < 0  or
            rect.x > W  or
            rect.y < 0  or
            rect.y > H
        )
    end
    watching(out_of_screen, function ()
        every('step', function (_,ms)
            local dt = ms / 1000
            rect.x = math.floor(rect.x + (vel.x * dt))
            rect.y = math.floor(rect.y + (vel.y * dt))
        end)
    end)
end

require "ts" -- includes the object tasks

local t = {   -- holds all spawned shots, limited to a maximum
    tasks(),  --  - shots for ship in the right
    tasks(),  --  - shots for ship in the right
}

--[[
;; Declares and spawns the game objects:
;;  - Meteors live in a dynamic pool of tasks and are spawned periodically.
;;  - Ships are fixed and held in a tuple pair.
;;  - Shots live in dynamic pools, one for each ship, which are held in a
;;    tuple pair.
;; Pools control the lifecycle of tasks by releasing them from memory
;; automatically on termination. Tasks in pools are anonymous and can only
;; be accessed through iterators or reference tracks.
]]

local meteors <close> = tasks()   -- holds all spawned meteors

-- holds all spawned shots, limited to a maximum
local shots_l <close> = tasks(SHIP_SHOTS)   --  - shots for ship in the left
local shots_r <close> = tasks(SHIP_SHOTS)   --  - shots for ship in the right

local pos = {         -- positions for each ship
    l = PP(10, 50),     -- left  of the screen
    r = PP(90, 50),     -- right of the screen
}
local ctl = {         -- key controls for each ship
    l = {mov={l='A',    r='D',     u='W',  d='S'},    shot='Left Shift'},
    r = {mov={l='Left', r='Right', u='Up', d='Down'}, shot='Right Shift'},
}

local ships = tasks(2)  -- holds the two ships
spawn_in(ships, Ship, 'Ship.L', pos.l, ctl.l, shots_l, "imgs/ship-L.gif")
spawn_in(ships, Ship, 'Ship.R', pos.r, ctl.r, shots_r, "imgs/ship-R.gif")

local _, ship = watching(ships, function ()
    -- GAMEPLAY
    --[[
    ;; Runs the gameplay until one of the two ships is destroyed:
    ;;  - Spawns new meteors periodically.
    ;;  - Checks collisions between all objects.
    ]]
    par(function ()                   -- METEORS
        --[[
        ;; Spawns new meteros in the game every period:
        ;;  - Hold them in the outer pool.
        ;;  - Gradually decreases the spawning period.
        ]]
        local period = METEOR_MS
        while true do
            local dt = math.random(1, period)
            await(clock{ms=dt})
            spawn_in(meteors, Meteor)
        end
    end, function ()
        every('step', function () -- COLLISIONS
            --[[
            ;; Checks collisions between objects:
            ;;  1. Uses `to.vector` to collect all references to dinamically
            ;;     allocated ships, shots, and meteors.
            ;;  2. Uses `pico-collisions` to get all pairs of colliding
            ;;     objects, using the `f-cmp` comparator which relies on `:T`
            ;;     rect.
            ;;  3. Iterates over the pairs, ignores innocuous collisions, and
            ;;     collects final colliding objects.
            ;;  4. Signals colliding objects.
            ;; A ship collision will eventually terminate the enclosing
            ;; `watching`, also terminating the current battle.
            ]]

            local tsks = {}    -- (1)
            for _, t in pairs(ships) do
                tsks[#tsks+1] = t
            end
            for _, t in pairs(shots_l) do
                tsks[#tsks+1] = t
            end
            for _, t in pairs(shots_r) do
                tsks[#tsks+1] = t
            end
            for _, t in pairs(meteors) do
                tsks[#tsks+1] = t
            end

            local cols = {}     -- (2)
            for i=1, #tsks do
                for j=i+1, #tsks do
                    local t1 = tsks[i]
                    local t2 = tsks[j]
                    local no = (
                        (t1.tag=='Ship.R' and t2.tag=='Shot.R') or
                        (t1.tag=='Shot.R' and t2.tag=='Ship.R') or
                        (t1.tag=='Ship.L' and t2.tag=='Shot.L') or
                        (t1.tag=='Shot.L' and t2.tag=='Ship.L') or
                        (t1.tag=='Meteor' and t2.tag=='Meteor')
                    )
                    if (not no) and rect_vs_rect(t1.rect, t2.rect) then
                        emit_in(t1, 'collided')
                        emit_in(t2, 'collided')
                    end
                end
            end
        end)
    end)
end)

-- BATTLE RESULT
return ship.tag
