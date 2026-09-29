;============================================================================================
; @A_Collection_of_Functions_to_be_Used_Wherever
;============================================================================================

;============================================================================================
; @Libraries
;============================================================================================
#Include clipboard-history.ahk


;============================================================================================
; @Functions
;============================================================================================
Range(start, end?, step := 1) {
    if not IsSet(end) {
        end := start
        start := 1
    }

    if end < start and step > 0 {
        step := -step
    }

    return (&n) {
        n := start
        start += step
        return (step > 0 ? n <= end : n >= end)
    }
}


/**
 * @param {hex} @color1
 * @param {hex} @color2
 * @returns {}
 * @example
 * if CompareColor(0x1f1f24, 0x1f1f28) < 10 {
 *     ; do something
 * }
 */
CompareHexColor(color1, color2) => Abs(color2 - color1)

/**
 * Returns the colors black or white, depending on the color passed.
 * It chooses based on what color should have better visibility against the given color.
 * @param backgroundColor
 * @returns {Integer 0xARGB}
 */
GetContrastingHexColor(color) {
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF

    brightness := GetColorLuminance(color)

    return brightness < 128 ? 0xFFFFFFFF : 0xFF000000  ; white text for dark backgrounds, black for light
}

/**
 * Takes a color of type string or RGB and converts it to ARGB
 * @param color
 * @returns {Integer | Number | String}
 */
ColorToHex(color) {
    if color is String {                            ; if it's a hex string (not a raw number)
        switch StrLen(color) {                      ; check string length
        case 6:     return Integer('0xFF' . color)  ; if 6 numbers
        case 8:     return Integer('0x' color)      ; if 8 numbers
        case 10:    return Integer(color)           ; if 10 numbers
        default:    return color                    ; otherwise, return it as is
        }
    } else {                                        ; if it's a numeric hex value
        color := color & 0xFFFFFFFF

        if color <= 0xFFFFFF {                      ; adds alpha if only RGB is supplied
            return color | 0xFF000000
        }

        return color                                ; otherwise, return unchanged
    }
}

EnsureHexMinAlpha(color) {
    if !((color >> 24) & 0xFF000000) {          ; if no alpha (full transparency)
        return color & 0x00FFFFFF | 0x01000000  ; add 1 alpha to make it behave properly
    }
    return color
}

HexToStringColor(color) {
    return Format('{:08X}', color & 0xFFFFFFFF)
}

/**
 * @description
 * Expects an 0xARGB color that will automatically brighten or darken depending on whether it is already considered bright or dark.
 * This function was created with the intent of highlighting something. So if there was a gui element I wanted to accentuate,
 *      I could pass that color to this function and it would automatically return a brighter or darker version.
 * @param color
 * @returns {Number 0xARGB}
 */
ColorBrightnessAutoAdjust(color, offset := 60) {
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF

    ; standard luminance formula
    brightness := GetColorLuminance(color)

    if (brightness > 170) {     ; if color is already bright, use a dark highlight
        r := Max(0, r - offset)
        g := Max(0, g - offset)
        b := Max(0, b - offset)
    } else {                    ; if color is dark, brighten it
        r := Min(255, r + offset)
        g := Min(255, g + offset)
        b := Min(255, b + offset)
    }

    return (0xFF << 24) | (r << 16) | (g << 8) | b  ; keep full opacity
}

/**
 * @description
 * Expects an 0xARGB color and an amount to adjust the color.
 * Positive values increase color brightness. Negative decrease color brightness.
 * @param color
 * @param offset
 * @returns {Number 0xARGB}
 */
ColorBrightnessAdjust(color, offset := 60) {
    ; extract ARGB components
    a := (color >> 24) & 0xFF
    r := ((color >> 16) & 0xFF) + offset
    g := ((color >> 8) & 0xFF) + offset
    b := (color & 0xFF) + offset

    ; clamp values
    r := Max(0, Min(255, r))
    g := Max(0, Min(255, g))
    b := Max(0, Min(255, b))

    ; recombine
    return (a << 24) | (r << 16) | (g << 8) | b
}

GetColorLuminance(color) {
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF

    ; standard luminance formula
    return  (r * 0.299 + g * 0.587 + b * 0.114)
}

RGBToBrightness(r, g, b) {
    return sqrt(0.299 * r ** 2 + 0.587 * g ** 2 + 0.114 * b ** 2)
}

/**
 * @author @skan
 * @source https://www.autohotkey.com/boards/viewtopic.php?t=3401
 * System Time in MS / STMS() returns milliseconds elapsed since 16010101000000 UT
 * Used similarly to A_TickCount, i.e. save current time, do something, get current time and compare to saved time
 */
GetSystemTime() {
    static GetSystemTimeAsFileTime := DllCall('GetProcAddress', 'UInt', DllCall('GetModuleHandle', 'Str', 'Kernel32.dll', 'Ptr'), 'AStr', 'GetSystemTimeAsFileTime', 'Ptr')
    DllCall(GetSystemTimeAsFileTime, 'Int64*', &T1601 := 0)
    return T1601 // 10000
}


GetTime() => A_Hour ':' A_Min ':' A_Sec
; GetTime() => FormatTime(, "hh:mm:ss tt")


; Very accurate Sleep
; However, doesn't yield rest of timeslice like Sleep() so other threads may not work as expected
Wait(duration) {
    if (hTimer := DllCall('CreateWaitableTimerExW', 'Ptr', 0, 'Ptr', 0, 'UInt', 2, 'UInt', 0x1F0003, 'UPtr')) {
	    if DllCall('SetWaitableTimer', 'UPtr', hTimer, 'UInt64*', duration * -10000, 'Int', 0, 'Ptr', 0, 'Ptr', 0, 'Int', 0) {
            DllCall('WaitForSingleObject', 'UPtr', hTimer, 'UInt', 0xFFFFFFFF)
            DllCall('CloseHandle', 'UPtr', hTimer)
        }
    }
}


; More accurate Sleep
; However, doesn't yield rest of timeslice like Sleep() so other threads may not work as expected
SleepV2(duration := 3000) {
    duration *= -10000
    DllCall('Ntdll.dll\ZwDelayExecution', 'UChar', 0, 'Int64*', duration)
}


IsFunc(FunctionName) {
    (FunctionName is String and FunctionName := %FunctionName%)
    return HasMethod(FunctionName)
}


