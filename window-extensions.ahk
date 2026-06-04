#Include <window>
#Include <mouse>
#Include <monitor>


;============================================================================================
; @Properties
;============================================================================================
Window.mouseGestureUsed := false    ; used to prevent certain hotkeys from clashing if they're easy to trigger


;============================================================================================
; @Methods
;============================================================================================


/**
 * @param {Integer} MonitorToSwitchTo monitor number to cycle windows on
 * @param {Boolean} activateFirst_ThenSwitchWindow default := false
 * @param {Function} onActivateCallback user callback if they want something to happen when the window successfully changes
 *
 * when ***false***, triggering the function always causes the window found to move to the
 * bottom of the stack and activate the next one
 *
 * when ***true***, cycling windows on a specific monitor makes the first found window activate (when not active)
 * before cycling through and activating the next window
 */
Window.GetNextOnMonitor := (this, MonitorToSwitchTo, activateThenSwitch := true, OnActivateCallback := (id) => 0) {
    if MonitorToSwitchTo > MonitorGetCount() {                      ; if monitor to check exceeds amount of actual monitors
        return                                                      ; exit
    }

    ids := WinGetList(,,, 'Program Manager')                        ; store an array of all the window ids in an array called ids, except desktop
    windowFound := activateThenSwitch                               ; used to keep track of a found window
    prevId := 0                                                     ; saves id of window found on monitor in case it needs to be activated

    for id in ids {                                                 ; loop through windows
        if Window.IsException(id) {                                 ; if exception is found, skip
            continue
        }

        thisMonitor := Monitor.FromWindow(id)                       ; find out which monitor this window is on

        if thisMonitor = MonitorToSwitchTo {                        ; if window is found on monitor
            if activateThenSwitch {                                 ; if you want the first window found on the monitor to activate first
                if WinActive(id) {                                  ; if window is active
                    WinMoveBottom(id)                               ; move to bottom of stack
                    continue                                        ; finds next window to activate
                }
            }

            if !windowFound {                                       ; first window found
                WinMoveBottom(id)                                   ; push window to bottom of stack
                prevId := id                                        ; saves id of window on monitor in case it's the only window on that monitor
                windowFound := true                                 ; skip this code block next loop
                continue                                            ; find next window on identifier monitor
            }


            try WinActivate(id)                                     ; activate found window
            this.ShowActiveWindowGui()                              ; show gui to indicate activated window
            OnActivateCallback(id)                                  ; user-defined callback is invoked
            break                                                   ; done
        }

        if A_Index = ids.Length and windowFound {                   ; if last window in list that wasn't found on identifier monitor and a previous window was, activate that previous window
            try WinActivate(prevId)                                 ; i.e. if only one window on monitor is found, activate it
        }
    }
}


/**
 * @author iseahound
 * @modified crash
 * @source https://www.autohotkey.com/boards/viewtopic.php?f=83&p=566016#p566016
 * @param {String} z_order Whether to use the most recent window or the previous window.
 * @param {Integer} monitor The monitor to cycle windows through, if not provided, uses the monitor the mouse is on.
 * @param {Bool} activate_first Only cycles to new window if last found window is the active window.
 * Personal notes:
 *      The old method didn't activate fullscreen-exclusive apps (games).
 *      Turns out this one doesn't always work either for the above reason.
 *      Future me: this may not be related to games. This also fails sometimes for regular programs.
 */
Window._OnFocus  := (*) => 0
Window.OnFocusHandler := (this, Callback) {
    this._OnFocus := (_, hwnd) => Callback(hwnd)
}

Window.FocusNext := (this, monitor := 0, activate_first := true) => this.Focus('next', monitor, activate_first)
Window.FocusPrev := (this, monitor := 0, activate_first := true) => this.Focus('prev', monitor, activate_first)

