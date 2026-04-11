 /************************************************************************
 * @author crash
 * @description     Gets monitor or screen information
 *
 * Classes:
 * @Monitor         Gets the dimensions of the entire screen
 * @Screen          Gets the dimensions of the workarea (takes taskbar into account if it exists on that monitor)
 * @WorkArea        Alias for @Screen
 * @VirtualScreen   Gets the dimensions of the virtual screen
 * @PhysicalMonitor Gets the dimensions of the monitor based on physical location (see its method's comments for how it currently works)
 *
 * Common methods:
 *  FromWindow()    ; returns monitor object from a specified window
 *  FromMouse()     ; returns monitor object from the current mouse position
 *  @returns Monitor (or equivalent) object
 *  Many methods return a Monitor object with various properties for dimensions/coordinates of the monitor
 *
 * If you want a monitor object from a specific monitor, there are 3 main ways:
 *  1. mon := Monitor(1)
 *  2. mon := Monitor.1
 *  3. mon := Monitor[1]
 *  4. mon := Monitor._monitor[1]   ; technical detail (should ignore)
 * Use whichever feels most natural for you.
 *
 * Using Mon(1) has the benefit of setting that monitor object to the most recently accessed.
 * What does that mean?
 * Well, let's say you wanted to set up a few hotkeys and you are adamant on them being one-liners:
 * Instead of saving the monitor object and using that, you could just use Monitor.property and it will use the monitor most recently accessed
 * So this:
 * @example
 * F1:: {
 *  mon := Monitor(1)
 *  WinMove(mon.left, mon.top, mon.width, mon.height//2, 'A')
 * } @ends
 *
 * Becomes:
 * @example
 * F1::WinMove(Monitor(1).left, Monitor.top, Monitor.width, Monitor.height//2, 'A')
 * @end
 *
 * Is this recommended? Probably not. It's probably best to be explicit. But if this is how your brain works, it's an option.
 ***********************************************************************/


; DllCall('SetThreadDpiAwarenessContext', 'Ptr', -3, 'Ptr')   ; obsolete in v2.1 alpha 16?




class VirtualScreen {
    static left   => SysGet(76)
    static top    => SysGet(77)
    static width  => SysGet(78)
    static height => SysGet(79)
    static right  => this.width
    static bottom => this.height
}


class WorkArea extends Screen {
}
class Screen extends Monitor {
    static coords := {}
    static __CoordsFunc => MonitorGetWorkArea

    static __New() {
        this.UpdateMonitorInfo()
    }
}


class PhysicalMonitor extends Monitor {
    static coords := {}

    static __New() {
        this.UpdateMonitorInfo(GetPosition)

        /**
         * Only tested on setup with 3 monitors left-to-right so this may not work as intended.
         *
         * @param {int} @monNumber the monitor number relative to its physical position
         * This only supports two rows of monitors, i.e. you can't have 3 or more monitors stacked on top of each other.
         * Bottom row is read first, left to right, then the top.
         * For example, this is the expected result if you had 6 monitors in a 2x3 formation:
         * 	[4][5][6]
         * 	[1][2][3]
         */
        GetPosition(monNumber) {
            monHandleArray := []                            ; initialize monitor handle number array

            loop MonitorGetCount() {
                MonitorGet(A_Index, &left, &top,, &bottom)
                monHandleArray.Push({handle: A_Index, left: left, top: top, bottom: bottom})
            }

            ArrangeMonitorsInArray(&monHandleArray)         ; if any stack, position the monitor on top to the end of the array
            return monHandleArray[monNumber].handle         ; return monitor number at the index requested

            ; auxillary functions
            ArrangeMonitorsInArray(&array) {
                main := array[1]                            ; save first monitor since that will always be the primary monitor
                array.RemoveAt(1)                           ; delete from array to compare first against the rest
                tolerance := 300                            ; max range top row can fall below main monitor's top value before being considered bottom row

                topArray    := []                           ; temp array for top row of monitors
                bottomArray := []                           ; temp array for bottom row of monitors

                loop array.Length {
                    ; if main monitor's top is higher than the compared monitor's bottom + tolerance
                    if main.top < array[A_Index].bottom + tolerance {
                        bottomArray.Push(array[A_Index])    ; push monitor into bottom row array
                    } else {
                        topArray.Push(array[A_Index])       ; push monitor into top row array
                    }
                }

                bottomArray.Push(main)                      ; push main monitor back into bottom array
                BubbleSort(bottomArray, 'left')             ; sort bottom array, ordering them from left to right
                BubbleSort(topArray, 'left')                ; sort top array, ordering them from left to right

                loop topArray.Length {                      ; for every monitor in the top row
                    bottomArray.Push(topArray[A_Index])     ; push that monitor into the bottom row, adding them to the end
                }

                array := bottomArray                        ; set original array to the new ordered list of monitors


                BubbleSort(this, property := '') {
                    i := 0
                    length := this.Length

                    while true {
                        swapped := false

                        while ++i < length {
                            if (property ? this[i].%property% > this[i+1].%property%    ; if property stated, use property value
                                         : this[i] > this[i+1])                         ; if property omitted, use index value
                            {
                                temp := this[i]
                                this[i] := this[i+1]
                                this[i+1] := temp
                                swapped := true
                            }
                        }
                        i := 0, length--

                        if !swapped {
                            break
                        }
                    }
                }
            }
        }
    }
}


