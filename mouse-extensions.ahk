#Include <keyboard>
#Include <functions>
#Include <monitor>
#Include <window>
#Include <Gdip_All>

; Avoid leaving the user trapped with a clipped cursor when this script exits unexpectedly
OnExit((*) => (Mouse.ClipCursor.ConfineToArea(0), 0))    ; ensures the cursor has full control when the script exits


Mouse.Layer := Class('Layer')
Mouse.Gesture := Class('Gesture')
Mouse.ClipCursor := Class('ClipCursor')
Mouse.Capture := __CaptureMouse
Mouse.Jump := __Jump


Mouse.MoveToMonitorCenter := (this, winTitle?, winText?, excludeTitle?, excludeText?) {
    mon := Monitor(Monitor.FromWindow(winTitle?, winText?, excludeTitle?, excludeText?))
    DllCall('SetCursorPos', 'Int', mon.centerX, 'Int', mon.centerY)
    return this
}

Mouse.MoveToCenterOfWindow := (this, winTitle?, winText?, excludeTitle?, excludeText?) {
    win := Window(winTitle?, winText?, excludeTitle?, excludeText?)
    win.GetCenterPos(&x, &y)
    try DllCall('SetCursorPos', 'Int', x, 'Int', y)
    return this
}

Mouse.MoveWithAccel := (this, speed := 1, up := 'e', down := 'd', left := 's', right := 'f') {
    static accel := speed                           ; initialize acceleration

    if accel > speed                                ; if already running (without this it would reset accel the first time a new direction is used)
        return                                      ; return

    maxSpeed := 40 * speed                          ; max speed reached by acceleration
    base := 3                                       ; increase this value to make acceleration slower, vice versa

    loop {
        if Mod(A_Index, base) = 0 {                 ; every x loops, increase speed of mousemovement
            accel := Min(accel+1, maxSpeed)         ; increase speed by one unless at maxSpeed
        }

        MouseMove(x := GetKeyState(left, 'P') ? -accel : GetKeyState(right, 'P') ? accel : 0,               ; if mouse is moved left, else if mouse is moved right, else don't move horizontally
                  y := GetKeyState(up,   'P') ? -accel : GetKeyState(down,  'P') ? accel : 0,, 'Relative')  ; if mouse is moved up, else if mouse is moved down, else don't move vertically

        Sleep(1)

    } until !x and !y and A_TimeIdleKeyboard > 50   ; buffer when switching directions so it doesn't immediately lose acceleration

    accel := speed                                  ; reset
}

; static accel := 1
; static accel_index := 1
; static decelerate := ObjBindMethod(this, 'DecreaseAccel')

; static MoveUp(speed := 1) {
;     this.MoveWithAccel(speed)
;     ; MouseMove()
; }

; static MoveDown() {

; }

; static MoveLeft() {

; }

; static MoveRight() {

; }

; static MoveWithAccel(speed)
; {
;     maxSpeed := 40 * speed                      ; max speed reached by acceleration

;     ; if not this.accel > speed
;         this.IncreaseAccel(maxSpeed)


;     MouseMove(x := GetKeyState(this.left, 'P') ? -accel : GetKeyState(this.right, 'P') ? accel : 0,               ; if mouse is moved left, else if mouse is moved right, else don't move horizontally
;               y := GetKeyState(this.up,   'P') ? -accel : GetKeyState(this.down,  'P') ? accel : 0,, 'Relative')  ; if mouse is moved up, else if mouse is moved down, else don't move vertically


;     Sleep(1)
;     SetTimer(this.decelerate, 100)      ; may want another timer for delay, look at notification class for how I did that
; }


Mouse.IncreaseAccel := (this, maxSpeed) {
    static base := 3                                ; increase this value to make acceleration slower, vice versa
    if Mod(this.accel_index, 3) = 0 {               ; every 3 iterations, increase accel
        this.accel := Min(this.accel+1, maxSpeed)   ; increase accel by one unless it's at maxSpeed
        this.accel_index++                          ; increase index
    }
}

Mouse.DecreaseAccel := (this) {
    if this.accel {
        this.accel--                                ; decrease speed
        this.accel_index--                          ; decrease index
    }
    else {
        SetTimer(this.decelerate, 0)
        this.accel_index := 1
    }
}