Window.Focus := (this, z_order, monitor, activate_first := false) {
    static prev_order := ''
    static z := 0
    debug := false
    Tooltip()

    windows := Window.GetAltTabList(monitor)
    win_count := windows.length

    switch win_count {
    case 0: return 0
    case 1: return ActivateWindow(windows[1])
    }

    always_on_top := GetAlwaysOnTopCount()

    if (win_count - always_on_top) < 2 {
        return ActivateWindow(windows[-1])
    }

    if z_order = 'prev' {
        z := GetRecentIndex()
    } else if z_order = 'next' {
        z := GetNextIndex()
    } else if z_order ~= '^-?\d+$' {
        z := z_order
    }

    if debug {
        return DebugTooltip()
    }

    prev_order := z_order
    hwnd := windows[z]

    ; if window on monitor should be set active before focusing next window
    if activate_first {
        ActivateFirstWindowOnNewMonitor()
    }

    return ActivateWindow(hwnd)

    ActivateWindow(hwnd) {
        WinActivate('ahk_id' hwnd)
        this._OnFocus(hwnd)
        return hwnd
    }

    GetNextIndex() {
        if z_order != prev_order || z > win_count {
            return GetRecentIndex()
        }

        return z + (z < win_count)
    }

    GetRecentIndex() {
        ; search for the window that is next in the z_order after the current active window
        active_window := WinActive('A')
        loop win_count {
            index := A_Index + 1
        } until (active_window = windows[A_Index])

        ; if z index is out of bounds, loop back to first normal window
        if index > win_count {
            index := always_on_top + 1
        }

        ; if z-index is still greater than window list
        if (index > win_count) {
            debug := true
        }

        return index
    }

    GetAlwaysOnTopCount() {
        local always_on_top := 0
        for hwnd in windows {
            if 0x8 & WinGetExStyle(hwnd) {
                always_on_top += 1
            }
        }

        return always_on_top
    }

    ActivateFirstWindowOnNewMonitor() {
        first_window_found := windows[1 + always_on_top]    ; get first window on monitor that isn't AlwaysOnTop
        if !WinActive('ahk_id' first_window_found) {
            hwnd := first_window_found
        }
    }

    DebugTooltip() {
        result := ''
        for i, v in windows {
            info := Format('{}. {} - {}`n', i, (WinGetTitle(v) || WinGetClass(v)), v)
            result .= info
        }
        return ToolTip(result)
    }
}

/**
 * Cycle through the open windows of the active program
 */
Window.CycleProgramWindows := (this) {
    if !currentWindow := WinExist('A') {
        return
    }

    processName := WinGetProcessName(currentWindow)
    list := WinGetList('ahk_exe' processName)

    if count := list.Length < 2 {
        return
    }

    WinMoveBottom(list[1])
    targetWindow := list[2]

    if WinGetMinMax(targetWindow) = -1 {
        WinRestore(targetWindow)
    }
    WinActivate(targetWindow)
}

/**
 * swaps the position/size of two windows
 * if neither parameter is provided, it will use the active window and the window under the cursor
 */
Window.SwapWindows := (this, window1, window2) {
    first := IsSet(window1)
    second := IsSet(window2)

    if !first && !second {
        window1 := WinExist('A')
        MouseGetPos(,, &window2)
    } else if !first || !second {
        throw Error('Must provide both arguments or no arguments.')
    }

    WinGetPos(&x1, &y1, &w1, &h1, window1)
    WinGetPos(&x2, &y2, &w2, &h2, window2)
    WinMove(x2, y2, w2, h2, window1)
    WinMove(x1, y1, w1, h1, window2)
}


