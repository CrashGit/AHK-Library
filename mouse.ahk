; ensure the cursor is made visible when the script exits
OnExit (*) => Mouse.Cursor.Visibility('Show')

; minimal mouse delay
SetMouseDelay(-1)


class Mouse {
    static _coordMode := 'Screen'

    static x => (this.GetPos(&x), x)
    static y => (this.GetPos(, &y), y)
    static isHoveringOver => (this.GetPos(,, &win), win)
    static windowUnderCursor => (this.GetPos(,, &win), win)
    static currentWindow => (this.GetPos(,, &win), win)

    static CoordMode(value) => this._coordMode := value
    static IsOver(winTitle?, winText?, excludeTitle?, excludeText?) => (MouseGetPos(,, &hwnd), hwnd = WinExist(winTitle?, winText?, excludeTitle?, excludeText?))

    static GetPos(&x?, &y?, &win?, &control?, flag := 0) {
        CoordMode('Mouse', this._coordMode)
        MouseGetPos(&x, &y, &win, &control, flag)
        return this
    }

    static Lock()   => BlockInput('MouseMove')
    static Unlock() => BlockInput('MouseMoveOff')

    static MoveTo(x, y) => DllCall('SetCursorPos', 'Int', x, 'Int', y)

    static __Call(name, *) => throw(Error('This value of type "Class: ' this.Prototype.__Class '" has no method named ' name '.'))
    static __Get(name, *) => throw(Error('This value of type "Class: ' this.Prototype.__Class '" has no property named ' name '.'))

    class Cursor {
        static __Call(name, *) => throw(Error('This value of type "Class: ' this.Prototype.__Class '" has no method named ' name '.'))

        /**
         * @param {string} cmd 'Show|Hide|Toggle|Reload'
         * @returns {void}
         */
        static Visibility(cmd) {
            static visible := true, c := Map()
            static sys_cursors := [32512, 32513, 32514, 32515, 32516, 32642,
                                   32643, 32644, 32645, 32646, 32648, 32649, 32650]

            if (cmd = 'Reload' or !c.Count) {   ; Reload when requested or at first call.
                for i, id in sys_cursors {
                    h_cursor  := DllCall('LoadCursor', 'Ptr', 0, 'Ptr', id)
                    h_default := DllCall('CopyImage', 'Ptr', h_cursor, 'UInt', 2,
                                         'Int', 0, 'Int', 0, 'UInt', 0)
                    h_blank   := DllCall('CreateCursor', 'Ptr', 0, 'Int', 0, 'Int', 0,
                                         'Int', 32, 'Int', 32,
                                         'Ptr', Buffer(32*4, 0xFF),
                                         'Ptr', Buffer(32*4, 0))
                    c[id] := {default: h_default, blank: h_blank}
                }
            }

            switch cmd {
                case 'Show':   visible := true
                case 'Hide':   visible := false
                case 'Toggle': visible := !visible
                default: return
            }

            for id, handles in c {
                h_cursor := DllCall('CopyImage',
                                    'Ptr', visible ? handles.default : handles.blank,
                                    'UInt', 2, 'Int', 0, 'Int', 0, 'UInt', 0)
                DllCall('SetSystemCursor', 'Ptr', h_cursor, 'UInt', id)
            }
        }


        static VisibilityEnable()  => this.Visibility('Show')
        static VisibilityDisable() => this.Visibility('Hide')
        static VisibilityToggle()  => this.Visibility('Toggle')
    }
}