Mouse.MoveWithAccel2 := (this, speed := 1) {
    static accel := 4                           ; initialize acceleration

    if accel > 4                                ; if already running
        return                                  ; return

    maxSpeed := 40 * speed                      ; max speed reached by acceleration

    loop {
        if A_Index > 40 {
            accel := Min(accel+speed, maxSpeed) ; increase acceleration by base value
        }

        MouseMove(x := GetKeyState(this.left, 'P') ? -accel : GetKeyState(this.right, 'P') ? accel : 0,               ; if mouse is moved left, else if mouse is moved right, else don't move horizontally
                    y := GetKeyState(this.up,   'P') ? -accel : GetKeyState(this.down,  'P') ? accel : 0,, 'Relative')  ; if mouse is moved up, else if mouse is moved down, else don't move vertically

        Sleep(1)

    } until !x and !y

    accel := 4
}


Mouse.MoveWithAccel3 := (this, speed := 1) {
    static accel := 0                           ; initialize acceleration
    static base := 200                          ; random through testing

    if accel                                    ; if already running
        return                                  ; return

    maxSpeed := 40 * speed                      ; max speed reached by acceleration
    step := base                                ; initialize step start

    loop {
        if step > 20 {
            accel := (base/step * 4)
            step -= 2
        }

        MouseMove(x := GetKeyState(this.left, 'P') ? -accel : GetKeyState(this.right, 'P') ? accel : 0,               ; if mouse is moved left, else if mouse is moved right, else don't move horizontally
                    y := GetKeyState(this.up,   'P') ? -accel : GetKeyState(this.down,  'P') ? accel : 0,, 'Relative')  ; if mouse is moved up, else if mouse is moved down, else don't move vertically

        Sleep(1)

    } until !x and !y

    accel := 0
}


/**
 * @class scrollwheel
 * Should this be a class?
 */

Mouse.ScrollAccel := (this, accel := 1) {
    static hotkey := StripHotkey()              ; keep track of direction
    scroll := 1                                 ; starting line scroll value

    if hotkey != StripHotkey() {                ; if different direction
        hotkey := StripHotkey()                 ; remember new direction
        SetTimer(Acceleration, 0)               ; stop acceleration
    }


    SetTimer(Acceleration, 200)                 ; start acceleration

    while GetKeyState(hotkey, 'P') {            ; while still going the same direction
        ; MouseClick(direction,,, scroll)         ; scroll
        Sleep(scroll = 1 ? 300 : 100)           ; but not too fast :)
    }

    SetTimer(Acceleration, 0)                   ; stop acceleration
    Acceleration() => scroll += accel           ; increase acceleration by base value
}


Mouse.ClipCursor.DefineProp('isConfined', {Get: (this) => this.GetConfinedArea()})

/**
 * @param {integer} @left   how far left  the mouse can move
 * @param {integer} @top    how far up    the mouse can move
 * @param {integer} @right  how far right the mouse can move
 * @param {integer} @bottom how far down  the mouse can move
 */
Mouse.ClipCursor.ConfineToArea := (this, confine := true, left := 0, top := 0, right := 1, bottom := 1) {
    static rect := Buffer(16)

    ; certain parameters, like confining the cursor to just one axis,
    ; prevent a new confined area from being specified until clipcursor is called with null
    DllCall('ClipCursor', 'Ptr', 0)

    if confine {
        NumPut('Int', left, 'Int', top, 'Int', right, 'Int', bottom, rect)
        return DllCall('ClipCursor', 'Ptr', rect)
    }

    return DllCall('ClipCursor', 'Ptr', 0)
}


/**
 * @returns true or 1 if cursor is confined to anything besides the virtual screen
 */
Mouse.ClipCursor.GetConfinedArea := (this) {
    static rect := Buffer(16)                               ; rect struct to store screen coordinates
    DllCall('GetClipCursor', 'Ptr', rect)                   ; get coordinates of mouse confined area

    x := y := r := b := 0                                   ; initialize variables

    loop MonitorGetCount() {                                ; loop through monitors
        MonitorGet(A_Index, &left, &top, &right, &bottom)   ; get current monitor coords
        (left   <   x   ?   x := left    : 0)               ; save furthest left coord
        (top    <   y   ?   y := top     : 0)               ; save furthest top coord
        (right  >   r   ?   r := right   : 0)               ; save furthest right coord
        (bottom >   b   ?   b := bottom  : 0)               ; save furthest bottom coord
    }


    if !(x = NumGet(rect,  0, 'Int')                        ; compares saved coords vs the bounding box of the mouse cursor confined area
        && y = NumGet(rect,  4, 'Int')
        && r = NumGet(rect,  8, 'Int')
        && b = NumGet(rect, 12, 'Int')) {
            return true                                     ; returns true if they don't all match
    }

    return false
}

