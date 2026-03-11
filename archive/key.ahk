; handles key states, keywait, and
; returning the hotkey pressed in its basic form


class Key {
    static IsPressed(hotkey := A_ThisHotkey)        => GetKeyState(this.ReturnHotkey(hotkey), 'P')
    static IsNotHeld(hotkey := this.ReturnHotkey()) => not this.IsPressed(hotkey)

    static WaitForRelease(hotkey := A_ThisHotkey, timeout := 0, waitForBothKeys := false) {
        if this.__CheckForUp(hotkey) {                                   ; guard clause to not work for up keys, e.g. LCtrl up::
            return ; MsgBox('"up" variation of hotkey not allowed')
        }

        this.__StripHotkey(&hotkey)
        this.__WaitForKey(hotkey, 'U', timeout, waitForBothKeys)
    }

    static OnRelease(Callback, key := this.ReturnHotkey()) {
        key_to_release := '*' key ' up'
        active := true

        HotIf (*) => active
        Hotkey(key_to_release, (*) => (active := false, Callback()))
        HotIf
    }


    static WaitForPress(hotkey := A_ThisHotkey, timeout := 0, waitForBothKeys := false) {
        if this.__CheckForUp(hotkey) {                                  ; guard clause to not work for up keys, e.g. LCtrl up::
            return ; MsgBox('"up" variation of hotkey not allowed')
        }

        this.__StripHotkey(&hotkey)
        return this.__WaitForKey(hotkey, 'D', timeout, waitForBothKeys)
    }



   static ReturnHotkey(hotkey := A_ThisHotkey, waitForBothKeys := false) {
        if this.__CheckForUp(hotkey)                                    ; guard clause to not work for up keys, e.g. LCtrl up::
            return ; MsgBox('"up" variation of hotkey not allowed')

        this.__StripHotkey(&hotkey)
        this.__CheckForAmpersand(hotkey, &ampersand)                    ; check for hotkey with & symbol


        switch {                                                        ; return hotkey
            case ampersand and waitForBothKeys:                         ; if hotkey is something like 'LCtrl & a::'
                return [SubStr(hotkey, 1, ampersand-1),                 ; return both keys in an array
                        SubStr(hotkey, ampersand+1)]                    ; retrieved like value1 := KeyWait(,,,, true)[1] and value2 := KeyWait(,,,, true)[2]
                                                                        ; or value3 := KeyWait(,,,, true), value[1] or value[2]
            case ampersand:                                             ; if hotkey is something like 'LCtrl & a::', but only want second key
                return SubStr(hotkey, ampersand+1)                      ; return 'a'

            default:                                                    ; returns normal hotkey
                return hotkey
        }
   }




   ;-------------------------------------------------------------
   ; private methods to support the methods that should be called
   ;-------------------------------------------------------------
   ; wait for key to be pressed or released
   static __WaitForKey(hotkey, options, timeout, waitForBothKeys) {
        options := options (timeout > 0 ? ' T' timeout : '')            ; keywait options
        this.__CheckForAmpersand(hotkey, &ampersand)                    ; check for hotkey with & symbol

        try {
            switch {                                                    ; keywait()
                case ampersand and waitForBothKeys:                     ; wait for both keys to be pressed or released
                    if KeyWait(SubStr(hotkey, 1, ampersand-1), options) ; key left of ampersand
                    && KeyWait(SubStr(hotkey,    ampersand+1), options) ; key right of ampersand
                        return true

                case ampersand:                                         ; wait for second key
                    if KeyWait(SubStr(hotkey, ampersand+1), options) {  ; key right of ampersand
                        return true
                    }

                default:                                                ; wait for key
                    if KeyWait(hotkey, options) {                       ; normal keywait
                        return true
                    }
            }
        }
    }


    ; removes modifiers and symbols from hotkey
    static __StripHotkey(&hotkey) {
        modifiers := ['~', '*', '$', '!', '^',                          ; symbols to strip from hotkey
                      '+', '#', '<', '>', ' ']

        for modifier in modifiers {                                     ; for each modifier
            hotkey := StrReplace(hotkey, modifier)                      ; remove modifier
        }
    }

    static __CheckForUp(hotkey) => (InStr(hotkey, ' up') and not InStr(hotkey, '& up'))
    static __CheckForAmpersand(hotkey, &ampersand) => ampersand := InStr(hotkey, '&')
}