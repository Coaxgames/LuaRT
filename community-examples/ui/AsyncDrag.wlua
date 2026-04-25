/*
## ** Async Drag Example **
 Ever annoyed about your app freezing when dragging the UI around, Avoiding a painfull flashbang when moving ui's around with dark mode?

# WELL i have just the spitefull solution for you, this example displays;
 ~A Small foundation for a TopBar replacment, Allowing for a sleeker looking borderless(mostly) window
 ~The new TaskFactory system, an awesome solution so tasks randomly stopping after some time!
 ~Async Tasks WHILE dragging a UI around, and customizable Drag logic
 ~OnHover animation with predefined colors
Made by Xaon420
*/


local ui = require("ui")

local colors = {--predefined colors for switching/preloading a color
  TopBarColor = 0x070707,
  ButtonColor = 0x060606,
  ButtonHover = 0xbebebe,
}


--## UI Defines
local win = ui.Window("Window.startmoving() example", "raw", 320, 200)
win.bgcolor = 0xffffff

--Top Bar that will hold our icons
local TopBar = ui.Panel(win)
TopBar.height = 16
TopBar.bgcolor = colors.TopBarColor
TopBar.obgcolor = TopBar.bgcolor
TopBar.align = "top"

--close label (use a png for no backround)
local CloseLB = ui.Label(TopBar, "X", 5, math.floor((TopBar.height / 5))-2)
CloseLB.bgcolor = colors.ButtonColor
CloseLB.obgcolor = CloseLB.bgcolor
CloseLB.textalign = "left"

--move label (use a png for no backround)
local MoveLB = ui.Label(TopBar, "#", (CloseLB.width * 2)+1, math.floor((TopBar.height / 5))-2)
MoveLB.bgcolor = colors.ButtonColor
MoveLB.obgcolor = MoveLB.bgcolor
MoveLB.textalign = "left"




--## ui IsHovering function (Detects if mouse is overtop of an element, provided an element to check)
function IsHovering(Button)
  local mx, my = ui.mousepos()
  local Bounds = { --define bounds here, or offsets. much easier to read
    x1 = win.x+(Button.x), x2 = win.x+(Button.x + Button.width), 
    y1= win.y+(Button.y), y2 = win.y+(Button.y + Button.height)
  }

  --print(mx,my, win.x,win.y, Button.x, Button.y,"\n",Bounds)
  if mx > Bounds.x1 and mx < Bounds.x2 and
    my > Bounds.y1 and my < Bounds.y2 then
    return true
  else
    return false
  end
end



--## Task example + UI drag task
--a task to handle moving the window, using tasks rather than win11 message loop
local MovUI, IsDrag = sys.Task(function (Button, buttons)
  while true do
    if not IsHovering(Button) then--may switch this to only the main window
      x, y = ui.mousepos()
      ui.update()
      win.x = (x) - (Button.x+2) --this adjusts the grab location to where the label exists
      win.y = (y) - (Button.y+5) --offset for buttons and topbar's size
    end
    sleep(3)
  end
end), false

--an example task that runs in the backround while dragging (also printing a bit slower for readability)
local BackroundTask = sys.Task(function ()
  while true do
    --print("RUNNING")
    x, y = ui.mousepos()
    win:status(win.x, win.y, "MOUSE: ", x,y)
    sleep(16)
  end
end)
  


--## OnHover redirect for any dragging and animation (the main sauce)
function OnHov(Button, x, y, buttons, Animate)
  --just for driving the onHover Color. it is better to do it in the main event but this redirect helps make things more compact
  if Animate==true then --Must have a boolean on Arg 5 to animate!
    if buttons.left == false then --added to help with flashing, since we MAY still be overtop of the move Element
      if IsHovering(Button) then
        Button.bgcolor = colors.ButtonHover
        async(function()
          while true do
            sleep(16) --delay roughly 60 frames
            if IsHovering(Button) == false then
              Button.bgcolor = Button.obgcolor
              return
            end
          end
        end)
      end
    end
  end
  
  --Drag Start/Release/Click detection
  if (Button == MoveLB) and (buttons.left == false and IsDrag) then --ill need to debug this more, it sems like it not needed but removing it does change dragging a bit
    --this also catches the edge case; OnMouseUp is buggy when NOT hovering within the main UI. SO when the Pos updates we want the events to make sure we let go
    IsDrag = false
    MovUI:pause()
  elseif (Button == MoveLB) and (buttons.left == true and IsDrag == false) then--disabled; causes re-grabbing when hovering over another element (or forces a drop when grabbing)
    --IsDrag = true
    --MovUI(MoveLB, {left = true})
  end
end





--## Hover events, if hovering on another element then another may be ignored
function MoveLB:onHover(x, y, buttons) --required, updates Drag task status and catches edge cases in the ui hover system
  OnHov(MoveLB, x, y, buttons, true)
end
function TopBar:onHover(x, y, buttons) --required, updates Drag task status and catches edge cases in the ui hover system
  OnHov(MoveLB, x, y, buttons, true)
end
function MoveLB:onMouseUp(b, x, y) --Added in preferance from OnHover and OnLeave with button checks
  IsDrag = false
  MovUI:pause()
end
function MoveLB:onMouseDown(b, x, y) --added to catch when the user (KINDA) leaves the main window
  IsDrag = true
  MovUI(MoveLB, {left = true})
end
function win:onMouseUp(b, x, y) --added to catch when the user (KINDA) leaves the main window while still dragging (high dpi issue)
  IsDrag = false
  MovUI:pause()
end


--## Click events
function CloseLB:onClick()--Close button (for program exit)
  IsDrag = false --force drag off
  win:hide()
  await(function()
    MovUI:pause() --pause here, just incase we want to restart the UI from the main app
    sleep(1000) --gives time for backround task to stop, or main lua script to shutdown correctly for logging and such
  end)
end



--run the backround task (You can also use async, task allows for more control without the new extentions)
BackroundTask()

--begin the UI, and await its termination
await(win:showasync())
