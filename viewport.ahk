/**
 * @inspiration
 * @author GroggyOtter
 * @source https://old.reddit.com/r/AutoHotkey/comments/141oy0q/viewport_for_ahk_v2_click_and_drag_to_make_a/
 */

#SingleInstance
#Include monitor.ahk
#Include mouse.ahk


class Viewport {

    static __New() {
        this.views := Map()
    }


    static SetOpacity(value) {
        for id, view in this.views {
            alpha := WinGetTransparent(view.Hwnd)
            WinSetTransparent(alpha + value, view.Hwnd)
        }
    }

    static IncreaseOpacity(value := 15) => this.SetOpacity(value)
    static DecreaseOpacity(value := 15) => this.SetOpacity(-value)


    static SetViewOpacity(value, identifier := 'A') {
        view := this.__CreateView(identifier)
        alpha := WinGetTransparent(view.Hwnd)
        WinSetTransparent(alpha + value, view.Hwnd)
    }

    static IncreaseViewOpacity(value := 15, identifier := 'A') => this.SetViewOpacity(value, identifier)
    static DecreaseViewOpacity(value := 15, identifier := 'A') => this.SetViewOpacity(-value, identifier)


    static Call(dimensions?) {
        if IsSet(dimensions) {
            this.__CreateGui(this.__DimensionStruct(dimensions.x, dimensions.y, dimensions.w, dimensions.h))
            return
        }

        MouseGetPos(&x, &y, &winUnderMouse)

        win := this.views.Get(winUnderMouse, false)
        if !win {
            return
        }

        ; initialize start of drawing position
        x_start := x < 0 ? Abs(VirtualScreen.left) - Abs(x) : Abs(x) + Abs(VirtualScreen.left)
        y_start := y < 0 ? Abs(VirtualScreen.top)  - Abs(y) : Abs(y) + Abs(VirtualScreen.top)

        ; confine mouse to monitor if relevant
        ; (this.mon = 'all' ? Mouse.Cursor.ConfineToArea(false) :  Mouse.Cursor.ConfineToMonitor(this.mon))   ; Mouse.Cursor.ConfineToMonitorMouseIsOn()

        ; if !WinExist('ahk_id' this.gui.Hwnd) {
        ;     this.gui.Restore()
        ; }

        Mouse.Cursor.ConfineToWindow('ahk_id' win)

        Draw(RegExReplace(A_ThisHotkey, '[~*$!#+^<>]|\sup'))

        Draw(key) {
            if !GetKeyState(key, 'P') {
                Mouse.Cursor.ConfineToArea(false)
                return
            }

            MouseGetPos(&x, &y)

            xPos := x < 0 ? Abs(VirtualScreen.left) - Abs(x)                            ; get relative mouse x position
                          : Abs(x) + Abs(VirtualScreen.left)
            yPos := y < 0 ? Abs(VirtualScreen.top) - Abs(y)                             ; get relative mouse y position
                          : Abs(y) + Abs(VirtualScreen.top)

            drawn_region := Format('{1}-{2} {3}-{2} {3}-{4} {1}-{4} {1}-{3}', x_start, y_start, xPos, yPos)
            ; region := (blackoutRegion ' ' whiteoutRegion ' '                   ; set region to be viewed
                        ; this.drawn_region ' ' whiteoutRegion ' ' whiteoutRegion)

            ; this.Whiteout('ahk_id' this.gui.Hwnd)     ; update to dynamic view
            ; this.SetView(drawn_region)                                                                   ; update viewport
            SetTimer(() => Draw(key), -1)                                                              ; restart function
        }
    }





    static Blackout(identifier, toggleIfExists := true) {
        if toggleIfExists {
            view := this.__GetView(identifier)
            if view {
                this.ToggleView(view)
                return
            }
        }
        this.__CreateView(identifier)
        ; view.Restore()
    }


    static Whiteout(identifier) {
        view := this.__GetView(identifier)
        if view {
            view.Destroy()
            this.views[identifier] := unset
        }
    }


    static __GetPortType(identifier) {
        return (IsInteger(identifier) && identifier <= 10)
            ? 'monitor'     ; if strictly an integer and less than 10
            : 'window'      ; else assumed to be a WinTitle
    }


    static __GetView(identifier) {
        portType := this.__GetPortType(identifier)

        switch portType {
        case 'monitor':
            return this.views.Get(identifier, false)
        case 'window':
            hwnd := WinGetID(identifier)
            return this.views.Get(hwnd, false)
        default:
            throw Error('Something went wrong retrieving the viewport.')
        }
    }

    static __CreateView(identifier) {
        portType := this.__GetPortType(identifier)

        switch portType {
        case 'monitor':
            size := this.__GetMonitorSize(identifier)
            view := this.views.Get(identifier, false)
        case 'window':
            size := this.__GetWindowSize(identifier)
            identifier := WinGetID(identifier)
            view := this.views.Get(identifier, false)
        default: throw Error('Something went wrong retrieving the viewport.')
        }

        if view {
            view.Destroy()
            this.views[identifier] := unset
        }

        view := this.__CreateGui(size)
        return this.views[identifier] := view
    }

    static __GetWindowSize(identifier) {
        WinGetPos(&x, &y, &w, &h, identifier)
        return this.__DimensionStruct(x, y, w, h)
    }

    static __GetMonitorSize(monNumber) {
        MonitorGet(monNumber, &left, &top, &right, &bottom)
        width := Abs(right - left)
        height := Abs(bottom - top)
        return this.__DimensionStruct(left, top, width, height)
    }


    static __CreateGui(size) {   ; object literal {x, y, w, h}
        goo := Gui('+AlwaysOnTop -Caption')
        goo.BackColor := 000000
        dimensions := Format('x{} y{} w{} h{}', size.x, size.y, size.w, size.h)
        goo.Show(dimensions ' NoActivate')
        WinSetTransparent(255, goo.Hwnd)
        return goo
    }

    static __DimensionStruct(x, y, w, h) {
        return {
            x: x,
            y: y,
            w: w,
            h: h
        }
    }

    static ToggleViews(setAll := true) {    ; set to false if you want to invert all gui's state independently
        Callback := setAll
            ? (AnyViewVisible() ? (view) => view.Hide() : (view) => view.Restore())
            : ObjBindMethod(this, 'ToggleView')

        for id, view in this.views {
            Callback(view)
        }

        AnyViewVisible() {
            for id, view in this.views {
                if WinExist('ahk_id' view.Hwnd) {
                    return true
                }
            }
            return false
        }
    }

    ; where view is the viewport gui associated with a pure hwnd or monitor number in the this.views map
    static ToggleView(view) =>
        (WinExist('ahk_id' view.Hwnd) ? view.Hide() : view.Restore())

    static DestroyView(view) {
        if view := this.views.Get(view, false) {
            view.Destroy()
            this.views[view] := unset
        }
    }

    static Clear() =>
        this.views.Clear()

    ; does this work how I think?
    ; it's supposed to check if the monitor/window exists, if not, it destroys the viewport and removes it from the map
    static CleanUp() {
        temp := []

        for id, view in this.views {
            portType := this.__GetPortType(id)
            switch portType {
            case 'monitor':
                if MonitorGetCount() > id {
                    temp.Push(id)
                }
            case 'window':
                if !WinExist(id) {
                    temp.Push(id)
                }
            }
        }

        for id in temp {
            this.views[id].Destroy()
            this.views.Delete(id)
        }
    }
}