class Monitor {

    static activeWindowIsOn => Monitor.FromWindow('A')
    static mouseIsOn        => Monitor.FromMouse()
    static count            => MonitorGetCount()

    static coords {
        get => this[1]
        set => this.DefineProp('coords', {Get: (self) => self[value]})
    }
    static __CoordsFunc => MonitorGet

    static __Item[index] {
        get {
            if this._monitors.Has(index) {                  ; if index requested doesn't exist
                return this._monitors[index]                ; return last monitor in array
            }
            return 0
        }
    }

    static __New(CoordsFunc := MonitorGet, sorting_function?) {
        this.UpdateMonitorInfo()
    }

    static __Get(name, *) {
        return this.coords.%name%
    }

    static UpdateMonitorInfo(sortingFunction?) {
        ; when updating monitor info, removes previous index properties
        ; to ensure user can't try to access something that doesn't exist
        if this.HasOwnProp('_monitors') {
            loop this._monitors.Length {
                this.DeleteProp(A_Index)
            }
        }

        temp := []                                                          ; array to store monitor order (type: int)
        loop MonitorGetCount() {                                            ; loop amount equal to monitors found
            index := sortingFunction?.(A_Index) ?? A_Index                  ; if sorting function is supplied, sort monitors
            coords := this.__GetMonitorCoordinates(index)                   ; coords of monitor/screen

            this.DefineProp(A_Index, {Get: ((idx, *) => idx).Bind(index)})  ; save logical position of monitor to computer-assigned number
            temp.Push(coords)                                               ; add coords to array
        }

        this._monitors := temp                                      ; save array to class (for use with __Item)
        this.SetActive(this.%this.activeWindowIsOn%)                ; update coordinates of monitor currently in use
    }

    static Call(mon := this.activeWindowIsOn) {
        this.coords := mon
        return this[mon]
    }

    static SetActive(mon) {
        this.coords := mon
        return this[mon]
    }