Mouse.ClipCursor.ConfineToMonitor := (this, mon) =>
    this.ConfineToArea(true, Monitor(mon).left, Monitor.top, Monitor.right, Monitor.bottom)

Mouse.ClipCursor.ConfineToMonitorMouseIsOn := (this) =>
    this.ConfineToArea(true, Monitor(Monitor.mouseIsOn).left, Monitor.top, Monitor.right, Monitor.bottom)

Mouse.ClipCursor.ConfineToMonitorWindowIsOn := (this, winTitle?, winText?, excludeTitle?, excludeText?) =>
    this.ConfineToArea(true, Monitor(Monitor.FromWindow(winTitle?, winText?, excludeTitle?, excludeText?)).left, Monitor.top, Monitor.right, Monitor.bottom)

Mouse.ClipCursor.ConfineXAxisToMonitorMouseIsOn := (this) =>
    this.ConfineToArea(true, Monitor(Monitor.mouseIsOn).left, Mouse.y, Monitor.right, Mouse.y)

Mouse.ClipCursor.ConfineYAxisToMonitorMouseIsOn := (this) =>
    this.ConfineToArea(true, Mouse.x, Monitor(Monitor.mouseIsOn).top, Mouse.x, Monitor.bottom)

Mouse.ClipCursor.ConfineXAxisAcrossVirtualScreen := (this) =>
    this.ConfineToArea(true, VirtualScreen.left, Mouse.y, VirtualScreen.right, Mouse.y)

Mouse.ClipCursor.ConfineYAxisAcrossVirtualScreen := (this) =>
    this.ConfineToArea(true, Mouse.x, VirtualScreen.top, Mouse.x, VirtualScreen.bottom)

Mouse.ClipCursor.ConfineToWindow := (this, id := 'A') {
    win := Window(id)
    this.ConfineToArea(true, win.left, win.top, win.right, win.bottom)
}

Mouse.ClipCursor.ConfineToWindowMouseIsOn := (this) {
    win := Window(Window.underMouse)
    this.ConfineToArea(true, win.left, win.top, win.right, win.bottom)
}


/**
 * @class mouse gestures
 */

/**
 * @param {int} @x_distance_required_to_move
 * @param {int} @y_distance_required_to_move
 * @param {func} UpCallback callback function/method if x or y distance required to trigger is met
 * @param {func} DownCallback callback function/method if x or y distance required to trigger is met
 * @param {func} LeftCallback callback function/method if x or y distance required to trigger is met
 * @param {func} RightCallback callback function/method if x or y distance required to trigger is met
 * @returns {bool} used if you want to do something if the gesture fails or succeeds
 */
Mouse.Gesture.DirectionalDrag := (this, xDistance, yDistance, UpCallback?, DownCallback?, LeftCallback?, RightCallback?) {
    MouseGetPos(&initial_xPos, &initial_yPos)               ; get mouse position

    KeyWait(StripHotkey())                                  ; wait for key to be released

    if Window.mouseGestureUsed {                            ; if another method using this key is called
        return Window.mouseGestureUsed := false             ; exit
    }

    MouseGetPos(&final_xPos, &final_yPos)                   ; get new position of mouse after letting go

    ; evaluate mouse distance moved
    x_distance_moved := Abs(final_xPos - initial_xPos) > xDistance
    y_distance_moved := Abs(final_yPos - initial_yPos) > yDistance

    return CheckIfMouseMovedRequiredDistance()              ; check if mouse moved enough distance

    CheckIfMouseMovedRequiredDistance() {
        switch {
        ; mouse moved right enough distance
        case final_xPos > initial_xPos and x_distance_moved and !y_distance_moved:
            (RightCallback?)()

        ; mouse moved left enough distance
        case final_xPos < initial_xPos and x_distance_moved and !y_distance_moved:
            (LeftCallback?)()

        ; mouse moved up enough distance
        case final_yPos < initial_yPos and y_distance_moved and !x_distance_moved:
            (UpCallback?)()

        ; mouse moved down enough distance
        case final_yPos > initial_yPos and y_distance_moved and !x_distance_moved:
            (DownCallback?)()

        default: return false
        }

        return true
    }
}


/**
 * @returns {void}
 */
