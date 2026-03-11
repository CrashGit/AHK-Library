OnExit (*) => Keyboard.Lock(false)


class Keyboard {
    static __Call(name, *) => throw(Error('This value of type "Class: ' this.Prototype.__Class '" has no method named ' name '.'))
    static __Get(name, *) => throw(Error('This value of type "Class: ' this.Prototype.__Class '" has no property named ' name '.'))

    static __OnLock := (*) => 0
    static __OnUnlock := (*) => 0

    static OnLock(Callback) {
        this.__OnLock := (*) => Callback()
    }

    static OnUnlock(Callback) {
        this.__OnUnlock := (*) => Callback()
    }

    /**
     * @thanks lexikos
     * @source https://www.autohotkey.com/board/topic/21238-blocking-just-keyboard-not-mouse/page-2#:~:text=script%20doesn%27t%20block.-,Keyboard%20hook%20method,-%3A
     * @param {number} @block
     * @note -
     * To block only physical keypresses (and allow Send), add this to the function:
        if (NumGet(lParam+8) & 0x10)  ; LLKHF_INJECTED
            return DllCall("CallNextHookEx", "uint", 0, "int", nCode, "uint", wParam, "uint", lParam)
    */
    static Lock(block := -1) {  ; -1, true or false
        static hHook := 0, cb := CallbackCreate(ObjBindMethod(this, '__BlockKeyboard_HookProc'),, 3)

        if (hHook!=0) = (block!=0) {    ; already (un)blocked, no action necessary.
            return
        }

        if (block) {
            try TraySetIcon('icons\disabled.ico')
            hHook := DllCall('SetWindowsHookEx',
                'Int',  13,     ; WH_KEYBOARD_LL
                'UInt', cb,     ; lpfn (callback)
                'UInt', 0,      ; hMod (NULL)
                'UInt', 0)      ; dwThreadId (all threads)
            this.__OnLock()
        } else {
            try TraySetIcon('icons\coding.png')
            BlockInput('MouseMoveOff')
            DllCall('UnhookWindowsHookEx', 'UInt', hHook)
            hHook := 0
            this.__OnUnlock()
        }
    }

    static __BlockKeyboard_HookProc(nCode, wParam, lParam) {
        static count := 0

        if (NumGet(lParam, 8, 'Int') & 0x80) {                          ; key up
            ; unlock keyboard if "unlock" is typed in
            if (count = 0 && NumGet(lParam, 4, 'Int') = 0x16) {         ; 'u'
                count := 1
            } else if (count = 1 && NumGet(lParam, 4, 'Int') = 0x31) {  ; 'n'
                count := 2
            } else if (count = 2 && NumGet(lParam, 4, 'Int') = 0x26) {  ; 'l'
                count := 3
            } else if (count = 3 && NumGet(lParam, 4, 'Int') = 0x18) {  ; 'o'
                count := 4
            } else if (count = 4 && NumGet(lParam, 4, 'Int') = 0x2E) {  ; 'c'
                count := 5
            } else if (count = 5 && NumGet(lParam, 4, 'Int') = 0x25) {  ; 'k'
                count := 0, this.Lock(false)
            } else {
                count := 0
            }
        }

        return 1
    }
}