    /**
     * @param @mon id window identification
     * @param @GetCoords used to dereference MonitorGet functions
     */
    static __GetMonitorCoordinates(mon) {
        this.__CoordsFunc.Call(mon, &left, &top, &right, &bottom)        ; get dimensions of monitor/screen

        coords := {         ; return monitor/screen coordinates and some other info
            index:          mon,
            number:         mon,
            top:            (top),
            bottom:         (bottom),
            left:           (left),
            right:          (right),
            width:          Abs(right  - left),
            height:         Abs(bottom - top ),
            halfWidth:      Abs(right  - left) * 0.50,          ; absolute position
            halfHeight:     Abs(bottom - top ) * 0.50,          ; absolute position
            centerX:        (left + right)     * 0.50,          ; relative position, useful for moving mouse to center
            centerY:        (top  + bottom)    * 0.50,          ; relative position, ^
            ChangeOrientation: (_, orientation) => Monitor.ChangeOrientation(orientation, mon),
        }

        coords.DefineProp('dpi', {Get: (self) => Monitor.GetDpi(mon) }) ; returns the DPI value
        coords.DefineProp('dpiScalingFactor', {Get: (self) => Monitor.GetDpiScalingFactor(mon)})    ; returns the multiplier relative to 100% scaling

        coords.DefineProp('orientation', {Get: (self) {
            DEVMODE := this.__GetDEVMODE(mon)
            return this.__GetOrientation(DEVMODE)
        }})

        return coords
    }

    class Info {
        static FromWindow(winTitle?, winText?, excludeTitle?, excludeText?) {
            handle := Monitor.GetHandleFromWindow(winTitle?, winText?, excludeTitle?, excludeText?)
            return this.__GetInfoFromHandle(handle)
        }
        static FromRect(left, top, right, bottom) {
            handle := Monitor.GetHandleFromRect(left, top, right, bottom)
            return this.__GetInfoFromHandle(handle)
        }
        static FromMouse() {
            handle := Monitor.GetHandleFromMouse()
            return this.__GetInfoFromHandle(handle)
        }
        static FromPoint(x, y?) {
            handle := Monitor.GetHandleFromPoint(x, y?)
            return this.__GetInfoFromHandle(handle)
        }