Mouse.Gesture.HoldKeyToDragWindow := (this) {
    MouseGetPos(&initial_xPos, &initial_yPos, &window_under_mouse)
    if Window.IsException(window_under_mouse)
    || Window.IsFullscreen(window_under_mouse) {
        return
    }
    WinActivate(window_under_mouse)
    hotkey := StripHotkey()

    UpdateWindow(initial_xPos, initial_yPos)
    UpdateWindow(initial_xPos, initial_yPos) {
        MouseGetPos(&mouse_xPos, &mouse_yPos)                                       ; update mouse position
        xDistance_moved := mouse_xPos - initial_xPos                                ; x distance mouse has moved
        yDistance_moved := mouse_yPos - initial_yPos                                ; y distance mouse has moved

        WinGetPos(&winX, &winY,,, window_under_mouse)                               ; get window position
        WinMove(winX+xDistance_moved, winY+yDistance_moved,,, window_under_mouse)   ; move window to new position
        SetTimer(UpdateWindow.Bind(mouse_xPos, mouse_yPos), -10 * GetKeyState(hotkey, 'P'))
    }
}


; adjust this value to determine how many pixels you have to move the mouse before it cycles apps
Mouse.Gesture.HoldKeyAndDragToSwitchWindows := (this, initial_xPos := 1, startTime := A_TickCount, amount_of_required_pixels_to_move := 200, hotkey := StripHotkey()) {
    ; guard clause to check if button is being held
    if not GetKeyState(hotkey, 'P') {
        __AbortAltTabSwitching(altTabActivated)
        return
    }

    static altTabActivated := false


    try {
        MouseGetPos(&updated_xPos)                                                              ; update mouse position
        timeElapsed := A_TickCount - startTime                                                  ; update time since button was held
        distanceMoved := Abs((updated_xPos - initial_xPos) / amount_of_required_pixels_to_move) ; calculate distance mouse has moved

        ; if mouse isn't moved far enough to change app for 2 seconds, reset starting position
        ; this is to make swiping feel natural after slowing down movement
        ; the slowing down creates a resting place in your mind like you're starting over
        if timeElapsed >= 2000 { ; timeout
            __ResetXPositionAndStartingTime()
        }

        ; if mouse is moved the amount_of_required_pixels_to_move
        else if distanceMoved >= 1 {
            Mouse.Cursor.Visibility('Hide')

            if updated_xPos > initial_xPos {                    ; if mouse is moved to the right
                Send('{Alt Down}{Tab}')
            }
            else {                                              ; if mouse is moved to the left
                Send('{Alt Down}{Shift Down}{Tab}{Shift Up}')
            }
            altTabActivated := true
            __ResetXPositionAndStartingTime()
        }

        CheckIfMouseGestureIsTracking := ObjBindMethod(this, 'HoldKeyAndDragToSwitchWindows', initial_xPos, startTime)
        SetTimer(CheckIfMouseGestureIsTracking, -20)

    } catch {
        __AbortAltTabSwitching(altTabActivated)
    }


    ; local functions to reset mouse starting point and elapsedTime
    __ResetXPositionAndStartingTime() {
        startTime    := A_TickCount   ; restart time
        initial_xPos := updated_xPos  ; reset x position
    }

    __AbortAltTabSwitching(altTabActivated) {
        if not altTabActivated        ; if mouse gesture didn't trigger, do a single alt-tab
            Send('{Alt down}{Tab}{Alt up}')
        else altTabActivated := false

        Send('{Alt Up}{Tab Up}{Shift Up}')
        Mouse.Cursor.Visibility('Show')
    }
}