Window.ShowActiveWindowGui := (this, winTitle := 'A') {
    static ActiveWindowGui := CreateActiveGui()                         ; initialize gui

    if WinExist('ahk_id ' ActiveWindowGui.Hwnd) {                       ; if gui is shown
        SetTimer(__ActiveGuiFade, 0)                                    ; stop timer from triggering if it's about to trigger
        Sleep(15)                                                       ; wait long enough for fade method to stop if running
    }

    processName := GetProgramName(WinGetProcessPath(winTitle))

    if processName = '' {
        process := WinGetProcessName(winTitle)
        processName := StrSplit(process, '.exe')[1]                     ; split process name and .exe and assign just the first index (process name)
    }

    ActiveWindowGui.windowName.text := processName

    if processName != '' {                                              ; if text not empty (without this check, gui disappears when all characters are backspaced)
        text_size := GetTextSize(ActiveWindowGui.windowName)            ; get text size
        ActiveWindowGui.windowName.Move(,,, text_size.height)           ; set text control height
    }

    ActiveWindowGui.GetPos(&x, &y, &width, &height)                     ; get gui dimensions
    WinSetTransparent(255, ActiveWindowGui)                             ; set opacity to 100%

    show_position := Format('x{} y{}', Window.centerX - (width/2), Window.centerY - (height/2))
    ActiveWindowGui.Show('AutoSize NoActivate ' show_position)

    fade_out := false                                                   ; allow fade-out
    SetTimer(__ActiveGuiFade, -1000)                                    ; begin fade-out after 1 second

    ; fade-out effect for gui
    static __ActiveGuiFade() {
        hwnd := 'ahk_id' . ActiveWindowGui.Hwnd
        if !WinExist(hwnd) {
            ActiveWindowGui.Hide()
            return
        }

        transparency := WinGetTransparent(hwnd)
        ; The below line sometimes errors (Critical Error Invalid Memory Read/Write). I've changed it from just ActWinGui to use ahk_id to see if that helps. It doesn't.
        try {
            WinSetTransparent(transparency-4, hwnd)
            SetTimer(__ActiveGuiFade, -10)
        }
        catch {
            ActiveWindowGui.Hide()
            return
        }
    }

    GetTextSize(textCtrl) {   ; @teadrinker
        static WM_GETFONT := 0x0031, DT_CALCRECT := 0x400
        hDC      := DllCall('GetDC', 'Ptr', textCtrl.Hwnd, 'Ptr')
        hPrevObj := DllCall('SelectObject', 'Ptr', hDC, 'Ptr', SendMessage(WM_GETFONT,,, textCtrl), 'Ptr')
        height   := DllCall('DrawText', 'Ptr', hDC, 'Str', textCtrl.Value, 'Int', -1, 'Ptr', buf := Buffer(16), 'UInt', DT_CALCRECT)
        width    := NumGet(buf, 8, 'Int') - NumGet(buf, 'Int')

        DllCall('SelectObject', 'Ptr', hDC, 'Ptr', hPrevObj, 'Ptr')
        DllCall('ReleaseDC', 'Ptr', textCtrl.Hwnd, 'Ptr', hDC)
        return {width:  Round(width  * 96 / A_ScreenDPI),       ; return width of text object
                height: Round(height * 96 / A_ScreenDPI)}       ; and height of text object
    }

    GetProgramName(path) {
        size := DllCall("version\GetFileVersionInfoSizeW", "str", path, "uint*", 0, "uint")
        if !size {
            return
        }

        buf := Buffer(size)
        if !DllCall("version\GetFileVersionInfoW", "str", path, "uint", 0, "uint", size, "ptr", buf) {
            return
        }

        Query(val) {
            ptr := 0, len := 0
            if DllCall("version\VerQueryValueW",
                "ptr", buf,
                "str", "\StringFileInfo\040904b0\" val,
                "ptr*", &ptr,
                "uint*", &len)
            {
                return StrGet(ptr, "UTF-16")
            }
        }

        return Query('ProductName')

        ; return {
        ;     ProductName:   Query("ProductName"),
        ;     FileDescription: Query("FileDescription"),
        ;     CompanyName:   Query("CompanyName"),
        ;     OriginalFilename: Query("OriginalFilename")
        ; }
    }

    CreateActiveGui() {
        goo := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border +E0x20')
        goo.BackColor := '131313'
        goo.MarginX   := 6
        goo.MarginY   := 6

        goo.SetFont('s18 cffffff bold')
        goo.AddText('Center', 'Activated')

        goo.SetFont('s12 c14e347')
        goo.windowName := goo.AddText('Center y+0 wp', '')

        goo.Show('x0 y0 AutoSize NoActivate')
        goo.AddBorder(, 1, 'dddddd')
        goo.Hide()
        return goo
    }
}



Window.Prototype.DefineProp('monitor', {Get: (this) => Monitor(Monitor.FromWindow(this.criteria*)).index})
Window.Prototype.DefineProp('screen',  {Get: (this) => Screen(Monitor.FromWindow(this.criteria*)).index})

/**
 * This property is useful if you have hotkeys or a setup that moves/resizes a window to be fullscreen that doesn't use the maximize
 */
Window.Prototype.DefineProp('isFullscreen', {Get: (this) {
    if this.isMaximized {
        return true
    }

    this.GetPosWithoutExtendedFrameBounds(&x, &y, &width, &height)
    mon := Screen(Monitor.FromWindow(this.hwnd))

    if CompareDimensions() {
        return true
    }

    return false

    CompareDimensions() {
        diff := 8	; arbitrary pixel offset window can be from screen edge to be considered fullscreen

        if Abs(mon.left - x) < diff
        && Abs(mon.right - (x + width)) < diff
        && Abs(mon.top - y) < diff {
            if Abs(mon.bottom - (y + height)) < diff {
                return true
            } else {
                if Abs(Monitor(mon.index).bottom - (y + height)) < diff {	; change bottom to account for taskbar
                    return true
                }
            }
        }
    }
}})