        ; @plankoe
        static __GetInfoFromHandle(handle) {
            ; NumPut('UInt', 104, monInfo := Buffer(40 + 64))   ; ntepa
            NumPut('UInt', 40, monInfo := Buffer(40))
            if DllCall('user32\GetMonitorInfo', 'Ptr', handle, 'Ptr', monInfo) {
                return {
                    Handle          : handle,
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
    }

    static GetCount() => MonitorGetCount()
    static GetName(monNumber?) => MonitorGetName(monNumber?)
    static GetPrimary() => MonitorGetPrimary()

    static FromWindow(winTitle?, winText?, excludeTitle?, excludeText?) {
        handle := this.GetHandleFromWindow(winTitle?, winText?, excludeTitle?, excludeText?)
        num := this.NumberFromHandle(handle)
        return this.%num%
    }

    static FromMouse() {        ; return monitor handle number mouse is on
        handle := this.GetHandleFromMouse()
        num := this.NumberFromHandle(handle)
        return this.%num%
    }

    ; if y is omitted, x is expected to be a point structure
    static FromPoint(x, y?) {   ; return monitor handle from an x, y point
        handle := this.GetHandleFromPoint(x, y?)
        num := this.NumberFromHandle(handle)
        return this.%num%
    }

    static FromRect(left, top, right, bottom) {
        handle := this.GetHandleFromRect(left, top, right, bottom)
        num := this.NumberFromHandle(handle)
        return this.%num%
    }

    static GetHandleFromWindow(winTitle?, winText?, excludeTitle?, excludeText?) {
        ; MONITOR_DEFAULTTONULL = 0
        ; MONITOR_DEFAULTTOPRIMARY = 1
        ; MONITOR_DEFAULTTONEAREST = 2
        return DllCall('MonitorFromWindow', 'Ptr', WinExist(winTitle?, winText?, excludeTitle?, excludeText?), 'UInt', 2)   ; get monitor handle from window specified
    }

    static GetHandleFromMouse() {
        ; MONITOR_DEFAULTTONULL = 0
        ; MONITOR_DEFAULTTOPRIMARY = 1
        ; MONITOR_DEFAULTTONEAREST = 2
        DllCall('GetCursorPos', 'UInt64*', &pointStruct:=0) ; get mouse position struct
        return DllCall('MonitorFromPoint', 'Int64', pointStruct, 'UInt', 2)
    }

    static GetHandleFromPoint(x, y?) {
        ; MONITOR_DEFAULTTONULL = 0
        ; MONITOR_DEFAULTTOPRIMARY = 1
        ; MONITOR_DEFAULTTONEAREST = 2
        pointStruct := IsSet(y)
            ? (x & 0xFFFFFFFF | y << 32)
            : x
        return DllCall('MonitorFromPoint', 'Int64', pointStruct, 'UInt', 2)
    }

    static GetHandleFromRect(left, top, right, bottom) {
        ; MONITOR_DEFAULTTONULL = 0
        ; MONITOR_DEFAULTTOPRIMARY = 1
        ; MONITOR_DEFAULTTONEAREST = 2
        RECT := Buffer(16, 0)
        NumPut(
            'Int', left,
            'Int', top,
            'Int', right,
            'Int', bottom,
            RECT
        )
        return DllCall('MonitorFromRect', 'Ptr', RECT, 'UInt', 2)
    }

    static FromHandle(handle) {
        num := this.NumberFromHandle(handle)
        return this.%num%
    }

    /**
     * @param {int} handle
     * @returns {Integer} the monitor's position the system defined it as (1, 2, 3, etc.)
     */
    static NumberFromHandle(handle) {                           ; convert handle to monitor number and return it
        list := this.__GetMonitorHandleList()
        loop parse, list, '`n' {                                ; loop list of monitor handle numbers
            if A_LoopField = handle {                           ; if the handle number matches the monitor handle specified
                return A_Index                                  ; return that index
            }
        }
        throw Error('Monitor not found.')
    }

    static HandleFromNumber(monNumber) {                        ; convert monitor number to handle and return it
        list := this.__GetMonitorHandleList()
        loop parse, list, '`n' {                                ; loop list of monitor handle numbers
            if A_Index = monNumber {                            ; if the monitor number matches the monitor number specified
                return A_LoopField                              ; return that monitor handle
            }
        }
        throw Error('Monitor not found.')
    }

    static __GetMonitorHandleList() {
        monHandleList := ''
        monCallback := CallbackCreate(EnumMonitors, 'Fast', 4)  ; fast-mode, 4 parameters

        if Monitor.EnumerateDisplays(monCallback) {             ; enumerates all monitors
            monHandleList := SubStr(monHandleList, 1, -1)       ; remove last newline character
            CallbackFree(monCallback)                           ; free callback from memory
            return monHandleList                                ; return list
        }

        EnumMonitors(hMonitor, hDevCon, pRect, args) {          ; callback function for enumeration DLL
            monHandleList .= hMonitor '`n'                      ; add monitor handle number to list
            return true                                         ; continues enumeration
        }
    }

    /**
     * @param {func} callback callback to perform after each iteration of monitor found
     * @returns {Float | Integer | String}
     */
    static EnumerateDisplays(callback) => DllCall('EnumDisplayMonitors', 'Ptr', 0, 'Ptr', 0, 'Ptr', callback, 'UInt', 0)

    /**
        DPI     Scale   Percentage
        96      1       100%
        120     1.25    125%
        144     1.5     150%
        168     1.75    175%
        192     2       200%
        216     2.25    225%
        240     2.5     250%
        288     3       300%
        336     3.5     350%
     */
    static GetDpi(monNumber) {
        handle := Monitor.HandleFromNumber(monNumber)
        DllCall('SHCore\GetDpiForMonitor', 'Ptr', handle, 'UInt', 0, 'UInt*', &dpiX := 0, 'UInt*', &dpiY := 0)
        return Sqrt(dpiX * dpiY) / 96
    }

    static GetDpiScalingFactor(monNumber) {
        handle := Monitor.HandleFromNumber(monNumber)
        DllCall('SHCore\GetDpiForMonitor', 'Ptr', handle, 'UInt', 0, 'UInt*', &dpiX := 0, 'UInt*', &dpiY := 0)
        return Sqrt(dpiX * dpiY) / 96
    }


    ; uses full percent, in other words it automatically converts to decimal
    ; for example, invoking Screen.X_Pos_Percent(40) returns position 40% from the left of the monitor/screen
    static X_Pos_Percent(percent)  => Integer(this.width  * (percent / 100) + this.left)
    static Y_Pos_Percent(percent)  => Integer(this.height * (percent / 100) + this.top)
    static Width_Percent(percent)  => Integer(this.width  * (percent / 100))
    static Height_Percent(percent) => Integer(this.height * (percent / 100))

    static Position_Percent(percent, &x?, &y?, &w?, &h?) {  ; same as above but all-in-one; untested
        x := this.X_Pos_Percent(percent)
        y := this.Y_Pos_Percent(percent)
        w := this.Width_Percent(percent)
        h := this.Height_Percent(percent)
    }


    /**
     * @Brightness
     * @param @offset how much to increase/decrease brightness
     */
    static IncreaseBrightness(offset := 1) => this.Brightness(offset)
    static DecreaseBrightness(offset := 1) => this.Brightness(offset)

    static Brightness(offset) {
        static wmi := ComObjGet("winmgmts:\\.\root\WMI")
        static last := wmi.ExecQuery("SELECT * FROM WmiMonitorBrightness").ItemIndex(0).CurrentBrightness
        level := Min(100, Max(1, last + Offset))
        if (level != last) {
            last := level
            wmi.ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods").ItemIndex(0).WmiSetBrightness(0, level)
        }
    }



    /**
     * @authors @teadrinker @ntepa
     * @source https://www.autohotkey.com/boards/viewtopic.php?f=82&t=118324&sid=110987efc736b5fc9c51bb9a8a09e855
     * @param {string or int} @orientation Orientation or direction to rotate screen
     * @param {int} @monNumber monitor to use
     */
    static ChangeOrientation(orientation := 'Landscape', monNumber := Monitor.FromWindow()) {
        static DMDO_DEFAULT := 0, DMDO_90 := 1, DMDO_180 := 2, DMDO_270 := 3

        display := '\\.\DISPLAY' monNumber
        DEVMODE := this.__GetDEVMODE(monNumber)
        currentOrientation := this.__GetOrientation(DEVMODE)

        n0 := NumGet(DEVMODE, 172, 'UInt')
        n1 := NumGet(DEVMODE, 176, 'UInt')
        b  := n0 < n1

        dimension1 := n% b% | n%!b% << 32
        dimension2 := n%!b% | n% b% << 32


        switch orientation, false {
            case 'Clockwise':
                orientation := (--currentOrientation) < DMDO_DEFAULT ? DMDO_270 : currentOrientation
                i := (orientation&1) + 1
            case 'CClockwise', 'CounterClockwise':
                orientation := (++currentOrientation) > DMDO_270 ? DMDO_DEFAULT : currentOrientation
                i := (orientation&1) + 1
            case 'Landscape'          ,   0: i := 1, orientation := DMDO_DEFAULT
            case 'Portrait'           ,  90: i := 2, orientation := DMDO_90
            case 'Landscape (flipped)', 180: i := 1, orientation := DMDO_180
            case 'Portrait (flipped)' , 270: i := 2, orientation := DMDO_270
            default:                         i := 1, orientation := DMDO_DEFAULT
        }

        NumPut('Int',   orientation , DEVMODE,  84)
        NumPut('Int64', dimension%i%, DEVMODE, 172)
        DllCall('ChangeDisplaySettingsEx', 'Str', display, 'Ptr', DEVMODE, 'Ptr', 0, 'Int', 0, 'Int', 0)
    }

    static __GetOrientation(DEVMODE) {
        return NumGet(DEVMODE, 84, 'Int')   ; current orientation
    }

    static __GetDEVMODE(monNumber) {
        static dmSize := 220

        NumPut('Short', dmSize, DEVMODE := Buffer(dmSize, 0), 68)
        display := '\\.\DISPLAY' monNumber
        DllCall('EnumDisplaySettings', 'Str', display, 'Int', -1, 'Ptr', DEVMODE)
        return DEVMODE
    }
}