;============================================================================================
; @Display_Text_On_Screen
;============================================================================================
Display(text := '', color := 'ebebeb', hide := 1000) {
    static myGui := ''
    ; Single static callback reference that destroys the GUI when triggered
    static hideFunc := () => (IsSet(myGui) && myGui && (myGui.Destroy(), myGui := ''))

    ; Explicit call with empty text destroys the GUI immediately
    if (text == '') {
        SetTimer(hideFunc, 0)
        if myGui {
            myGui.Destroy()
            myGui := ''
        }
        return
    }

    ; Create a fresh GUI if none currently exists on screen
    if !myGui || !WinExist(myGui) {
        myGui := CreateGui()
    }

    Critical(10)
    myGui.text.SetFont('c' color)
    myGui.text.Value := text

    text_size := GetTextSize(myGui.text)
    myGui.text.Move(,,, text_size.height)

    myGui.Show('AutoSize NoActivate xCenter y-6')

    ; If hide is a positive number, schedule destroy timer. Otherwise, cancel active timers.
    if (hide != false && hide > 0) {
        SetTimer(hideFunc, -Abs(hide))
    } else {
        SetTimer(hideFunc, 0)
    }
    Critical(0)

    GetTextSize(textCtrl) {
        static WM_GETFONT := 0x0031, DT_CALCRECT := 0x400
        hDC      := DllCall('GetDC', 'Ptr', textCtrl.Hwnd, 'Ptr')
        hPrevObj := DllCall('SelectObject', 'Ptr', hDC, 'Ptr', SendMessage(WM_GETFONT,,, textCtrl), 'Ptr')
        height   := DllCall('DrawText', 'Ptr', hDC, 'Str', textCtrl.Value, 'Int', -1, 'Ptr', buf := Buffer(16), 'UInt', DT_CALCRECT)
        width    := NumGet(buf, 8, 'Int') - NumGet(buf, 'Int')

        DllCall('SelectObject', 'Ptr', hDC, 'Ptr', hPrevObj, 'Ptr')
        DllCall('ReleaseDC', 'Ptr', textCtrl.Hwnd, 'Ptr', hDC)
        return {width:  Round(width  * 96 / A_ScreenDPI),
                height: Round(height * 96 / A_ScreenDPI)}
    }

    CreateGui() {
        myGui := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border')
        myGui.BackColor := '131313'
        myGui.MarginX := 0, myGui.MarginY := 4
        myGui.SetFont('s14 cebebeb')
        myGui.text := myGui.AddText('w' (A_ScreenWidth * 96 // A_ScreenDPI) // 4 ' Center')
        FrameShadow(myGui.Hwnd)
        return myGui
    }

    FrameShadow(hwnd) {
        DllCall('dwmapi\DwmSetWindowAttribute', 'Ptr', hwnd, 'Int', 33, 'Int*', 2, 'Int', 4)
        NumPut('Int', 1, 'Int', 1, 'Int', 1, 'Int', 1, margins := Buffer(16, 0))
        DllCall('dwmapi\DwmExtendFrameIntoClientArea', 'Ptr', hwnd, 'Ptr', margins)
    }
}


FrameShadow(hwnd) {
    if hwnd is Object && hwnd.HasOwnProp('Hwnd') {
        hwnd := hwnd.Hwnd
    }

    DllCall('dwmapi.dll\DwmIsCompositionEnabled', 'Int*', &dwmEnabled:=0)

    if !dwmEnabled {
        DllCall('user32.dll\SetClassLongPtr', 'Ptr', hwnd, 'Int', -26, 'Ptr', DllCall('user32.dll\GetClassLongPtr', 'Ptr', hwnd, 'Int', -26) | 0x20000)
        return
    }

    NumPut('Int', 1, 'Int', 1, 'Int', 1, 'Int', 1, margins := Buffer(16, 0))
    DllCall('dwmapi.dll\DwmSetWindowAttribute', 'Ptr', hwnd, 'Int', 33, 'Int*', 2, 'Int', 4)
    DllCall('dwmapi.dll\DwmExtendFrameIntoClientArea', 'Ptr', hwnd, 'Ptr', margins)
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

;============================================================================================
; @Strip_Hotkey_of_Modifiers
;============================================================================================
; possible func name: NaKey - as in naked hotkey
; RawHotkey, PureHotkey, BareHotkey, GetHotkey
; StripHotkey(key := A_ThisHotkey) => RegExReplace(key, '[~*$!#+^<>]')
StripHotkey(key := A_ThisHotkey) => RegExReplace(key, '[~*$!#+^<>]|\sup') ; removes up variants

; teadrinker
; key := RegExReplace(A_ThisHotkey, '.*?(\w+)$', '$1')


;============================================================================================
; @Check_if_Keys_Are_Down
;============================================================================================
KeysAreDown(keys*) {
    for key in keys {
        if GetKeyState(key, 'P') {
            return true
        }
    }
    return false
}


AllKeysAreDown(keys*) {
    for key in keys {
        if not GetKeyState(key, 'P') {
            return false
        }
    }
    return true
}

; this parameter is mostly useful if the function is being called by a hotkey and you want it to ignore that key
AnyKeyIsDown(keys_to_ignore*) {
    keys := ''
    for key in keys_to_ignore {
        keys .= key . '|'
    }

    loop 256 {
        vk := Format('vk{:x}', A_Index)

        try {
            if GetKeyState(vk, 'P') {
                if RegExMatch(GetKeyName(vk), keys '|Control|Alt|Win|Shift') {
                    continue
                }

                return true
            }
        }
    }
}


;============================================================================================
; @Move_Text_Cursor
;============================================================================================
MoveCursor(key) => SendMultiple(key)
AltSymbol(hotkey) => MoveCursor(hotkey)     ; uses same functionality but wanted relevant name


SendMultiple(keys) {
    if IsInteger(A_PriorKey) {
        loop A_PriorKey
            Send('{Blind}' keys)
    }
    else Send('{Blind}' keys)
}


DeleteMulti(hotkey, homeOrEnd) {
    shift := GetKeyState('Shift', 'P')

    if shift                                ; if shift is held
        Send('+' homeOrEnd hotkey)          ; delete to beginning or end of line
    else Send('^' hotkey)                   ; otherwise, send key with/without control
}


;============================================================================================
; @Highlight_Words
;============================================================================================
/**
 * @param direction acceptable values are left or right
 * @notes opposite direction doesn't always work correctly
 *
 * @example
 * F1::SelectWordsExpandable('Left')
 * F2::SelectWordsExpandable('Right')
 *
 * ; using hotkey examples above
 * @example text: The quick brown fox jumps over the lazy dog
 * if the cursor is just before the j, F2 highlights the word 'jumps'
 * if F2 is pressed again, 'jumps over' will be highlighted
 * if F1 is pressed after that, 'fox jumps over' will be highlighted
 *
 * essentially, you can think of the function this way: the starting position
 * ripples out left and right to reach further words
 */
SelectWordsExpandable(direction) {   ; selection becomes noticeable if you select too much
    static keys := Map()                                                        ; keys pressed that change direction. Automatically configured.
    static ih := () {
        ih := InputHook('V L0 I101')
        ih.key := ''
        ih.prior_key := ''
        ih.KeyOpt('{All}', 'N')
        ih.OnKeyDown := (ih, vk, sc) {
            ih.prior_key := ih.key
            ih.key := GetKeyName(Format('vk{:x}sc{:x}', vk, sc))
        }
        ih.Start()
        return ih
    }()

    ; current_key := StripHotkey()                                                ; strip hotkey of modifiers
    ToolTip(
        'A_ThisHotkey: '  A_ThisHotkey  '`n'
        'A_PriorHotkey: ' A_PriorHotkey '`n'
        'current_key: '   ih.key        '`n'
        'A_PriorKey: '    ih.prior_key
    )

    ; if same hotkey is triggered, continue selecting words in that direction
    if A_ThisHotkey = A_PriorHotkey and ih.key = ih.prior_key {                 ; if hotkey pressed is the same as last and no other key was pressed in between
        Send('^+{' direction '}')                                               ; highlight in the appropriate direction
        return                                                                  ; return
    }

    if keys.Has(ih.prior_key) and Copy() {                                      ; if opposite direction to highlight is chosen right after function was already used
        count := StrLen(Trim(A_Clipboard, '`t`r`n'))                            ; get amount of characters copied

        switch direction, 'Off' {                                               ; check what the current direction is to determine keys to send
            case 'Left':  Send('{Right}+{Left ' count '}^+{Left}')              ; highlight opposite direction of previous direction
            case 'Right': Send('{Left}+{Right ' count '}^+{Right}')             ; highlight opposite direction of previous direction
        }
    } else {                                                                    ; first time selecting word
        Send('^+{' direction '}')

        if not keys.Has(ih.key) {                                               ; if key hasn't been added to map
            keys.Set(ih.key, direction)                                         ; add key pressed
        }
    }
}
; SelectWordsExpandable(direction) {   ; selection becomes noticeable if you select too much
;     static keys := Map()                                                        ; keys pressed that change direction. Automatically configured.
;     current_key := StripHotkey()                                                ; strip hotkey of modifiers
;     ToolTip(
;         'A_ThisHotkey: '  A_ThisHotkey  '`n'
;         'A_PriorHotkey: ' A_PriorHotkey '`n'
;         'current_key: '   current_key   '`n'
;         'A_PriorKey: '    A_PriorKey
;     )
;     ; if same hotkey is triggered, continue selecting words in that direction
;     if A_ThisHotkey = A_PriorHotkey and current_key = A_PriorKey {              ; if hotkey pressed is the same as last and no other key was pressed in between
;         Send('^+{' direction '}')                                               ; highlight in the appropriate direction
;         return                                                                  ; return
;     }

;     if keys.Has(A_PriorKey) and Copy() {                                        ; if opposite direction to highlight is chosen right after function was already used                                              ; copy highlighted text
;         count := StrLen(Trim(A_Clipboard, '`t`r`n'))                            ; get amount of characters copied

;         ; count := StrLen(A_Clipboard)
;         ; ToolTip(A_Clipboard '`n' count, 0, 0, 1)
;         ; clipboard := StrReplace(A_Clipboard, '`r')
;         ; clipboard := StrReplace(clipboard, '`n')
;         ; count := StrLen(clipboard)
;         ; ToolTip(clipboard '`n' count, 800, 0, 2)

;         ; count := StrLen(A_Clipboard)

;         switch direction, 'Off' {                                               ; check what the current direction is to determine keys to send
;             case 'Left':  Send('{Right}+{Left ' count '}^+{Left}')              ; highlight opposite direction of previous direction
;             case 'Right': Send('{Left}+{Right ' count '}^+{Right}')             ; highlight opposite direction of previous direction
;         }
;     } else {                                                                    ; first time selecting word
;         Send('^+{' direction '}')

;         if not keys.Has(current_key) {                                          ; if key hasn't been added to map
;             keys.Set(current_key, direction)                                    ; add key pressed
;         }
;     }
; }


; example text: The quick brown fox jumps over the lazy dog
; if the cursor is just before the j, CapsLock & t highlights the word 'jumps'
; if CapsLock & t is pressed again, 'jumps over' will be highlighted
; if CapsLock & r is pressed after that, 'jumps' will be highlighted, undoing the previous highlight
SelectWordsInOneDirection(highlight) {
    if A_ThisHotkey = A_PriorHotkey {                                   ; if same hotkey is triggered, continue selecting words in that direction
        Send(SubStr(highlight, InStr(highlight, '^',,, 3)))
    } else if A_PriorHotkey = 'r' or A_PriorHotkey = 't' {              ; if the direction changes (other hotkey), undo word selection by going back other direction
        direction := InStr(highlight, 'Left') < InStr(highlight, 'Right') ? 'Left' : 'Right'
        Send('^+{' direction '}')
    } else {                                                            ; first time selecting word
        Send(highlight)
    }
}


; example text: The quick brown fox jumps over the lazy dog
; if the cursor is just before the j, CapsLock & t highlights the word 'jumps'
; if CapsLock & t is pressed again, 'jumps over' will be highlighted
; if CapsLock & r is pressed after that, 'over' will be highlighted, with
; the direction of highlighting intent reversed
SelectWordReverse(highlight) {   ; variable cuts down on calculations
    static sameDirectionWordHighlighting := ''

    if A_ThisHotkey = A_PriorHotkey {
        Send(sameDirectionWordHighlighting)
    }
    else {
        Send(highlight)
        sameDirectionWordHighlighting := SubStr(highlight, InStr(highlight, '^',,, 3))
    }
}


;============================================================================================
; @CreateStringFromArray useful for things such as a tooltip
; Not as efficient as Join() function
;============================================================================================
CreateStringFromArray(arr, joiningChar := '`n') {
    local list := ''
    for value in arr {
        list .= value . joiningChar
    }

    if joiningChar {
        list := SubStr(list, 1, -(StrLen(joiningChar)))
    }
    return list
}


;============================================================================================
; @Get_List_of_Running_Scripts
;============================================================================================
GetRunningScripts() {
    hiddenWindows := DetectHiddenWindows(1)
    scripts       := []
    scriptList    := WinGetList('ahk_class AutoHotkey',, 'launcher.ahk')

    for index, id in scriptList {
        title := WinGetTitle('ahk_id ' id)
        scripts.Push(RegExReplace(title, ' - AutoHotkey v[\- .0-9a-z]+$'))  ; stores all ahk scripts running in scripts array
        scripts[index] := RegExReplace(scripts[index], '^.+\\|\.+$')        ; converts the path name to just the name of the file
        scripts[index] := Format('{:L}', scripts[index])                    ; converts name to all lowercase
    }

    DetectHiddenWindows(hiddenWindows)
    return scripts
}


;============================================================================================
; @Add_a_Progress_Bar_to_Simulate_Progress
;============================================================================================
AddProgressBar(text, async := false) {
    async ? SetTimer(ShowProgressBar, -1) : ShowProgressBar()   ; timer version allows the progress bar to show up along-side whatever you're doing

    ShowProgressBar() {
        ProgressGui := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border')
        ProgressGui.BackColor := '181a1b'
        ProgressGui.AddText('cFFFFFF', text)
        ProgressGui.AddProgress('c6772a2 Background292a35 Smooth vprogress')
        ProgressGui.Show('NoActivate')

        while ProgressGui['progress'].value < 100 {
            ProgressGui['progress'].value += 4
            Sleep(10)
        }
        ProgressGui.Destroy()
    }
}


;============================================================================================
; @Window_Position_Without_Invisible_Borders
;============================================================================================
/**
 * @author plankoe
 * @source https://old.reddit.com/r/AutoHotkey/comments/14xjya7/force_window_size_and_position/
 * move window and fix offset from invisible border
 */
WinMoveEx(x?, y?, w?, h?, hwnd?) {
    if !IsSet(hwnd) {
        hwnd := WinExist('A')
    } else if !(hwnd is integer) {
        hwnd := WinExist(hwnd)
    }

    ; compare pos and get offset
    WinGetPosEx(&fX, &fY, &fW, &fH, hwnd)
    WinGetPos(&wX, &wY, &wW, &wH, hwnd)
    xDiff := fX - wX
    hDiff := wH - fH

    ; new x, y, w, h with offset corrected.
    IsSet(x) && nX := x - xDiff
    IsSet(y) && nY := y
    IsSet(w) && nW := w + xDiff * 2
    IsSet(h) && nH := h + hDiff
    WinMove(nX?, nY?, nW?, nH?, hwnd?)

    ; CoordMode('ToolTip', 'Screen')
    ; ToolTip(fX '`n' fY '`n' fW '`n' fH, 0, 0, 1)    ; ex dimensions
    ; ToolTip(wX '`n' wY '`n' wW '`n' wH, 200, 0, 2)  ; wingetpos dimensions
    ; ToolTip(xDiff '`n' hDiff, 400, 0, 3)            ; difference
    ; ToolTip(nX '`n' nY '`n' nW '`n' nH, 600, 0, 4)  ; new dimensions
}


WinGetPosEx(&x?, &y?, &w?, &h?, hwnd?) { ; get window position without the invisible border
    static DWMWA_EXTENDED_FRAME_BOUNDS := 9
    if !IsSet(hwnd) {
        hwnd := WinExist('A') ; last found window
    } else if !(hwnd is integer) {
        hwnd := WinExist(hwnd)
    }

    DllCall('dwmapi\DwmGetWindowAttribute',
            'Ptr' , hwnd,
            'UInt', DWMWA_EXTENDED_FRAME_BOUNDS,
            'Ptr' , RECT := Buffer(16, 0),
            'Int' , RECT.size,
            'UInt')     ; return unsigned int
    x := NumGet(RECT,  0, 'Int')
    y := NumGet(RECT,  4, 'Int')
    w := NumGet(RECT,  8, 'Int') - x
    h := NumGet(RECT, 12, 'Int') - y
}

/**
  * @author plankoe
  * @source https://old.reddit.com/r/AutoHotkey/comments/1dsecxe/targeting_netflix_desktop_app_doesnt_work_when_it/lb3ezhc/
 */
GetUWPWindow(WinTitle) {
    hwnd := 0
    loop {
        hwnd := DllCall("FindWindowEx", "ptr", 0, "ptr", hwnd, "str", "ApplicationFrameWindow", "ptr", 0)
        if WinExist(hwnd) {
            child := DllCall("FindWindowEx", "ptr", hwnd, "ptr", 0, "str", "Windows.UI.Core.CoreWindow", "ptr", 0)
            if WinExist(WinTitle " ahk_id" child)
                return child
        }
    } until !hwnd
    return 0
}

; WinMoveEx(x?, y?, w?, h?, hwnd := WinExist())
; {
;     RECT := WinGetPosEx()
;     x := NumGet(RECT,  0, 'Int')
;     y := NumGet(RECT,  4, 'Int')
;     w := NumGet(RECT,  8, 'Int') - x
;     h := NumGet(RECT, 12, 'Int') - y
;     WinMove(x, y, w, h, hwnd)
; }

; WinGetPosEx(hWindow, &X := "", &Y := "", &Width := "", &Height := "", &Offset_X := "", &Offset_Y := "") {
;     Static S_OK := 0x0,
;            DWMWA_EXTENDED_FRAME_BOUNDS := 9
;     ;-- Get the window's dimensions
;     ;   Note: Only the first 16 bytes of the RECTPlus structure are used by the
;     ;   DwmGetWindowAttribute and GetWindowRect functions.
;     RECTPlus := Buffer(24,0)
;     Try {
;        DWMRC := DllCall("dwmapi\DwmGetWindowAttribute",
;                         "Ptr",  hWindow,                     ;-- hwnd
;                         "UInt", DWMWA_EXTENDED_FRAME_BOUNDS, ;-- dwAttribute
;                         "Ptr",  RECTPlus                     ;-- pvAttribute
;                         "UInt", 16,                          ;-- cbAttribute
;                         "UInt")
;     }
;     Catch {
;        Return False
;     }
;     ;-- Populate the output variables
;     X := NumGet(RECTPlus,  0, "Int") ; left
;     Y := NumGet(RECTPlus,  4, "Int") ; top
;     R := NumGet(RECTPlus,  8, "Int") ; right
;     B := NumGet(RECTPlus, 12, "Int") ; bottom
;     Width    := R - X ; right - left
;     Height   := B - Y ; bottom - top
;     OffSet_X := 0
;     OffSet_Y := 0
;     ;-- Collect dimensions via GetWindowRect
;     RECT := Buffer(16, 0)
;     DllCall("GetWindowRect", "Ptr", hWindow,"Ptr", RECT)
;     ;-- Right minus Left
;     GWR_Width := NumGet(RECT,  8, "Int") - NumGet(RECT, 0, "Int")
;     ;-- Bottom minus Top
;     GWR_Height:= NumGet(RECT, 12, "Int") - NumGet(RECT, 4, "Int")
;     ;-- Calculate offsets and update output variables
;     NumPut("Int", Offset_X := (Width  - GWR_Width)  // 2, RECTPlus, 16)
;     NumPut("Int", Offset_Y := (Height - GWR_Height) // 2, RECTPlus, 20)
;     Return RECTPlus
;  }


; @descolada
/**
 * Gets the position, size, and offset of a window. See the *Remarks* section for more information.
 * Source: https://www.autohotkey.com/boards/viewtopic.php?f=6&t=3392
 * Additional credits: original idea and some code from *KaFu* (AutoIt forum)
 * @param WinTitle Target window title or handle
 * @param X Optional: contains the screen x-coordinate of the window
 * @param Y Optional: contains the screen y-coordinate of the window
 * @param Width Optional: contains the width of the window
 * @param Height Optional: contains the height of the window
 * @param LeftBorder Optional: thickness of the invisible left border
 * @param TopBorder Optional: thickness of the invisible top border
 * @param RightBorder Optional: thickness of the invisible right border
 * @param BottomBorder Optional: thickness of the invisible bottom border
 * @returns {Integer} Returns 0 if failed, otherwise the window handle
 *
 * Remarks:
 *
 * Starting with Windows Vista, Microsoft includes the Desktop Window Manager
 * (DWM) along with Aero-based themes that use DWM.  Aero themes provide new
 * features like a translucent glass design with subtle window animations.
 * Unfortunately, the DWM doesn't always conform to the OS rules for size and
 * positioning of windows.  If using an Aero theme, many of the windows are
 * actually larger than reported by Windows when using standard commands (Ex:
 * WinGetPos, GetWindowRect, etc.) and because of that, are not positioned
 * correctly when using standard commands (Ex: Gui.Show, WinMove, etc.).  This
 * function was created to 1) identify the true position and size of all
 * windows regardless of the window attributes, desktop theme, or version of
 * Windows and to 2) identify the appropriate offset that is needed to position
 * the window if the window is a different size than reported.
 *
 * The true size, position, and offset of a window cannot be determined until
 * the window has been rendered.  See the example script for an example of how
 * to use this function to position a new window.
 */
; WinGetPosEx(WinTitle:="", &X := "", &Y := "", &Width := "", &Height := "", &LeftBorder := 0, &TopBorder := 0, &RightBorder := 0, &BottomBorder := 0) {
; 	static S_OK := 0x0, DWMWA_EXTENDED_FRAME_BOUNDS := 9
; 	local RECT := Buffer(16, 0), RECTPlus := Buffer(24,0), R, B
; 	if !(WinTitle is Integer)
; 		WinTitle := WinGetID(WinTitle)
; 	DllCall("GetWindowRect", "Ptr", WinTitle, "Ptr", RECT)
; 	try DWMRC := DllCall("dwmapi\DwmGetWindowAttribute", "Ptr",  WinTitle, "UInt", DWMWA_EXTENDED_FRAME_BOUNDS, "Ptr", RECTPlus, "UInt", 16, "UInt")
; 	catch
; 	   return 0
; 	X := NumGet(RECTPlus, 0, "Int"), LeftBorder := X - NumGet(RECT, 0, "Int")
; 	Y := NumGet(RECTPlus, 4, "Int"), TopBorder := Y - NumGet(RECT, 4, "Int")
; 	R := NumGet(RECTPlus, 8, "Int"), RightBorder := NumGet(RECT,  8, "Int") - R
; 	B := NumGet(RECTPlus, 12, "Int"), BottomBorder := NumGet(RECT,  12, "Int") - B
; 	Width := R - X
; 	Height := B - Y
; 	return WinTitle
; }

/**
 * Moves the window based on the visual attributes of the window (adjusts for invisible borders).
 * @param X If omitted, the position in the X dimension will not be changed. Otherwise, specify
 * the X coordinate (in pixels) of the upper left corner of the target window's new location.
 * The upper-left pixel of the screen is at 0, 0.
 * @param Y If omitted, the position in the Y dimension will not be changed. Otherwise, specify
 * the Y coordinate (in pixels) of the upper left corner of the target window's new location.
 * The upper-left pixel of the screen is at 0, 0.
 * @param Width If omitted, the width will not be changed. Otherwise, specify the new width of the window (in pixels).
 * @param Height If omitted, the height will not be changed. Otherwise, specify the new height of the window (in pixels).
 * @param WinTitle WinTitle, same as normal WinMove
 * @param WinText Same as normal WinMove
 * @param ExcludeTitle Same as normal WinMove
 * @param ExcludeText Same as normal WinMove
 */
; WinMoveEx(X?, Y?, Width?, Height?, WinTitle?, WinText?, ExcludeTitle?, ExcludeText?) {
; 	WinGetPosEx(hWnd := WinGetID(WinTitle?, WinText?, ExcludeTitle?, ExcludeText?),,,,, &LeftBorder := 0, &TopBorder := 0, &RightBorder := 0, &BottomBorder := 0)
; 	if IsSet(X)
; 		X -= LeftBorder
; 	if IsSet(Y)
; 		Y -= TopBorder
; 	if IsSet(Width)
; 		Width += LeftBorder + RightBorder
; 	if IsSet(Height)
; 		Height += TopBorder + BottomBorder
; 	return WinMove(X?, Y?, Width?, Height?, hWnd)
; }



/**
 * @author plankoe
 * @param @hwnd
 */
MonInfoFromWindow(hwnd) {
    hMon := DllCall('MonitorFromWindow', 'Ptr', WinExist(hwnd), 'UInt', 2, 'Ptr')
    NumPut('UInt', 40, monInfo := Buffer(40))
    ; NumPut('UInt', 104, monInfo := Buffer(40 + 64))   ; ntepa
    if DllCall('user32\GetMonitorInfo', 'Ptr', hMon, 'Ptr', monInfo) {
        return {
            Handle          : hMon,
            Name            : Name := StrGet(monInfo.ptr + 40, 32),   ; CCHDEVICENAME = 32
            Number          : RegExReplace(Name, ".*(\d+)$", "$1"),
            Left            : L  := NumGet(monInfo,  4, 'Int'),
            Top             : T  := NumGet(monInfo,  8, 'Int'),
            Right           : R  := NumGet(monInfo, 12, 'Int'),
            Bottom          : B  := NumGet(monInfo, 16, 'Int'),
            WorkAreaLeft    : WL := NumGet(monInfo, 20, 'Int'),
            WorkAreaTop     : WT := NumGet(monInfo, 24, 'Int'),
            WorkAreaRight   : WR := NumGet(monInfo, 28, 'Int'),
            WorkAreaBottom  : WB := NumGet(monInfo, 32, 'Int'),
            Width           : R - L,
            Height          : B - T,
            WorkAreaWidth   : WR - WL,
            WorkAreaHeight  : WB - WT,
            Primary         : NumGet(monInfo, 36, 'UInt')           ; returns 0 or 1, if on primary monitor
        }
    }
}


/**
 * @param {int} @timeout the time between taps before timing out
 * @param {funcs*} @callbacks second function to call if tapped twice
 */
MultiTap(timeout := 200, callbacks*) {
    static taps := 0, funcs := []                               ; initialize
    taps ? 0 : funcs := callbacks                               ; save callbacks on first tap

    SetTimer(OnFinish, (++taps = funcs.Length) ? -1 : -timeout) ; if reached last tap, run immediately, else normal timeout period

    OnFinish() {
        taps := Min(taps, funcs.Length)                         ; ensure taps is always in bounds
        if funcs.Has(taps) {                                    ; index has value
            action := funcs[taps]                               ; get action depending on taps
            if action is String {                               ; if action is string
                Send(action)                                    ; send it
            } else {                                            ; else
                action()                                        ; try to call it
            }
        }
        taps := 0                                               ; reset tap count
    }
}


; example use - *LButton::HoldClick()
HoldClick(key := 'LButton') {
    (enable := GetKeyState(key, 'P')) ? SendEvent('{Click}') : 0
    SetTimer(HoldClick, -50 * enable)
}


; not tested
RepeatKeyWhileHeld(key := RegExReplace(A_ThisHotkey, '[~*$!^+#<>]')) {
    (enable := GetKeyState(key, 'P')) ? SendEvent('{Click}') : 0
    SetTimer(HoldClick.Bind(key), -50 * enable)
}


NewLineMsgBox(msgs*) {
    message := ''
    for msg in msgs {
        if IsObject(msg) {
            for item in msg {
                message .= item '`n'
            }
        }
        else {
            message .= msg '`n'
        }
    }
    MsgBox(message)
}


;============================================================================================
; @Tooltip_Keystates
;============================================================================================
ToolTipKeyStates(keys*) {
    static toggle := false, ShowKeyStates := () => GetKeyStates()
    SetTimer(ShowKeyStates, 20 * (toggle ^= 1))
    toggle = false ? ToolTip() : 0

    GetKeyStates() {
        list := ''
        for index, key in keys {
            list .= 'Key: ' keys[index] '`nPhysical state: ' GetKeyState(keys[index], 'P' ) '`nLogical state:   ' GetKeyState(keys[index])
            if index != keys.Length {
                list .= '`n`n'
            }
        }
        ToolTip(list)
    }
}


RepeatKeyPress(repeat_rate := 35, key?) {
    ThisHotkey := StripHotkey()                                                         ; remove modifiers from hotkey
    vksc := GetVKSC(key ?? ThisHotkey)                                                  ; get vk and sc

    SetTimer(SendKey, repeat_rate)                                                      ; start timer
    KeyWait(ThisHotkey)                                                                 ; wait for key to be released to not
    SendKey() => (GetKeyState(ThisHotkey, 'P') ? Send('{' vksc '}') : SetTimer(, 0))    ; if key held, send key, else stop timer
}


GetVKSC(key) => Format('vk{:x}sc{:x}', GetKeyVK(key), GetKeySC(key))


TaskbarToggleVisibility() {
    static ABM_SETSTATE := 0xA, ABS_AUTOHIDE := 0x1, ABS_ALWAYSONTOP := 0x2
    local size := (2 * A_PtrSize) + (2 * 4) + 16 + A_PtrSize

    local APPBARDATA := __GetTaskbarBarData()
    state := !GetTaskbarState()
    NumPut('UInt', state ? ABS_AUTOHIDE : ABS_ALWAYSONTOP, APPBARDATA, size - A_PtrSize)
    DllCall('Shell32\SHAppBarMessage', 'UInt', ABM_SETSTATE, 'Ptr', APPBARDATA)
}

GetTaskbarState(APPBARDATA?) {
    static ABM_GETSTATE := 0x4
    APPBARDATA ??= __GetTaskbarBarData()
    return DllCall('Shell32\SHAppBarMessage', 'UInt', ABM_GETSTATE, 'Ptr', APPBARDATA)
}

__GetTaskbarBarData() {
    local taskbar := 'ahk_class Shell_TrayWnd'
    local size := (3 * A_PtrSize) + 24
    local APPBARDATA := Buffer(size, 0)
    NumPut('UInt', size, APPBARDATA)
    NumPut('Ptr', WinExist(taskbar), APPBARDATA, A_PtrSize)
    return APPBARDATA
}

/**
 * @returns {Array(Objects)} Returns an array of objects that for each program on the taskbar.
 * @returns {[{name: x, path: y}]}
 */
GetPinnedTaskbarApps() {
    pinnedApps := []

    try {
        taskbandPath := A_AppData "\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

        if DirExist(taskbandPath) {
            loop files, taskbandPath "\*.lnk" {
                pinnedApps.Push({
                    name: SubStr(A_LoopFileName, 1, -4),
                    path: A_LoopFileFullPath
                })
            }
        } else {
            MsgBox("Directory doesn't exist: " taskbandPath)
        }
    } catch error as e {
        MsgBox("Error: " e.What " - " e.Extra)
    }

    return pinnedApps
}

; Not finished. instance approach is less appealing now that I know I can't hide specific taskbars.
; Probably make methods static, but unsure what to do as a whole.
class Taskbar {
    static ABM_GETSTATE     := 0x4
    static ABM_SETSTATE     := 0xA
    static ABS_AUTOHIDE     := 0x1
    static ABS_ALWAYSONTOP  := 0x2
    static APPBAR_SIZE      := (3 * A_PtrSize) + 24


    GetState() {
        APPBARDATA := this.__GetAppBarData()
        return DllCall('Shell32\SHAppBarMessage', 'UInt', Taskbar.ABM_GETSTATE, 'Ptr', APPBARDATA)
    }

    SetState(state) {
        APPBARDATA := this.__GetAppBarData()
        NumPut('UInt', state ? Taskbar.ABS_AUTOHIDE : Taskbar.ABS_ALWAYSONTOP, APPBARDATA, Taskbar.APPBAR_SIZE - A_PtrSize)
        DllCall('Shell32\SHAppBarMessage', 'UInt', Taskbar.ABM_SETSTATE, 'Ptr', APPBARDATA)
    }

    Toggle() {
        this.SetState(!this.GetState())
    }

    __GetAppBarData() {
        local APPBARDATA := Buffer(Taskbar.APPBAR_SIZE, 0)
        NumPut('UInt', Taskbar.APPBAR_SIZE, APPBARDATA)
        NumPut('Ptr', WinExist(this.hwnd), APPBARDATA, A_PtrSize)
        return APPBARDATA
    }

    /**
     * @param {Integer} monitor defaults to primary
     */
    __New(monitor := 1) {
        if monitor = 1 {
            this.hwnd := WinExist('ahk_class Shell_TrayWnd')
            return
        }

        for hwnd in WinGetList('ahk_class Shell_SecondaryTrayWnd') {
            monitorFound := Taskbar.GetMonitorFromTaskbar(hwnd)

            if monitorFound = monitor {
                this.hwnd := hwnd
                return
            }
        }

        this.hwnd := 0
    }


    /**
     * @returns {Array(Objects)} Returns an array of objects that for each program on the taskbar.
     * @returns {[{name: x, path: y}]}
     */
    static GetPinnedApps() {
        pinnedApps := []

        try {
            taskbandPath := A_AppData '\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'

            if DirExist(taskbandPath) {
                loop files, taskbandPath '\*.lnk' {
                    pinnedApps.Push({
                        name: SubStr(A_LoopFileName, 1, -4),
                        path: A_LoopFileFullPath
                    })
                }
            } else {
                MsgBox('Directory does not exist: ' taskbandPath)
            }
        } catch error as e {
            MsgBox('Error: ' e.What ' - ' e.Extra)
        }

        return pinnedApps
    }

    static GetMonitorFromTaskbar(winTitle?, winText?, excludeTitle?, excludeText?) {
        handle := Taskbar.GetHandleFromWindow(winTitle?, winText?, excludeTitle?, excludeText?)
        return Taskbar.NumberFromHandle(handle)
    }

    static GetHandleFromWindow(winTitle?, winText?, excludeTitle?, excludeText?) {
        ; MONITOR_DEFAULTTONULL = 0
        ; MONITOR_DEFAULTTOPRIMARY = 1
        ; MONITOR_DEFAULTTONEAREST = 2
        return DllCall('MonitorFromWindow', 'Ptr', WinExist(winTitle?, winText?, excludeTitle?, excludeText?), 'UInt', 2)   ; get monitor handle from window specified
    }

     static NumberFromHandle(handle) {                           ; convert handle to monitor number and return it
        list := this.__GetMonitorHandleList()
        loop parse, list, '`n' {                                ; loop list of monitor handle numbers
            if A_LoopField = handle {                           ; if the handle number matches the monitor handle specified
                return A_Index                                  ; return that index
            }
        }
        throw Error('Monitor not found.')
    }

     static __GetMonitorHandleList() {
        monHandleList := ''
        monCallback := CallbackCreate(EnumMonitors, 'Fast', 4)  ; fast-mode, 4 parameters

        if this.EnumerateDisplays(monCallback) {                ; enumerates all monitors
            monHandleList := SubStr(monHandleList, 1, -1)       ; remove last newline character
            CallbackFree(monCallback)                           ; free callback from memory
            return monHandleList                                ; return list
        }

        EnumMonitors(hMonitor, hDevCon, pRect, args) {          ; callback function for enumeration DLL
            monHandleList .= hMonitor '`n'                      ; add monitor handle number to list
            return true                                         ; continues enumeration
        }
    }

    static EnumerateDisplays(callback) => DllCall('EnumDisplayMonitors', 'Ptr', 0, 'Ptr', 0, 'Ptr', callback, 'UInt', 0)
}
;

; ============================================================================================
; @Measure_Function_in_ms
; ============================================================================================
MeasureFunction(Callback, iterations := 1) {
    DllCall('QueryPerformanceFrequency', 'Int64*', &freq := 0)
    DllCall('QueryPerformanceCounter', 'Int64*', &counterBefore := 0)
    loop iterations {
        Callback()
    }
    DllCall('QueryPerformanceCounter', 'Int64*', &counterAfter := 0)
    MsgBox((counterAfter - counterBefore) / freq * 1000 ' ms')
}


TimedToolTip(text := '', x := 0, y := 0, whichToolTip := 1, timeout := 3000) {
    static tips := Map()

    if not tips.Has(text) {
        tips.Set(text, Map(
                'Show', ToolTip.Bind(text, x, y, whichToolTip),
                'Hide', ToolTip.Bind(,,, whichToolTip)
            )
        )
    }

    tips[text]['Show']()
    SetTimer(tips[text]['Hide'], -timeout)
}


ToolTipDarkMode(text := '', x?, y?, whichToolTip := 1) {
    (!IsSet(x) and x := (MouseGetPos(&mX, &mY), mX))
    (!IsSet(y) and y := mY)

    tt := {
        text: text,
        x: x,
        y: y,
        whichToolTip: whichToolTip,
        id: ToolTip(text, x, y, whichToolTip),
        DarkMode: EnableDarkMode,
        LightMode: DisableDarkMode,
        Update: UpdateToolTip
    }

    tt.DarkMode()
    return tt

    UpdateToolTip(tt, text := tt.text, x := tt.x, y := tt.y, whichToolTip := tt.whichToolTip) => ToolTip(text, x, y, whichToolTip)
    EnableDarkMode(tt) => DllCall('uxtheme\SetWindowTheme', 'Ptr', tt.id, 'Ptr', StrPtr('DarkMode_Explorer'), 'Ptr', 0)
    DisableDarkMode(tt) => DllCall('uxtheme\SetWindowTheme', 'Ptr', tt.id, 'Ptr', StrPtr('LightMode_Explorer'), 'Ptr', 0)
}


;============================================================================================
; @KeyIsMultiTapped
; @GetMultiTapCount
;============================================================================================
/**
 * Check for multi-taps in the middle of code
 * @examples
    z:: {
        if KeyIsMultiTapped(4) {
            MsgBox('success')
        } else {
            ToolTip('failed')
        }
        KeyWait('z')
    }
    x:: {
        taps := GetMultiTapCount(5)
        ToolTip(taps)
        KeyWait('x')
    }
 */
; returns true if key was multi-tapped x amount of times
KeyIsMultiTapped(limit, tapping_term?) => __CheckForTaps('success', limit, tapping_term?)

; returns the amount of multi-taps in case you want to determine something case-by-case
GetMultiTapCount(limit, tapping_term?) => __CheckForTaps('count', limit, tapping_term?)

; determines how many times a key was tapped within the tapping term
__CheckForTaps(count_or_success, limit, tapping_term := 300) {
    key := RegExReplace(A_ThisHotkey, '[~*$!^+#<>]')  ; remove modifiers from simple hotkey
    tapping_term /= 2000
    taps := 1

    while taps < limit {
        if !(KeyIsReleased(key, tapping_term) and KeyIsPressed(key, tapping_term)) {
            break
        }
        taps++
    }
    return (count_or_success = 'count' ? taps : taps = limit)

    KeyIsReleased(key, hold_time) => KeyWait(key, 'T' hold_time)
    KeyIsPressed(key,  wait_time) => KeyWait(key, 'D T' wait_time)
}


;============================================================================================
; @KeyTapHold
;============================================================================================
/**
 * @KeyTapHold
 * @example
 */
; *z:: {
;     KeyTapHold(300, ; duration
;         (on_off) {
;             on_off ? Send('{Blind}{LShift downR}') : Send('{Blind}{LShift up}')
;         },
;         (bool) {
;             bool ? Send('{Blind}{LCtrl downR}') : Send('{Blind}{LCtrl up}')
;         }
;     )
; }

/**
 * @param {integer} tapping_term time (in ms) for key to be released and pressed again to count as another tap
 * @param {func} Callbacks callbacks accept one parameter that can be 1 or 0 (true or false)
 * Using the hotkey above, this function allows you to hold down 'z' to hold down Shift, double-tap hold 'z' to hold down Control
 */
KeyTapHold(tapping_term := 300, Callbacks*) {
    hold_time := tapping_term / 1000
    ThisHotkey := RegExReplace(A_ThisHotkey, '[~*$!^+#<>]|\sup')
    limit := Callbacks.length
    taps  := 1

    while taps <= limit {
        Callback := Callbacks[taps]
        Callback(true)
        start := A_TickCount

        if KeyWait(ThisHotkey, 'T' hold_time) {
            remaining_time := tapping_term - (A_TickCount - start)

            if KeyWait(ThisHotkey, 'D T' remaining_time/1000) {
                taps++
                Callback(false)
                continue
            }
        }
        break
    }

    KeyWait(ThisHotkey)
    Callback(false)
}


;============================================================================================
; @CheckForMultiTap
;============================================================================================
/**
 * Works but couldn't get multiple hotkeys to immediately cancel each other out when tried to account for it
 * Similar to @KeyIsMultiTapped but will fail if another key is pressed before reaching limit or timeout
 * @param {Integer} limit how many taps are required to return true
 * @param {Integer} tapping_term how long between each tap before it times out and returns false
 * @example
    ; c:: {
    ;     if CheckForMultiTap(3) {
    ;         ToolTip('Done at: ' FormatTime(20050423220133, "hh:mm:ss tt"))
    ;     } else {
    ;         ToolTip('Failed to meet tap count.')
    ;     }
    ; }

    ; v:: {
    ;     ToolTip(CheckForMultiTap(4) ? 'Done at: ' FormatTime(20050423220133, "hh:mm:ss tt")
    ;                                 : 'Key failed to be tapped 4 times.')
    ; }
 */
CheckForMultiTap(limit, tapping_term := 300) {
    tapping_term /= 1000
    key := RegExReplace(A_ThisHotkey, '[~*$!^+#<>]|\sup')
    taps := 1

    ih := InputHook('V I H T' tapping_term)
    ih.KeyOpt('{All}', 'E')
    ih.KeyOpt(key, '-E')
    ih.KeyOpt(key, 'NS')

    ih.OnKeyDown := (ih, *) {
        ih.Timeout := tapping_term
        ++taps = limit and ih.Stop()
    }

    ih.Start()
    ih.Wait()
    return taps = limit
}


;============================================================================================
; @Remap_Multiple_Keys_to_One_Key
;============================================================================================
MultiRemap(ThisHotkey, keys*) {
    for key in keys {
        keys_down .= '{' key ' downR}'
        keys_up   .= '{' key ' up}'
    }

    mods := RegExReplace(ThisHotkey, '[^!#+^]+')
    blind := '{Blind' mods '}'

    Hotkey('*' ThisHotkey, Remap.Bind(keys_down))
    Hotkey('*' ThisHotkey ' up', Remap.Bind(keys_up))

    Remap(keys, *) {
        SetKeyDelay(-1)
        Send(blind . keys)
    }
}


;============================================================================================
; @Find_Text_On_Line
;============================================================================================
/**
 * @param {int} count the nth occurrence to find
 * @param {int} direction should only be 1 or -1 (forward/backward aka right/left respectively)
 * @param {bool} case_sense whether case sensitivity should be used in the search
 * @param {func} ActionWhenFound the action to perform when the text searched for is found
 */
SearchTypedText(count, direction, case_sense, char_limit := 0, ActionWhenFound) {
    Display('Text to search for...',, false)
    char_limit := (char_limit > 0 ? 'L' char_limit : '')

    ih := InputHook(char_limit, '{Enter}{Esc}')                                        ; setup input hook
    ih.VisibleNonText := false
    ih.NotifyNonText := true
    ih.KeyOpt('{All}', 'N')                                                     ; all keys trigger OnKeyDown
    ih.OnChar := (*) => Display(ih.Input,, false)                               ; all keys update display
    ih.OnKeyDown := (*) => Display(ih.Input,, false)                               ; all keys update display
    ih.Start(), ih.Wait()                                                       ; start input and wait until finished

    if ih.EndKey = 'Escape' or ih.Input = '' {                                  ; if Escape ended input or empty string
        Display('Search canceled', 'ff9d00')                                    ; display canceled message
        return                                                                  ; cancel search
    }

    prev_clip := A_Clipboard                                                    ; save previous clipboard
    A_Clipboard := ''                                                           ; clear clipboard
    switch direction {
    case 1:  Send('+{End}^c{Left}')                                             ; copy text to end of line
    case 0:  Send('{End}+{Home}^c{Left}')                                       ; copy all text on line
    case -1: Send('+{Home}^c{Right}')                                           ; copy text to beginning of line
    }

    if not ClipWait(2) {                                                        ; wait for clipboard to be updated
        return Display('Failed to copy', 'ff9d00')                              ; display error if failed
    }

    if pos := InStr(A_Clipboard, ih.Input,,, count*direction or count) {
        Display('Match found: ' ih.Input, '00c3ff')                         ; turn input blue and hide it
        ActionWhenFound(pos)
    } else {
        Display('Not found: ' ih.Input, 'ff9d00')                           ; turn input blue and hide it
    }

    A_Clipboard := prev_clip
}


;============================================================================================
; @Find_Text_On_Line_And_Do_Action
;============================================================================================
GoToTextOnLine(count, case_sense := false) {
    SearchTypedText(
        count, 0, case_sense,,
        (pos) {
            Send('{Blind}{Right ' pos-1 '}')
        }
    )
}

GoToTextRightOfCursor(count, case_sense := false) {
    SearchTypedText(
        count, 1, case_sense,, (pos) => Send('{Blind}{Right ' pos-1 '}')
    )
}

GoToTextLeftOfCursor(count, case_sense := false) {
    SearchTypedText(
        count, -1, case_sense,, (pos) => Send('{Blind}{Left ' (StrLen(A_Clipboard) - pos + 1) '}')
    )
}

RemoveCharToRight(count, case_sense := false) {
    SearchTypedText(
        count, 1, case_sense, 1, (pos) => Send('{Right ' pos '}{BackSpace}{Left ' pos-1 '}')    ; go to position of letter, delete it, go back to original position
    )
}

RemoveCharToLeft(count, case_sense := false) {
    SearchTypedText(
        count, -1, case_sense, 1,
        (pos) {
            pos := StrLen(A_Clipboard) - pos                    ; get position of character to backspace until
            Send('{Left ' pos '}{BackSpace}{Right ' pos '}')    ; go to position of letter, delete it, go back to original position
        }
    )
}

DeleteToChar(count, include_letter := true, case_sense := false) {
    SearchTypedText(
        count, 1, case_sense, 1,
        (pos) {
            pos += (include_letter ? 0 : -1)    ; get position of character to delete until
            Send('{Delete ' pos '}')            ;
        }
    )
}

DeleteToString(count, include_letter := true, case_sense := false) {
    SearchTypedText(
        count, 1, case_sense,,
        (pos) {
            pos += (include_letter ? 0 : -1)    ; get position of character to delete until
            Send('{Delete ' pos '}')            ;
        }
    )
}

BackSpaceToChar(count, include_letter := true, case_sense := false) {
    SearchTypedText(
        count, -1, case_sense, 1,
        (pos) {
            pos := StrLen(A_Clipboard) - (pos - include_letter) ; get position of character to backspace until
            Send('{BackSpace ' pos '}')                         ; backspace to char pressed
        }
    )
}

BackSpaceToString(count, include_letter := true, case_sense := false) {
    SearchTypedText(
        count, -1, case_sense,,
        (pos) {
            pos := StrLen(A_Clipboard) - (pos - include_letter) ; get position of character to backspace until
            Send('{BackSpace ' pos '}')                         ; backspace to char pressed
        }
    )
}


;============================================================================================
; @Copy_Paste
;============================================================================================
Copy(timeout := 3) {
    A_Clipboard := ''                   ; empty clipboard
    Send('^c')                          ; copy highlighted text
    return ClipWait(timeout)            ; wait for clipboard to have information
}


; currently not used, thought it was a neat idea
; but didn't like the delay when pasting a single item
PasteIndexByTapCount() {
    ; press key x times to paste xᵗʰ item from clipboard
    static presses := 0
    presses += 1

    ; show a tooltip of current item to be pasted and the next two
    ToolTip(presses   '. ' ClipboardHistory.GetHistoryItemText(presses)   '`n'
            presses+1 '. ' ClipboardHistory.GetHistoryItemText(presses+1) '`n'
            presses+2 '. ' ClipboardHistory.GetHistoryItemText(presses+2))

    ; timer resets with each press to give you time to continue pressing if your item is far down the list
    SetTimer(After250ms, -250)

    After250ms() {
        if ClipboardHistory.PutHistoryItemIntoClipboard(presses) {
            Send('^v')
        }
        presses := 0
        ToolTip()
    }
}

;============================================================================================
; @Spam
;============================================================================================
Spam(key := RegExReplace(A_ThisHotkey, '[~*$!^+#<>]|\sup'), interval := 100) {
    static saved_spams := Map()                                     ; initialize map

    if not saved_spams.Has(key) {                                   ; if spam wasn't started
        saved_spams.Set(key, Map(                                   ; save spammer
            'spam',     Send.Bind('{' key '}'),                     ; saves key to send
            'interval', interval                                    ; saves interval
        ))
        return SetTimer(saved_spams[key]['spam'], interval)         ; start spam
    }

    spammer := saved_spams[key]                                     ; temp save spammer for fewer map accessings

    spammer['interval'] != interval and interval != 0               ; if different interval passed that isn't zero
    ?   SetTimer(spammer['spam'], spammer['interval'] := interval)  ; update interval and timer
    :   SetTimer(saved_spams.Delete(key)['spam'], 0)                ; else turn off spam
}


;============================================================================================
; @Character_Count
;============================================================================================
CharacterCount() {
    thePreviousItem := ClipboardHistory.GetHistoryItemText(1)

    if not Copy() {                                 ; copy highlighted text
        return MsgBox('failed to copy text')        ; show error if it fails to copy something
    }

    try MsgBox(StrLen(Trim(A_Clipboard, ' `t`r`n')))

    if A_Clipboard = thePreviousItem {              ; clipboard doesn't get updated if the value is the same (Windows 11)
        return                                      ; so this prevents deleting older items
    }

    ClipboardHistory.DeleteHistoryItem(1)           ; delete item just copied
    ClipboardHistory.PutHistoryItemIntoClipboard(1) ; put the previous copied item back, ready to be pasted
}


;============================================================================================
; @Untoggle_CapsLock
;============================================================================================
CapsLockOffTimer() {
    if not GetKeyState('CapsLock', 'T') {
        return
    }
    ; if capslock is toggled and not being physically pressed down,
    ; turn off capslock if no keys are pressed in at least 400ms
    if A_TimeIdleKeyboard >= 800 {
        SetCapsLockState('Off')
    } else {
        SetTimer(CapsLockOffTimer, -100)
    }
}


/**
 * @author descolada
 * @credit plankoe (https://www.reddit.com/r/AutoHotkey/comments/ysuawq/get_the_caret_location_in_any_program/)
 * Gets the position of the caret with UIA, Acc, Java Access Bridge, or CaretGetPos.
 * @param X Value is set to the screen X-coordinate of the caret
 * @param Y Value is set to the screen Y-coordinate of the caret
 * @param W Value is set to the width of the caret
 * @param H Value is set to the height of the caret
 * This implementation prefers CaretGetPos > Acc > JAB > UIA. This is mostly due to speed differences between the methods
 *      and statistically it seems more likely that the UIA method is required the least (Chromium apps support Acc as well).
 */
GetCaretPos(&X?, &Y?, &W?, &H?) {
    ; Default caret
    savedCaret := CoordMode('Caret', 'Screen')
    CaretGetPos(&X, &Y)
    CoordMode('Caret', savedCaret)

	if IsInteger(X) && (X | Y) != 0 {
		W := 4, H := 20
		return
	}

    ; Acc caret
    static _ := DllCall('LoadLibrary', 'Str','oleacc', 'Ptr')
    try {
        idObject := 0xFFFFFFF8 ; OBJID_CARET
        if DllCall('oleacc\AccessibleObjectFromWindow', 'ptr', WinExist('A'), 'uint',idObject &= 0xFFFFFFFF
            , 'ptr',-16 + NumPut('int64', idObject == 0xFFFFFFF0 ? 0x46000000000000C0 : 0x719B3800AA000C81, NumPut('int64', idObject == 0xFFFFFFF0 ? 0x0000000000020400 : 0x11CF3C3D618736E0, IID := Buffer(16)))
            , 'ptr*', oAcc := ComValue(9,0)) = 0 {
            x:=Buffer(4), y:=Buffer(4), w:=Buffer(4), h:=Buffer(4)
            oAcc.accLocation(ComValue(0x4003, x.ptr, 1), ComValue(0x4003, y.ptr, 1), ComValue(0x4003, w.ptr, 1), ComValue(0x4003, h.ptr, 1), 0)
            X:=NumGet(x,0,'int'), Y:=NumGet(y,0,'int'), W:=NumGet(w,0,'int'), H:=NumGet(h,0,'int')
            if (X | Y) != 0
                return
        }
    }

	static JAB := InitJAB() ; Source: https://github.com/Elgin1/Java-Access-Bridge-for-AHK
	if JAB && (hWnd := WinExist('A')) && DllCall(JAB.module '\isJavaWindow', 'ptr', hWnd, 'CDecl Int') {
		if JAB.firstRun {
			Sleep(200)
            JAB.firstRun := 0
        }

		prevThreadDpiAwarenessContext := DllCall('SetThreadDpiAwarenessContext', 'ptr', -2, 'ptr')
		DllCall(JAB.module '\getAccessibleContextWithFocus', 'ptr', hWnd, 'Int*', &vmID:=0, JAB.acType '*', &ac:=0, 'Cdecl Int') '`n'
		DllCall(JAB.module '\getCaretLocation', 'Int', vmID, JAB.acType, ac, 'Ptr', Info := Buffer(16,0), 'Int', 0, 'Cdecl Int')
		DllCall(JAB.module '\releaseJavaObject', 'Int', vmId, JAB.acType, ac, 'CDecl')
		DllCall('SetThreadDpiAwarenessContext', 'ptr', prevThreadDpiAwarenessContext, 'ptr')

		X := NumGet(Info, 0, 'Int'), Y := NumGet(Info, 4, 'Int'), W := NumGet(Info, 8, 'Int'), H := NumGet(Info, 12, 'Int')
		hMonitor := DllCall('MonitorFromWindow', 'ptr', hWnd, 'int', 2, 'ptr') ; MONITOR_DEFAULTTONEAREST
    	DllCall('Shcore.dll\GetDpiForMonitor', 'ptr', hMonitor, 'int', 0, 'uint*', &dpiX:=0, 'uint*', &dpiY:=0)

		if dpiX {
			X := DllCall('MulDiv', 'int', X, 'int', dpiX, 'int', 96, 'int')
            Y := DllCall('MulDiv', 'int', Y, 'int', dpiX, 'int', 96, 'int')
        }

		if X || Y || W || H {
			return
        }
	}

    ; UIA caret
    static IUIA := ComObject('{e22ad333-b25f-460c-83d0-0581107395c9}', '{34723aff-0c9d-49d0-9896-7ab52df8cd8a}')
    try {
        ComCall(8, IUIA, 'ptr*', &FocusedEl:=0) ; GetFocusedElement
		/*
			The current implementation uses only TextPattern GetSelections and not TextPattern2 GetCaretRange.
			This is because TextPattern2 is less often supported, or sometimes reports being implemented
			but in reality is not. The only downside to using GetSelections is that when text
			is selected then caret position is ambiguous. Nevertheless, in those cases it most
			likely doesn't matter much whether the caret is in the beginning or end of the selection.

			If GetCaretRange is needed then the following code implements that:
			ComCall(16, FocusedEl, 'int', 10024, 'ptr*', &patternObject:=0), ObjRelease(FocusedEl) ; GetCurrentPattern. TextPattern2 = 10024
			if patternObject {
				ComCall(10, patternObject, 'int*', &IsActive:=1, 'ptr*', &caretRange:=0), ObjRelease(patternObject) ; GetCaretRange
				ComCall(10, caretRange, 'ptr*', &boundingRects:=0), ObjRelease(caretRange) ; GetBoundingRectangles
				if (Rect := ComValue(0x2005, boundingRects)).MaxIndex() = 3 { ; VT_ARRAY | VT_R8
					X:=Round(Rect[0]), Y:=Round(Rect[1])
                    W:=Round(Rect[2]), H:=Round(Rect[3])
					return
				}
			}
		*/
        ComCall(16, FocusedEl, 'int', 10014, 'ptr*', &patternObject:=0), ObjRelease(FocusedEl) ; GetCurrentPattern. TextPattern = 10014
        if patternObject {
            ComCall(5, patternObject, 'ptr*', &selectionRanges:=0), ObjRelease(patternObject) ; GetSelections
			ComCall(4, selectionRanges, 'int', 0, 'ptr*', &selectionRange:=0) ; GetElement
			ComCall(6, selectionRange, 'int', 0) ; ExpandToEnclosingUnit = Character
            ComCall(10, selectionRange, 'ptr*', &boundingRects:=0), ObjRelease(selectionRange), ObjRelease(selectionRanges) ; GetBoundingRectangles

            if (Rect := ComValue(0x2005, boundingRects)).MaxIndex() = 3 { ; VT_ARRAY | VT_R8
                X := Round(Rect[0]), Y := Round(Rect[1])
                W := Round(Rect[2]), H := Round(Rect[3])
                return
            }
        }
    }

	InitJAB() {
		ret := {}, ret.firstRun := 1, ret.module := A_PtrSize = 8 ? 'WindowsAccessBridge-64.dll' : 'WindowsAccessBridge-32.dll', ret.acType := 'Int64'
		ret.DefineProp('__Delete', {call: (this) => DllCall('FreeLibrary', 'ptr', this)})
		if !(ret.ptr := DllCall('LoadLibrary', 'Str', ret.module, 'ptr')) && A_PtrSize = 4 {
            ; try legacy, available only for 32-bit
            ret.acType := 'Int'
            ret.module := 'WindowsAccessBridge.dll'
            ret.ptr := DllCall('LoadLibrary', 'Str', ret.module, 'ptr')
		}

		if !ret.ptr {
			return ; Failed to load library. Make sure you are running the script in the correct bitness and/or Java for the architecture is installed.
        }

		DllCall(ret.module '\Windows_run', 'Cdecl Int')
		return ret
	}
}


Eval(str) {
    shell := ComObject('WScript.Shell')
    exec := shell.Exec(A_AhkPath ' /ErrorStdOut *')
    exec.stdin.Write('#NoTrayIcon`nFileAppend(' str ', "*")')
    exec.StdIn.Close()
    return exec.StdOut.ReadAll()
}



; basic deep clone
DeepClone(obj) {
    if obj is Map {
        clone := Map()
        for key, val in obj
        clone[key] := DeepClone(val)
        return clone
    }
    if obj is Array {
        clone := []
        for index, val in obj {
            clone.Push(DeepClone(val))
        }
        return clone
    }
    return obj
}

; @description - can be used to find a single missing number between two arrays
; MsgBox(XOR_MissingNumber([1, 2, 3, 4, 5], [1, 2, 4, 5]))
XOR_MissingNumber(arr1, arr2) {
    var1 := XOR(arr1)
    var2 := XOR(arr2)
    return var1 ^ var2

    XOR(arr) {
        local sum := 0
        for value in arr {
            sum ^= value
        }
        return sum
    }
}

; @description - can be used to find a single duplicate number in an array
; someArray := []
; loop 100 {
;     someArray.Push(A_Index)
; }
; randomValue := Random(1, 100)
; someArray.Push(randomValue)
; RandomArrayOfNumbers := RandomizeArray(someArray)
; MsgBox(XOR_FindDuplicateNumber(RandomArrayOfNumbers, 1, 100))
XOR_FindDuplicateNumber(arr, min := 1, max := 100) {
    local x := 0
    loop max - min + 1 {
        x ^= (min + A_Index - 1)
    }

    for value in arr {
        x ^= value
    }
    return x
}

; @returns new array
; *slightly* faster than in-place version
RandomizeNewArray(arr) {
    temp := []
    loop arr.length {
        temp.Push(A_Index)
    }

    newArray := []
    loop temp.Length {
        length := temp.Length
        index := temp.RemoveAt(Random(1, length))
        value := arr[index]
        newArray.Push(value)
    }

    return newArray
}

; in-place randomization
RandomizeArray(arr) {
    len := arr.Length
    loop len-1 {
        Swap(A_Index, Random(A_Index, len))
    }

    Swap(a, b) {
        temp := arr[b]
        arr[b] := arr[a]
        arr[a] := temp
    }
}

/**
 * Joins an array of strings together
 * @source https://www.autohotkey.com/boards/viewtopic.php?f=82&t=137950&sid=0bcb47c93a1e2f05d0a59855105e3d7c
 * arr := ["a","b","c","d","e"]
 * @param {Array} arr The array of strings to combine.
 * @param {String} delim The character delimiter to separate strings with.
 * Reformatted for better readability
 */
Join(arr, delim := '') {
    placeholders    := Format('{:' arr.length '}', '')              ; adds arr.Length amount of spaces to a string
    formatTemplate  := StrReplace(placeholders, ' ', '{}' . delim)  ; replace all spaces with {} Format variable placeholders
    result          := Format(formatTemplate, arr*)                 ; place easy array value into string in order
    return SubStr(result, 1, -StrLen(delim))                        ; remove last delimiter
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

/**
 * @plankoe @swagfag
 * @source https://old.reddit.com/r/AutoHotkey/comments/11dnz2l/enumerating_via_for_key_value_in_var_out_of/jaaknw6/
 */
class OrderedMap extends Map {
    __New(KVPairs*) {
        super.__New(KVPairs*)
        KeyArray := []
        keyCount := KVPairs.Length // 2
        KeyArray.Length := keyCount
        Loop keyCount
            KeyArray[A_Index] := KVPairs[(A_Index << 1) - 1]
        this.KeyArray := KeyArray
    }

    __Item[key] {
        set {
            if !this.Has(key)
                this.KeyArray.Push(key)
            super[key] := value
        }
    }

    Clear() {
        super.Clear()
        this.KeyArray := []
    }

    Clone() {
        Other := super.Clone()
        Other.KeyArray := this.KeyArray.Clone()
        return Other
    }

    Delete(key) {
        try {
            RemovedValue := super.Delete(key)
            CaseSense := this.CaseSense
            for i, Element in this.KeyArray {
                areSame := (Element is String)
                    ? !StrCompare(Element, key, CaseSense)
                    : (Element = key)
                if areSame {
                    this.KeyArray.RemoveAt(i)
                    break
                }
            }
            return RemovedValue
        }
        catch UnsetItemError as Err
            throw UnsetItemError(Err.Message, -1, Err.Extra)
    }

    Set(KVPairs*) {
        if (KVPairs.Length & 1)
            throw ValueError('Invalid number of parameters.', -1)
        KeyArray := this.KeyArray
        keyCount := KVPairs.Length // 2
        KeyArray.Capacity += keyCount
        Loop keyCount {
            key := KVPairs[(A_Index << 1) - 1]
            this.Has(key) || KeyArray.Push(key)
        }
        super.Set(KVPairs*)
        return this
    }

    __Enum(*) {
        keyEnum := this.KeyArray.__Enum(1)
        return (&key?, &val?) => (
            keyEnum(&key) ? (val := this[key], true) : false
        )
    }
}


; Sorting
MergeSort(arr) {
    length := arr.length

    if length = 1 {
        return arr
    }

    midPoint := length // 2
    arr1 := []
    arr2 := []

    loop midPoint {
        arr1.Push(arr[A_Index])
    }
    loop length - midPoint {
        arr2.Push(arr[A_Index+midPoint])
    }

    leftHalf  := MergeSort(arr1)
    rightHalf := MergeSort(arr2)

    return Merge(leftHalf, rightHalf)

    Merge(left, right) {
        output := []
        i := j := 1
        leftLength  := left.Length
        rightLength := right.Length

        while i <= leftLength && j <= rightLength {
            if left[i] <= right[j] {
                output.Push(left[i])
                i += 1
            } else {
                output.Push(right[j])
                j += 1
            }
        }

        while i <= leftLength {
            output.Push(left[i])
            i++
        }
        while j <= rightLength {
            output.Push(right[j])
            j++
        }

        return output
    }
}


; class Color {
;     __New(color, g?, b?) {
;         this.Parse(color, g?, b?)
;     }

;     Parse(color, g?, b?) {
;         return IsRGB()
;             || Is0xRGB()
;             || Is0xARGB()
;             || IsRGBString()
;             || throw(Error('Invalid color passed.'))

;         IsRGB() {         ; 255, 255, 255
;             if IsSet(g) {
;                 if !IsSet(b) {
;                     throw Error('Missing color: Blue')
;                 } else {
;                     this._color := {r: color, g: g, b: b}
;                     this._format := 'RGB'
;                     return true
;                 }
;             } else if IsSet(b) {
;                 throw Error('Missing color: Green')
;             }
;         }

;         Is0xRGB() {       ; 0xFF0033

;         }

;         Is0xARGB() {      ; 0xFFFF0033

;         }

;         IsRGBString() {   ; 'FF0033' or 'cFF0033'
;             if !(color is String) {
;                 return
;             }

;             if SubStr(color, 1) = 'c' {
;                 color := SubStr(color, 2)
;             }

;             if StrLen(color) != 6 {                            ; if it's a hex string (not a raw number)
;                 return
;             }

;             this._color := color
;             this._format := 'RGBString'
;             return true
;         }
;     }

;     To0xRGB() {

;     }

;     /**
;      * @param {hex} @color1
;      * @param {hex} @color2
;      * @returns {}
;      * @example
;      * if CompareColors(0x1f1f24, 0x1f1f28) < 10 {
;      *     ; do something
;      * }
;      */
;     CompareTo(color) => Abs(color - this._color)

;     /**
;      * Returns the colors black or white, depending on the color passed.
;      * It chooses based on what color should have better visibility against the given color.
;      * @param backgroundColor
;      * @returns {Integer 0xARGB}
;      */
;     static GetContrastingHexColor(color) {
;         r := (color >> 16) & 0xFF
;         g := (color >> 8)  & 0xFF
;         b := color & 0xFF

;         brightness := GetColorLuminance(color)

;         return brightness < 128 ? 0xFFFFFFFF : 0xFF000000  ; white text for dark backgrounds, black for light
;     }

;     /**
;      * Takes a color of type string or RGB and converts it to ARGB
;      * @param color
;      * @returns {Integer | Number | String}
;      */
;     static StringToHex(color) {
;         switch StrLen(color) {                      ; check string length
;         case 6:     return Integer('0xFF' . color)  ; if 6 numbers
;         case 8:     return Integer('0x' color)      ; if 8 numbers
;         case 10:    return Integer(color)           ; if 10 numbers
;         default:    return color                    ; otherwise, return it as is
;         }
;     }

;     static RGBtoARGB(color) {
;         color := color & 0xFFFFFFFF
;         return color | 0xFF000000
;         return Number('0x' Format('{:02X}{:02X}{:02X}', r & 0xFF, g & 0xFF, b & 0xFF))
;     }

;     static EnsureHexHasAlpha(color) {
;         if !((color >> 24) & 0xFF000000) {          ; if no alpha (full transparency)
;             return color & 0x00FFFFFF | 0x01000000  ; add 1 alpha
;         }
;         return color
;     }

;     static HexToString(color) {
;         return Format('{:08X}', color & 0xFFFFFFFF)
;     }

;     /**
;      * @description
;      * Expects an 0xARGB color that will automatically brighten or darken depending on whether it is already considered bright or dark.
;      * This function was created with the intent of highlighting something. So if there was a gui element I wanted to accentuate,
;      *      I could pass that color to this function and it would automatically return a brighter or darker version.
;      * @param color
;      * @returns {Number 0xARGB}
;      */
;     static ColorBrightnessAutoAdjust(color, offset := 60) {
;         r := (color >> 16) & 0xFF
;         g := (color >> 8) & 0xFF
;         b := color & 0xFF

;         ; standard luminance formula
;         brightness := GetColorLuminance(color)

;         if (brightness > 170) {     ; if color is already bright, use a dark highlight
;             r := Max(0, r - offset)
;             g := Max(0, g - offset)
;             b := Max(0, b - offset)
;         } else {                    ; if color is dark, brighten it
;             r := Min(255, r + offset)
;             g := Min(255, g + offset)
;             b := Min(255, b + offset)
;         }

;         return (0xFF << 24) | (r << 16) | (g << 8) | b  ; keep full opacity
;     }

;     /**
;      * @description
;      * Expects an 0xARGB color and an amount to adjust the color.
;      * Positive values increase color brightness. Negative decrease color brightness.
;      * @param color
;      * @param offset
;      * @returns {Number 0xARGB}
;      */
;     static ColorBrightnessAdjust(color, offset := 60) {
;         ; extract ARGB components
;         a := (color >> 24) & 0xFF
;         r := ((color >> 16) & 0xFF) + offset
;         g := ((color >> 8) & 0xFF) + offset
;         b := (color & 0xFF) + offset

;         ; clamp values
;         r := Max(0, Min(255, r))
;         g := Max(0, Min(255, g))
;         b := Max(0, Min(255, b))

;         ; recombine
;         return (a << 24) | (r << 16) | (g << 8) | b
;     }

;     static GetColorLuminance(color) {
;         r := (color >> 16) & 0xFF
;         g := (color >> 8) & 0xFF
;         b := color & 0xFF

;         ; standard luminance formula
;         return  (r * 0.299 + g * 0.587 + b * 0.114)
;     }

;     static GetBrightnessFromRGB(r, g, b) {
;         return sqrt(0.299 * r ** 2 + 0.587 * g ** 2 + 0.114 * b ** 2)
;     }
; }





; ============================================================
; Public entry point — grabs a Steam link + player-support tag
; for the currently picked game and copies it to the clipboard.
; ============================================================
GetTemplateForDemoReviews() {
    appId := SteamGamePicker.Show()
    if (appId = "") {
        ToolTip("Cancelled / Not Found")
        SetTimer(() => ToolTip(), -2000)
        return
    }

    steamUrl := "https://store.steampowered.com/app/" . appId . "/"
    info := SteamAPI.GetAppInfo(appId)
    result := FormatTemplate()

    A_Clipboard := result
    ToolTip("Copied!")
    SetTimer(() => ToolTip(), -2000)

    FormatTemplate() {
        verdict := "### ``Verdict: ``"
        playerSupport := '*``Players: ' info.PlayerTag '``*'
        access := '*``Access: Demo``*'
        release := '*``Release: ' info.Release '``*'
        notes := '- '
        return Format("# [{1}]({2})`n{3}`n{4} {5} {6}`n{7}`n<br><br>", info.Name, steamUrl, verdict, playerSupport, access, release, notes)
    }
}

; ============================================================
; SteamAPI
; ============================================================
class SteamAPI {

    ; Returns an array of {AppId, Name, ImgSrc} for a search term.
    static Search(query) {
        results := []

        cleanQuery := RegExReplace(query, "[-–—:]", " ")
        encoded := SteamAPI.__EncodeURL(cleanQuery)
        url := "https://store.steampowered.com/search/results/?term=" . encoded . "&f=games&cc=US&l=english"

        html := SteamAPI.__HttpGet(url)

        seen := Map()
        pos := 1
        while RegExMatch(html, "s)<a\s[^>]*search_result_row[^>]*>.*?</a>", &rowMatch, pos) {
            pos := rowMatch.Pos(0) + rowMatch.Len(0)
            row := rowMatch[0]

            if !RegExMatch(row, 'data-ds-appid="(\d+)"', &idMatch)
                continue
            if !RegExMatch(row, '<span class="title">([^<]+)</span>', &titleMatch)
                continue

            appId := idMatch[1]
            if seen.Has(appId)
                continue
            seen[appId] := true

            name := titleMatch[1]
            name := StrReplace(name, "&amp;", "&")
            name := StrReplace(name, "&apos;", "'")
            name := StrReplace(name, "&quot;", '"')
            name := StrReplace(name, "&#39;", "'")

            imgSrc := ""
            if RegExMatch(row, '<img[^>]+src="([^"]+)"', &imgMatch)
                imgSrc := imgMatch[1]
            else
                imgSrc := "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/" . appId . "/capsule_184x69.jpg"

            results.Push({ AppId: appId, Name: name, ImgSrc: imgSrc })

            if results.Length >= 15
                break
        }

        return results
    }

    ; Returns {Name, PlayerTag, Release} for a given app id.
    static GetAppInfo(appId, fallbackName := "") {
        try {
            json := SteamAPI.__HttpGet("https://store.steampowered.com/api/appdetails?appids=" . appId "&l=english")
        } catch {
            return { Name: (fallbackName != "" ? fallbackName : "Selected Game"), PlayerTag: "" }
        }

        name := fallbackName
        if RegExMatch(json, '"name"\s*:\s*"([^"]+)"', &nameMatch)
            name := StrReplace(nameMatch[1], "\u0027", "'")
        else if (name = "")
            name := "Selected Game"

        return { Name: name, PlayerTag: SteamAPI.__ParsePlayerSupport(json), Release: SteamAPI.__ParseReleaseDate(json) }
    }

    ; ---------------- private ----------------

    static __HttpGet(url) {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.SetTimeouts(5000, 5000, 5000, 5000)
        http.Open("GET", url, false)
        http.setRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        http.Send()
        return http.ResponseText
    }

    static __EncodeURL(str) {
        doc := ComObject("htmlfile")
        doc.write("<meta http-equiv='X-UA-Compatible' content='IE=edge'>")
        return doc.parentWindow.encodeURIComponent(str)
    }

    static __ParseReleaseDate(jsonStr) {
        if RegExMatch(jsonStr, '"release_date"\s*:\s*\{[^}]*?"date"\s*:\s*"([^"]+)"', &dateMatch) {
            ; 1. Remove escaped slashes (\/ -> / or space)
            cleanDate := StrReplace(dateMatch[1], "\/", " ")

            ; Swap day and month to match American date format
            if RegExMatch(cleanDate, "i)^(\d{1,2})\s+([a-z]+)[,\s]+(\d{4})$", &m) {
                return m[2] " " m[1] ", " m[3]
            }

            return cleanDate
        }
        return ""
    }

    static __ParsePlayerSupport(jsonStr) {
        hasSingle := false
        hasPvP := false
        hasOnlineCoop := false
        hasCouchCoop := false

        if RegExMatch(jsonStr, '"categories"\s*:\s*\[(.*?)\]', &catMatch) {
            catArray := catMatch[1]

            ; Steam Category IDs:
            ; 2  = Single-player
            ; 1, 36 = Multi-player / Online PvP
            ; 38 = Online Co-op
            ; 39 = Shared/Split Screen Co-op

            if RegExMatch(catArray, '"id"\s*:\s*2\b')
                hasSingle := true
            if RegExMatch(catArray, '"id"\s*:\s*\b(38)\b')
                hasOnlineCoop := true
            if RegExMatch(catArray, '"id"\s*:\s*\b(39)\b')
                hasCouchCoop := true

            if RegExMatch(catArray, '"id"\s*:\s*\b(36)\b')
                hasPvP := true
            else if (RegExMatch(catArray, '"id"\s*:\s*1\b') && !hasOnlineCoop && !hasCouchCoop) ; this check exists because CS2 only returned categories 1 and 27 (Multi-player and Cross-Platform Multiplayer) so if I included 1 in all checks, Co-op games without PvP would return it has Multi (PvP).
                hasPvP := true
        }

        tags := []
        if (hasSingle)
            tags.Push("Single")

        if (hasOnlineCoop)
            tags.Push("Co-op")
        else if (hasCouchCoop)
            tags.Push("Couch Co-op")

        if (hasPvP)
            tags.Push("Multi")

        if (tags.Length = 0)
            return ""

        tagStr := ""
        for idx, tag in tags
            tagStr .= (idx = 1 ? "" : "/") . tag

        return tagStr
    }
}

; ============================================================
; SteamGamePicker — the GUI. Depends on SteamAPI.
; Returns a chosen app id, or "".
; ============================================================
class SteamGamePicker {

    static __wb := ""
    static __activeHwnd := 0

    ; Registered exactly once, ever. Only "live" while __activeHwnd
    ; matches the currently active window, so nothing needs to be
    ; turned on/off per Show() call.
    static __New() {
        HotIf(ObjBindMethod(SteamGamePicker, "__IsActive"))
        Hotkey("Enter", ObjBindMethod(SteamGamePicker, "__OnEnter"))
        Hotkey("Down", ObjBindMethod(SteamGamePicker, "__OnDown"))
        Hotkey("Up", ObjBindMethod(SteamGamePicker, "__OnUp"))
        HotIf()
    }

    static __IsActive(*) {
        return SteamGamePicker.__activeHwnd != 0 && WinActive("ahk_id " . SteamGamePicker.__activeHwnd)
    }

    static __OnEnter(*) {
        if (SteamGamePicker.__wb != "")
            try SteamGamePicker.__wb.parentWindow.triggerEnter()
    }

    static __OnDown(*) {
        if (SteamGamePicker.__wb != "")
            try SteamGamePicker.__wb.parentWindow.moveSelection(1)
    }

    static __OnUp(*) {
        if (SteamGamePicker.__wb != "")
            try SteamGamePicker.__wb.parentWindow.moveSelection(-1)
    }

    ; Shows the picker GUI. Blocks until a game is chosen or the
    ; window is closed/escaped. Returns the chosen app id, or "".
    static Show(initialQuery := "") {
        chosenAppId := ""
        guiClosed := false

        myGui := Gui("+AlwaysOnTop +ToolWindow", "Steam Search")
        myGui.MarginX := 0
        myGui.MarginY := 0
        myGui.OnEvent("Close", (*) => guiClosed := true)
        myGui.OnEvent("Escape", (*) => guiClosed := true)

        axCtrl := myGui.Add("ActiveX", "w340 h540", "htmlfile")
        wb := axCtrl.Value
        wb.write(SteamGamePicker.__BuildHtmlShell())

        if (initialQuery != "")
            try wb.parentWindow.document.getElementById("search-input").value := initialQuery

        myGui.Show()

        ; Raw .Focus() on the control isn't reliable for this OLE
        ; object — force real UI-activation with a synthetic click
        ; first, then hand focus to the input inside the document.
        ControlClick(axCtrl, myGui)
        Sleep(50)
        try wb.parentWindow.document.getElementById("search-input").focus()

        SteamGamePicker.__wb := wb
        SteamGamePicker.__activeHwnd := myGui.Hwnd

        try {
            if (initialQuery != "")
                SteamGamePicker.__RunSearch(wb, initialQuery)
            else
                try wb.getElementById("container").innerHTML :=
                    "<div style='color:#c6d4df; text-align:center; padding-top:40px; font-size:14px;'>Type a game name above.</div>"

            try wb.parentWindow.highlightFirst()

            lastSeenText := initialQuery
            lastSearchedText := initialQuery
            lastChangeTime := A_TickCount

            while (WinExist("ahk_id " . myGui.Hwnd) && chosenAppId == "" && !guiClosed) {
                try currentVal := wb.parentWindow.selectedId
                catch {
                    currentVal := ""
                }

                if (currentVal != "") {
                    chosenAppId := currentVal
                    break
                }

                ; Debounced auto-search, driven entirely from AHK —
                ; the embedded engine's own JS timers aren't reliable
                ; here, but polling a COM property every tick is.
                try text := Trim(wb.parentWindow.document.getElementById("search-input").value)
                catch {
                    text := lastSeenText
                }

                if (text != lastSeenText) {
                    lastSeenText := text
                    lastChangeTime := A_TickCount
                } else if (text != "" && text != lastSearchedText && (A_TickCount - lastChangeTime) >= 250) {
                    lastSearchedText := text
                    SteamGamePicker.__RunSearch(wb, text)
                }

                Sleep(50)
            }
        } finally {
            SteamGamePicker.__activeHwnd := 0
            SteamGamePicker.__wb := ""
            ToolTip()
            if WinExist("ahk_id " . myGui.Hwnd)
                myGui.Destroy()
        }

        return chosenAppId
    }

    ; ---------------- private ----------------

    static __RunSearch(wb, query) {
        ToolTip("Fetching Steam Data...")
        try {
            results := SteamAPI.Search(query)
            html := SteamGamePicker.__BuildResultsHtml(results)
        } catch {
            html := "<div style='color:#c6d4df; text-align:center; padding-top:40px; font-size:14px;'>Request Failed / Timed Out</div>"
        }
        ToolTip()

        try wb.getElementById("container").innerHTML := html
        try wb.parentWindow.highlightFirst()
    }

    static __BuildResultsHtml(results) {
        if (results.Length = 0)
            return "<div style='color:#c6d4df; text-align:center; padding-top:40px; font-size:14px;'>No games found.</div>"

        html := ""
        for game in results {
            html .= "<div class='game-card' onclick='selectApp(" . game.AppId . ")'>"
            html .= "<div class='img-box'><img src='" . game.ImgSrc . "' onerror='this.style.display=`"none`";'></div>"
            html .= "<div class='title-wrap'><div class='title'>" . game.Name . "</div></div>"
            html .= "<div style='clear:both;'></div>"
            html .= "</div>"
        }
        return html
    }

    static __BuildHtmlShell() {
        return "
        (
        <!DOCTYPE html>
        <html>
        <head>
        <meta http-equiv='X-UA-Compatible' content='IE=edge'>
        <style>
            * { box-sizing: border-box; }
            html, body { background: #1b2838; color: #fff; font-family: sans-serif; margin: 0; padding: 0; overflow: hidden; width: 100%; height: 100%; }

            #search-bar-container { background: #171a21; padding: 10px; border-bottom: 1px solid #2a475e; position: fixed; top: 0; left: 0; width: 100%; z-index: 10; }
            #search-input { width: 100%; padding: 7px 10px; background: #0b0e14; border: 1px solid #2a475e; color: #fff; border-radius: 4px; font-size: 14px; outline: none; }
            #search-input:focus { border-color: #66c0f4; }

            #container { position: absolute; top: 55px; bottom: 0; left: 0; width: 100%; overflow-y: auto; text-align: center; padding: 10px 0; }

            .game-card { background: #171a21; margin: 0 auto 10px auto; padding: 10px; border-radius: 6px; cursor: pointer; border: 1px solid #2a475e; width: 310px; text-align: left; zoom: 1; transition: background 0.1s, border-color 0.1s; }
            .game-card:hover, .game-card.keyboard-focus { background: #2a475e; border-color: #66c0f4; }

            .img-box { float: left; width: 130px; height: 60px; background: #0b0e14; border-radius: 3px; margin-right: 12px; overflow: hidden; position: relative; }
            img { width: 130px; height: 60px; object-fit: cover; display: block; }

            .title-wrap { float: left; width: 144px; height: 60px; display: table; }
            .title { display: table-cell; vertical-align: middle; font-size: 15px; font-weight: bold; color: #c6d4df; line-height: 1.2; word-break: break-word; }
        </style>
        </head>
        <body>
            <div id='search-bar-container'>
                <input type='text' id='search-input' placeholder='Search Steam...' autocomplete='off' />
            </div>
            <div id='container'></div>
            <script>
        )" . SteamGamePicker.__BuildScript() . "
        (
            </script>
        </body>
        </html>
        )"
    }

    ; Isolated on its own so it's easy to edit without wading through the HTML/CSS template around it.
    static __BuildScript() {
        return "
        (
            var selectedId = '';
            var currentIndex = -1;

            function selectApp(id) {
                selectedId = id.toString();
            }

            function moveSelection(direction) {
                try {
                    var cards = document.querySelectorAll('.game-card');
                    if (cards.length === 0) return;

                    if (currentIndex < 0) {
                        currentIndex = 0;
                    } else if (direction === 1) {
                        currentIndex = (currentIndex + 1 < cards.length) ? currentIndex + 1 : 0;
                    } else {
                        currentIndex = (currentIndex - 1 >= 0) ? currentIndex - 1 : cards.length - 1;
                    }

                    setFocusIndex(currentIndex);
                } catch(e) {}
            }

            function triggerEnter() {
                try {
                    var cards = document.querySelectorAll('.game-card');
                    if (cards.length === 0) return;
                    var idx = (currentIndex >= 0 && currentIndex < cards.length) ? currentIndex : 0;
                    cards[idx].click();
                } catch(e) {}
            }

            function setFocusIndex(idx) {
                var cards = document.querySelectorAll('.game-card');
                for (var i = 0; i < cards.length; i++) {
                    cards[i].className = (i === idx) ? 'game-card keyboard-focus' : 'game-card';
                }
                if (cards[idx]) cards[idx].scrollIntoView();
                currentIndex = idx;
            }

            function highlightFirst() {
                var cards = document.querySelectorAll('.game-card');
                currentIndex = (cards.length > 0) ? 0 : -1;
                if (cards.length > 0) setFocusIndex(0);
            }

            window.onload = function() {
                var input = document.getElementById('search-input');
                if (input) input.focus();
            };
        )"
    }
}