Window.Prototype.Fullscreen := (this) {     ; makes window the size of the monitor
    mon := Monitor.FromWindow(this.hwnd)    ; update monitor dimensions depending on what monitor window is located on
    this.Reposition(mon.left, mon.top)      ; update left and top position of window
    this.Resize(mon.width, mon.height)      ; update width and height of the window
    return this                             ; allows method chaining
}

Window.Prototype.FitToWorkArea := (this) {  ; makes window the size of the work area
    mon := Screen.FromWindow(this.hwnd)     ; update screen dimensions depending on what monitor window is located on
    this.Reposition(mon.left, mon.top)      ; update left and top position of window
    this.Resize(mon.width, mon.height)      ; update width and height of the window
    return this                             ; allows method chaining
}

Window.Prototype.MoveToMonitorCenter := (this, targetMon := Screen.FromWindow('A')) {
    mon := Screen(targetMon)
    WinMove(mon.left + (mon.width - this.width) // 2,
            mon.top + (mon.height - this.height) // 2,,, this.criteria*)
}

Window.Prototype.GetPosAsPercent := (this, &x, &y, &w, &h) {
    Mon := Monitor(Monitor.FromWindow(this.hwnd))
    this.GetPos(&x, &y, &w, &h)

    x := (x / Mon.width)  * 100
    y := (y / Mon.height) * 100
    w := (w / Mon.width)  * 100
    h := (h / Mon.height) * 100

    return this
}


Window.Prototype.Alter := (this, mode, horizontal := 0, vertical := 0) {
    static direction := DefaultMap()

    key := RegExReplace(A_ThisHotkey, '[~*$!#+^<>]|\sup')

    if horizontal {
        direction['x'] := horizontal
        direction[horizontal > 0 ? '+x' : '-x'] := key
    }

    if vertical {
        direction['y'] := vertical
        direction[vertical > 0 ? '+y' : '-y'] := key
    }

    accel := 1
    MoveWindowX := %mode%X
    MoveWindowY := %mode%Y

    ; move := {x: 1, y: 1}    ; static variant has problems

    ; if !move.x && !move.y {
    ; MoveWindow()
    ; }
    ; Sleep(100)

    loop {
        x := unset, y := unset, width := unset, height := unset

        xPos := GetKeyState(direction['+x'], 'P')
        xNeg := GetKeyState(direction['-x'], 'P')

        if xPos && !xNeg {
            direction['x'] := 1
        } else if xNeg && !xPos {
            direction['x'] := -1
        } else {
            direction['x'] := 0
        }

        yPos := GetKeyState(direction['+y'], 'P')
        yNeg := GetKeyState(direction['-y'], 'P')

        if yPos && !yNeg {
            direction['y'] := 1
        } else if yNeg && !yPos {
            direction['y'] := -1
        } else {
            direction['y'] := 0
        }

        ; if nothing is held, stop loop
        if direction['x'] = 0 && direction['y'] = 0
            break

        if Mod(A_Index, 5) = 0
            accel := Min(accel+1, 50)

        ; only call if direction was set
        if direction['x'] {
            MoveWindowX()
        }
        if direction['y'] {
            MoveWindowY()
        }

        this.Move(x?, y?, width?, height?)
        Sleep(1)
    }

    ; direction := DefaultMap()

    DefaultMap() {
        return Map(
            'x' , 0,    ; x direction
            'y' , 0,    ; y direction
            '+x', 0,    ; x right key
            '-x', 0,    ; x left key
            '+y', 0,    ; y down key
            '-y', 0,    ; y up key
        )
    }

    IncreaseX() {
        width := this.width + accel
        if direction['x'] < 0 {
            x := this.x - accel
        }
    }
    IncreaseY() {
        height := this.height + accel
        if direction['y'] > 0 {
            y := this.y - accel
        }
    }

    DecreaseX() {
        width := this.width - accel
        if direction['x'] > 0 {
            x := this.x + accel
        }
    }
    DecreaseY() {
        height := this.height - accel
        if direction['y'] < 0 {
            y := this.y + accel
        }
    }

    NudgeX() {
        width := this.width
        x := direction['x'] < 0
            ? this.x - accel
            : this.x + accel
    }
    NudgeY() {
        height := this.height
        y := direction['y'] > 0
            ? this.y - accel
            : this.y + accel
    }
}

Window.Prototype.Nudge    := (_, horizontal := 0, vertical := 0) => Window.Alter('nudge', horizontal, vertical)
Window.Prototype.Increase := (_, horizontal := 0, vertical := 0) => Window.Alter('increase', horizontal, vertical)
Window.Prototype.Decrease := (_, horizontal := 0, vertical := 0) => Window.Alter('decrease', horizontal, vertical)



Window.Reposition.Prototype.ToPreviousMonitor := (this) {
    Window.mouseGestureUsed := true
    WinActivate(this.Window.criteria*)
    Send('+#{Left}')
    return this
}
Window.Reposition.Prototype.ToNextMonitor := (this) {
    Window.mouseGestureUsed := true
    WinActivate(this.Window.criteria*)
    Send('+#{Right}')
    return this
}
Window.Reposition.Prototype.ToMonitor := (this, mon) {
    Window.mouseGestureUsed := true
    WinActivate(this.Window.hwnd)

    loop MonitorGetCount() - 1 {
        if mon = Monitor.FromWindow(this.Window.hwnd) {
            break
        }
        Send('+#{Right}')
        Sleep(30)
    }
    return this
}

Window.Reposition.Prototype.Up := (this) {
    WinActivate(this.Window.criteria*)
    Send('#{Up}')
    return this
}
Window.Reposition.Prototype.Down := (this) {
    WinActivate(this.Window.criteria*)
    Send('#{Down}')
    return this
}
Window.Reposition.Prototype.Left := (this) {
    WinActivate(this.Window.criteria*)
    Send('#{Left}')
    return this
}
Window.Reposition.Prototype.Right := (this) {
    WinActivate(this.Window.criteria*)
    Send('#{Right}')
    return this
}


Window.Prototype.SnapToScreenEdge := (this, horizontal := 0, vertical := 0) {
    activeScreen := Screen(Screen.FromWindow(this.hwnd))

    if horizontal > 0 {
        x := activeScreen.right - this.width
    } else if horizontal < 0 {
        x := activeScreen.left
    }

    if vertical > 0 {
        y := activeScreen.top
    } else if vertical < 0 {
        y := activeScreen.bottom - this.height
    }

    this.Reposition(x?, y?)
    return this
}

Window.Prototype.ExpandToScreenEdge := (this, horizontal := 0, vertical := 0) {
    activeScreen := Screen(Screen.FromWindow(this.hwnd))

    if horizontal > 0 {
        width := activeScreen.right - this.x
    } else if horizontal < 0 {
        x := activeScreen.left
        width := this.right - activeScreen.left
    }

    if vertical > 0 {
        y := activeScreen.top
        height := this.bottom - activeScreen.top
    } else if vertical < 0 {
        height := activeScreen.bottom - this.y
    }

    this.Move(x?, y?, width?, height?)
    return this
}


Window.Prototype.SnapToWindow := (this, horizontal := 0, vertical := 0) {
    distances := this.__FindNearestDistances(horizontal, vertical)

    moveH := horizontal && distances.h < distances.original
    moveV := vertical && distances.v < distances.original

    if moveH || moveV {
        newX := moveH ? this.x + (horizontal * distances.h) : this.x
        newY := moveV ? this.y + (vertical * distances.v) : this.y
        this.Move(newX, newY)
    }

    return this
}

Window.Prototype.ExpandToWindow := (this, horizontal := 0, vertical := 0) {
    distances := this.__FindNearestDistances(horizontal, vertical)

    stretchH := horizontal && distances.h < distances.original
    stretchV := vertical && distances.v < distances.original

    if stretchH || stretchV {
        newX := horizontal = -1 && stretchH ? this.x - distances.h : this.x
        newY := vertical = -1 && stretchV ? this.y - distances.v : this.y
        newW := stretchH ? this.width + distances.h : this.width
        newH := stretchV ? this.height + distances.v : this.height

        this.Move(newX, newY, newW, newH)
    }

    return this
}


Window.Prototype.FillEmptySpace := (this, x?, y?) {
    xSet := IsSet(x)
    ySet := IsSet(y)

    if xSet != ySet {   ; if either param is different, throw error
        throw Error('Both parameters must be provided or left blank.')
    }

    if !xSet {          ; if x is omitted, then y must be omitted due to previous check
        x := this.centerX
        y := this.centerY
    }

    ; used to require the coordinates matched an empty space on the desktop
    ; winID := Window.FromPoint(x, y)
    ; desktop := WinGetID('Program Manager ahk_class Progman ahk_exe explorer.exe')
    ; if desktop != winID {
    ;     throw Error('Coordinates must point to a space on the desktop.')
    ; }

    mon := Monitor.FromPoint(x, y)
    MonitorGetWorkArea(mon, &left, &top, &right, &bottom)

    list := Window.GetAltTabList(mon,,, this.title)

    for hwnd in list {
        win := Window(hwnd)

        ; check vertical overlap to constrain horizontal bounds
        if y >= win.y && y <= win.bottom {
            if win.right <= x && win.right > left {
                left := win.right
            }
            if win.x >= x && win.x < right {
                right := win.x
            }
        }

        ; check horizontal overlap to constrain vertical bounds
        if x >= win.x && x <= win.right {
            if win.bottom <= y && win.bottom > top {
                top := win.bottom
            }
            if win.y >= y && win.y < bottom {
                bottom := win.y
            }
        }
    }

    newW := right - left
    newH := bottom - top

    this.Move(left, top, newW, newH)
    return this
}


Window.Prototype.__FindNearestDistances := (this, horizontal, vertical) {
    if !horizontal && !vertical {
        return {h: 0, v: 0, original: 0}
    }

    mon  := Monitor.FromWindow(this.hwnd)
    list := Window.GetAltTabList(mon,,, this.title)

    MonitorGetWorkArea(mon,,, &originalDist)
    minDistH := originalDist
    minDistV := originalDist

    for win in list {
        nextWin := Window(win)

        if horizontal {
            diff := horizontal = 1 ? nextWin.x - this.right : this.x - nextWin.right
            if diff > 0 && diff < minDistH {
                minDistH := diff
            }
        }

        if vertical {
            diff := vertical = 1 ? nextWin.y - this.bottom : this.y - nextWin.bottom
            if diff > 0 && diff < minDistV {
                minDistV := diff
            }
        }
    }

    return {h: minDistH, v: minDistV, original: originalDist}
}



Window.Prototype._savedPositions := [{}, {}]
Window.savedPosition := {}

Window.Prototype.SavePosition := (this) {
    try {
        WinGetPos(&x, &y, &width, &height, this.criteria*)
        ; ToolTip('x: ' x ' y:' y ' w: ' width ' h:' height)
        this._savedPositions[2] := this._savedPositions[1]
        this._savedPositions[1] := {
            x: x,
            y: y,
            w: width,
            h: height,
        }

        Window.savedPosition := this._savedPositions[1]
    } catch {
        Window.ErrorTooltip('Failed saving window position.')
    }

    return this
}

Window.Prototype.MoveToSavedPosition := (this) {
    try {
        saved := Window.savedPosition
        this.Move(saved.x, saved.y, saved.w, saved.h)
    } catch {
        Window.ErrorTooltip('Failed moving window position.')
    }

    return this
}

Window.Prototype.RestorePosition := (this) {
    try {
        saved := this._savedPositions[2]
        this._savedPositions[2] := this._savedPositions[1]
        this._savedPositions[1] := saved

        this.Restore().Move(saved.x, saved.y, saved.w, saved.h)
    } catch {
        Window.ErrorTooltip('Failed restoring window position.')
    }

    return this
}


/** @Gestures */
Window.CycleGesture := (*) => Mouse.Gesture.HoldKeyAndDragToSwitchWindows()
Window.Reposition.ByDraggingWindow := (*) => Mouse.Gesture.HoldKeyToDragWindow()

Window.Resize.Prototype.ByDragginWindow := (*) => Mouse.Gesture.HoldKeyAndDragToResizeWindow()

Window.Reposition.Prototype.ToSideByDraggingMouse := (this) {
    return Mouse.Gesture.DirectionalDrag(150, 150,
        ObjBindMethod(this, 'Up'),
        ObjBindMethod(this, 'Down'),
        ObjBindMethod(this, 'Left'),
        ObjBindMethod(this, 'Right'))
}

Window.Resize.Prototype.ByDrawingAWindow := (this) {
    if Window.IsException() {
        return
    }

    if !win := Mouse.Gesture.HoldKeyAndDragToDrawWindow() {
        return
    }

    WinRestore('A')                           ; if window was maximized, unmaximize it
    WinMove(win.x, win.y, win.w, win.h, 'A')  ; move active window to dimensions of drawn gui
}