; depending on what quadrant of the window you started the drag
; determines what directions the window resizes
Mouse.Gesture.HoldKeyAndDragToResizeWindow := (this) {
    window_under_mouse := Window.underMouse
    if Window.IsException(window_under_mouse)
    || Window.IsFullscreen(window_under_mouse) {
        return
    }

    hotkey := StripHotkey()
    CoordMode('Mouse', 'Window')                                                    ; get mouse position relative to window
    MouseGetPos(&x_over_window, &y_over_window)                                     ; get position of mouse on window
    WinActivate(window_under_mouse)                                                 ; activate window under mouse

    CoordMode('Mouse', 'Screen')                                                    ; get mouse position relative to screen
    MouseGetPos(&initial_xPos, &initial_yPos)                                       ; initialize mouse starting point

    ; get initial window position
    WinGetPos(&initial_win_left, &initial_win_top, &win_width, &win_height, window_under_mouse)
    initial_win_right := initial_win_left + win_width, initial_win_bottom := initial_win_top + win_height


    quadrant := UpperLeftQuadrant() or UpperRightQuadrant() or LowerLeftQuadrant() or LowerRightQuadrant()
    UpperLeftQuadrant()  => (x_over_window <  (win_width//2) and y_over_window <  (win_height//2) ? 1 : 0)
    UpperRightQuadrant() => (x_over_window >= (win_width//2) and y_over_window <  (win_height//2) ? 2 : 0)
    LowerLeftQuadrant()  => (x_over_window <  (win_width//2) and y_over_window >= (win_height//2) ? 3 : 0)
    LowerRightQuadrant() => (x_over_window >= (win_width//2) and y_over_window >= (win_height//2) ? 4 : 0)

    Mouse.Cursor.VisibilityDisable()

    ResizeWindow(initial_xPos, initial_yPos)

    ResizeWindow(initial_xPos, initial_yPos) {
        static prev_width := 0, prev_height := 0                                    ; used for tooltip

        MouseGetPos(&mouse_xPos, &mouse_yPos)                                       ; update mouse position
        x_distance := mouse_xPos - initial_xPos                                     ; get x distance mouse moved
        y_distance := mouse_yPos - initial_yPos                                     ; get y distance mouse moved
        WinGetPos(&winX, &winY, &win_width, &win_height, window_under_mouse)        ; get window position and size

        if win_width != prev_width or win_height != prev_height {
            ToolTip('width:`t' win_width '`nheight:`t' win_height, (win_width/2)+5, (win_height/2)+5)
            prev_width := win_width, prev_height := win_height
        }

        switch quadrant {
        case 1:
            if quadrant = 1 and mouse_xPos < initial_win_right and mouse_yPos < initial_win_bottom {
                WinMove(winX+x_distance, winY+y_distance, win_width-x_distance, win_height-y_distance, window_under_mouse)
            }
        case 2:
            if mouse_xPos > initial_win_left and mouse_yPos < initial_win_bottom {
                WinMove(, winY+y_distance, win_width+x_distance, win_height-y_distance, window_under_mouse)
            }
        case 3:
            if mouse_xPos < initial_win_right and mouse_yPos > initial_win_top {
                WinMove(winX+x_distance,, win_width-x_distance, win_height+y_distance, window_under_mouse)
            }
        case 4:
            if mouse_xPos > initial_win_left and mouse_yPos > initial_win_top {
                WinMove(,, win_width+x_distance, win_height+y_distance, window_under_mouse)
            }
        }
        GetKeyState(hotkey, 'P') ? SetTimer(ResizeWindow.Bind(mouse_xPos, mouse_yPos), -10)
                                    : (Mouse.Cursor.VisibilityEnable(), ToolTip())
    }
}



/**
 * @author @SpeedMaster
 * https://www.autohotkey.com/boards/viewtopic.php?f=83&t=115226
 */
Mouse.Gesture.HoldKeyAndDragToDrawWindow := (this, color := 'Lime', transparent := 80) {
    if Window.IsException()                               ; guard clause
        return

    hotkey := StripHotkey()

    MouseGetPos(&initial_mouse_xPos, &initial_mouse_yPos)   ; get mouse position
    prevWidth := 0, prevHeight := 0                         ; initialize vars to check if window size changed so tooltip doesn't flash when sitting still

    Draw_Gui := Gui('+AlwaysOnTop -Caption +Border +ToolWindow +LastFound -DPIScale')
    WinSetTransparent(transparent)
    Draw_Gui.BackColor := color

    loop {
        MouseGetPos(&mouse_xPos, &mouse_yPos)               ; update mouse position
        width  := Abs(initial_mouse_xPos - mouse_xPos)      ; set width of gui
        height := Abs(initial_mouse_yPos - mouse_yPos)      ; set height of gui
        xPos   := Min(initial_mouse_xPos,  mouse_xPos)      ; set x pos of gui
        yPos   := Min(initial_mouse_yPos,  mouse_yPos)      ; set y pos of gui

        if width != prevWidth or height != prevHeight {     ; if gui size changed
            ToolTip('width: ' width '`nheight: ' height)     ; update tooltip
            prevWidth := width, prevHeight := height         ; update previous width and height
        }

        Draw_Gui.Show('x' xPos ' y' yPos  ' w' width ' h' height ' NoActivate')
        Sleep(1)
    } until not GetKeyState(hotkey, 'P') or GetKeyState('RButton', 'P') or GetKeyState('Escape', 'P')


    Draw_Gui.Destroy()
    ToolTip()

    ; if drawing gui was canceled
    if GetKeyState('RButton', 'P') or GetKeyState('Escape', 'P') {
        return
    }

    return {x: xPos, y: yPos, w: width, h: height}          ; return final dimensions of drawn gui
}


/**
 * @properties
 */
Mouse.Layer._layer_index :=  1       ; keep track of mouse layer in map
Mouse.Layer._layer := Map(
    1, 'Move Window',
    2, 'Resize Window',
    3, 'Move Window to Saved Position',
    4, 'Draw to Resize',
    5, 'AltTab Per Monitor',
)
Mouse.Layer.resizeLockState  := 0        ; state of cursor lock when resizing window

/**
 * @getters @setters
 */
Mouse.Layer.DefineProp('enabled', {
    Get: (this) {
        if Keyboard.Layer.activated and GetKeyState(Keyboard.Layer.modifier, 'P') {
            return this._layer.Get(this._layer_index)
        }
        return false
    }
})


/**
 * @methods
 */
Mouse.Layer.Disable := (this) {
    Mouse.Layer._layer_index := 1

    if Mouse.Layer.resizeLockState {
        Mouse.Layer.resizeLockState := 0
        Mouse.Layer.__CursorLock()
    } else {
        Mouse.Layer.resizeLockState := 0
    }
}



Mouse.Layer.next_mouse_layer := (this) => this.__Change_Mouse_Layer(1)
Mouse.Layer.prev_mouse_layer := (this) => this.__Change_Mouse_Layer(-1)


Mouse.Layer.CycleResizeCursorLock := (this) {
    if this.resizeLockState + 1 > 2 {
        this.resizeLockState := 0
    } else {
        this.resizeLockState++
    }

    this.__CursorLock()
}


Mouse.Layer.__CursorLock := (this) {
    MouseGetPos(&mouseX, &mouseY)

    switch this.resizeLockState {
    case 0: Mouse.ClipCursor.ConfineToArea(false)
    case 1: Mouse.ClipCursor.ConfineToArea(true, VirtualScreen.left, mouseY, VirtualScreen.right, mouseY)
    case 2: Mouse.ClipCursor.ConfineToArea(true, mouseX, VirtualScreen.top, mouseX, VirtualScreen.bottom)
    }
}


/**
 * @private @methods
 */
Mouse.Layer.__Change_Mouse_Layer := (this, change_amount) {
    this._layer_index += change_amount

    this._layer_index := this._layer_index < 1 ? this._layer.Count      ; if cycling backwards and hit zero, set index to last position
                        : this._layer_index > this._layer.Count ? 1      ; else if index is greater than last position, set to start
                        : this._layer_index                              ; else leave it alone

    Keyboard.Layer.Gui_Text_Update()    ; update gui
    Sleep(70)
}


class __Jump {
    static Call(*) {
        this.__CreatePreview()
    }

    static Hide() {
        this.Preview.Hide()
        this.image.Value := ''  ; don't remove
    }

    static __PreviewVisible {
        get {
            DetectHiddenWindows(false)
            return WinExist('ahk_id' this.Preview.Hwnd)
        }
    }

    static __isMouseOnPreview {
        get {
            MouseGetPos(,, &win)
            return win = this.Preview.Hwnd
        }
    }

    static __New() {
        Preview := Gui('+AlwaysOnTop +ToolWindow -SysMenu -Caption +E0x80000 +E0x02000000')
        Preview.MarginX := Preview.MarginY := 0
        this.image := Preview.AddPicture()
        Preview.Show('NoActivate Hide')
        this.Preview := Preview
        this._pToken := Gdip_Startup()

        SetupHotkeys()

        OnExit((*) {
            Gdip_Shutdown(this._pToken)
            return 0
        })

        SetupHotkeys() {
            HotIf((*) => this.__PreviewVisible)
            Hotkey('*LButton', (*) {
                if !this.__isMouseOnPreview {
                    this.Hide()
                    return
                }

                CoordMode('Mouse', 'Window')
                MouseGetPos(&x, &y)
                Preview.GetPos(,, &menuW, &menuH)

                scaleMouseMenuX := x / menuW
                scaleMouseMenuY := y / menuH
                l := SysGet(76)
                t := SysGet(77)
                r := SysGet(78)
                b := SysGet(79)

                newX := l + scaleMouseMenuX * (r)
                newY := t + scaleMouseMenuY * (b)

                struct := (Integer(newX) & 0xFFFFFFFF | Integer(newY) << 32)
                handle := DllCall('MonitorFromPoint', 'Int64', struct, 'UInt', 0)
                if !handle {
                    return
                }

                this.Hide()
                CoordMode('Mouse', 'Screen')
                MouseMove(newX, newY)
            })

            HotIf((*) => this.__PreviewVisible)
            Hotkey('*Escape', (*) => this.Hide())

            HotIf()
        }
    }

    static __CreatePreview() {
        if this.__PreviewVisible {
            this.Hide()
        }

        pBitmap := Gdip_BitmapFromScreen()
        width := Gdip_GetImageWidth(pBitmap)
        height := Gdip_GetImageHeight(pBitmap)

        targetWidth := 2000
        scale := targetWidth / width
        w := targetWidth
        h := height * scale

        CoordMode('Mouse', 'Screen')
        MouseGetPos(&mouseX, &mouseY)
        x := mouseX - (w / 2)
        y := mouseY - (h / 2)

        hMonMouse := MonitorFromPoint(mouseX, mouseY)

        if hMonMouse != MonitorFromPoint(x, y)
        || hMonMouse != MonitorFromPoint(x+w, y+h) {
            NumPut('UInt', 40, monInfo := Buffer(40))
            if !DllCall('user32\GetMonitorInfo', 'Ptr', hMonMouse, 'Ptr', monInfo) {
                throw Error('Something went wrong getting monitor info.')
            }

            left    := NumGet(monInfo,  4, 'Int')
            top     := NumGet(monInfo,  8, 'Int')
            right   := NumGet(monInfo, 12, 'Int')
            bottom  := NumGet(monInfo, 16, 'Int')
            monWidth := right - left

            if w > monWidth {
                w := monWidth
                scale := w / width
                h := height * scale
                x := mouseX - (w / 2)
                y := mouseY - (h / 2)
            }

            if x < left {
                x := left
            } else if x + w > right {
                x := right - w
            }

            if y < top {
                y := top
            } else if y + h > bottom {
                y := bottom - h
            }
        }

        pBitmap := ResizeBitmap(pBitmap, w, h)
        hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
        if !hBitmap {
            MsgBox('failed hBitmap')
        }

        this.Preview.Move(x, y, w, h)
        this.image.Value := 'HBITMAP:' hBitmap
        this.Preview.Show()

        ; cleanup
        Gdip_DisposeImage(pBitmap)
        DeleteObject(hBitmap)

        MonitorFromPoint(x, y) {
            struct := (Integer(x) & 0xFFFFFFFF | Integer(y) << 32)
            return DllCall('MonitorFromPoint', 'Int64', struct, 'UInt', 0)
        }

        ResizeBitmap(pBitmap, newWidth, newHeight) {
            pNewBitmap := Gdip_CreateBitmap(newWidth, newHeight)
            G := Gdip_GraphicsFromImage(pNewBitmap)
            Gdip_DrawImage(G, pBitmap, 0, 0, newWidth, newHeight)
            Gdip_DisposeImage(pBitmap)
            Gdip_DeleteGraphics(G)
            return pNewBitmap
        }
    }
}


class __CaptureMouse {
    static _hookMouse := false

    static ClearBounds() => this.DeleteProp('ConfineCallback')

    static Start() {
        if !this._hookMouse {
            this._hookMouse := DllCall('SetWindowsHookEx',      ; run callback whenever mouse is moved
                'Int', 14,                                      ; WH_MOUSE_LL
                'UInt', CallbackCreate(HookCallback, 'Fast'),   ; lpfn callback
                'UInt', 0,                                      ; hMod (NULL)
                'UInt', 0)                                      ; dwThreadId
        }

        ; nCode will be 0 if wParam and lParam contain information about a mouse message
        HookCallback(nCode, wParam, lParam) {
            if !nCode && wParam = 0x200 {
                mouseX := NumGet(lParam, 0, 'Int')          ; mouse x coord
                mouseY := NumGet(lParam, 4, 'Int')          ; mouse y coord
                this.__ConfineCallback(&mouseX, &mouseY)    ; update x, y coords

                DllCall('SetCursorPos', 'Int', mouseX, 'Int', mouseY)   ; set mouse position to current position or to edge of the radius if tried to move more than radius
                return 1
            }

            return DllCall('CallNextHookEx', 'UInt', 0, 'Int', nCode, 'UInt', wParam, 'UInt', lParam)
        }
    }

    static Stop() => this._hookMouse := !DllCall('UnhookWindowsHookEx', 'UInt', this._hookMouse)

    static Toggle() {
        if this._hookMouse {
            this.Stop()
        } else {
            this.Start()
        }
    }

    static Call(*) {
        this.Start()
    }

    static RectBounds(left := 0, top := 0, right := A_ScreenWidth, bottom := A_ScreenHeight) {
        ; subtract 1 because cartesian coordinates
        right  := left + right - 1
        bottom := top + bottom - 1

        this.__ConfineCallback := (this, &mouseX, &mouseY) {
            if mouseX < left {
                mouseX := left
            } else if mouseX > right {
                mouseX := right
            }

            if mouseY < top {
                mouseY := top
            } else if mouseY > bottom {
                mouseY := bottom
            }
        }
    }

    static RadiusBounds(radius := 0, x := '', y := '') {
        this.__ConfineCallback := (this, &mouseX, &mouseY) {
            ; if coords aren't specified
            ; use current mouse position as center
            if x = '' {
                x := mouseX
            }

            if y = '' {
                y := mouseY
            }

            dx   := mouseX - x                                      ; distance mouseX moved
            dy   := mouseY - y                                      ; distance mouseY moved
            dist := Sqrt((dx ** 2) + (dy ** 2))                     ; distance from center of circle moved

            if dist > radius {                                      ; if the distance the mouse moved is greater than radius specified
                dist := radius / dist                               ; get ratio of radius and distance mouse moved past it
                dx *= dist, dy *= dist                              ; multiply the distance mouse moved by the ratio to get the distance the mouse SHOULD have moved
                mouseX := x + dx                                    ; add distance mouseX SHOULD have moved to the previous supported position
                mouseY := y + dy                                    ; add distance mouseY SHOULD have moved to the previous supported position
            }
        }
    }

    static ConfineToArea(left := 0, top := 0, right := A_ScreenWidth-1, bottom := A_ScreenHeight-1) {
        this.RectBounds(left, top, right, bottom)
        this.Start()
    }

    /**
     * @param {Int} @radius
     * @param {Int} @x optional x coord
     * @param {Int} @y optional y coord
     * If coords aren't specified, uses the current mouse position as the center
     */
    static ConfineToRadius(radius := 0, x := '', y := '') {
        this.RadiusBounds(radius, x, y)
        this.Start()
    }

    static ConfineToMonitor(mon) =>
        this.ConfineToArea(Monitor(mon).left, Monitor.top, Monitor.right, Monitor.bottom)

    static ConfineToMonitorMouseIsOn() =>
        this.ConfineToArea(Monitor(Monitor.mouseIsOn).left, Monitor.top, Monitor.right, Monitor.bottom)

    static ConfineToMonitorWindowIsOn(id := 'A') =>
        this.ConfineToArea(Monitor(Monitor.FromWindow(id?)).left, Monitor.top, Monitor.right, Monitor.bottom)

    static ConfineXAxisToMonitorMouseIsOn() =>
        this.ConfineToArea(Monitor(Monitor.mouseIsOn).left, Mouse.y, Monitor.right, Mouse.y)

    static ConfineYAxisToMonitorMouseIsOn() =>
        this.ConfineToArea(Mouse.x, Monitor(Monitor.mouseIsOn).top, Mouse.x, Monitor.bottom)

    static ConfineXAxisAcrossVirtualScreen() =>
        this.ConfineToArea(VirtualScreen.left, Mouse.y, VirtualScreen.right, Mouse.y)

    static ConfineYAxisAcrossVirtualScreen() =>
        this.ConfineToArea(Mouse.x, VirtualScreen.top, Mouse.x, VirtualScreen.bottom)

    static ConfineToWindow(winTitle?, winText?, excludeTitle?, excludeText?) {
        win := Window(winTitle?, winText?, excludeTitle?, excludeText?)
        this.ConfineToArea(win.left, win.top, win.right, win.bottom)
    }

    static ConfineToWindowMouseIsOn() {
        win := Window(Window.underMouse)
        this.ConfineToArea(win.left, win.top, win.right, win.bottom)
    }

    static __New() {
        OnExit((*) {
            this.Stop()
            return 0
        })
    }
}