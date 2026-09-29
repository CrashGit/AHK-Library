/************************************************************************
 * @Preamble
 * These DefineProp definitions must come before any call to them so be
 * sure to #Include them at the top of the script that invokes them.
 ***********************************************************************/

; Used for primitive types because they don't have a DefineProp method
DefinePrimitive := Object.Prototype.DefineProp


/************************************************************************
 * @Hotkey
 * @Examples
 * Hotkey.OnceEager('x', (*) => ToolTip('x: ' A_TickCount))
 * Hotkey.OnceLazy('z', (*) => ToolTip('z: ' A_TickCount))
 * Hotkey.NoRepeat('*z', (*) => ToolTip('z: ' A_TickCount))
 ***********************************************************************/
; Calls the hotkey, turns off, then resumes normal behavior even while still held
Hotkey.DefineProp('OnceEager',
    {Call: (this, key, Callback, options?) {
        this(key, (ThisHotkey) {
            this(key, 'Off')
            Callback(ThisHotkey)
        }, options?)
    }
})

; Calls the hotkey, turns off, but waits for the user to release the key before it reverts back to normal behavior
Hotkey.DefineProp('OnceLazy',
    {Call: (this, key, Callback, options?) {
        this(key, (ThisHotkey) {
            this(key, 'Off')
            (Callback?)(ThisHotkey)
        }, options?)

        this(key ' up', (*) {
            this(key ' up', 'Off')
        }, options?)
    }
})

/**
 * For some reason, using function definition expressions fail here if fat-arrow functions are used as default params.
 * Fail two possible ways depending on how it's setup (can't remember exact setup for each failure):
 * 1: No error, doesn't work. A MsgBox earlier in the script didn't run either, very strange.
 * 2: Class that was defined below it at the time said that classes can't be defined inside functions.
 */
Hotkey.DefineProp('NoRepeat',
    {Call: (this, key, DownCallback?, downOptions?, UpCallback?, upOptions?) {
        this(key, (ThisHotkey) {
            this(key, 'Off')
            (DownCallback?)(ThisHotkey)
        }, downOptions?)

        this(key ' up', (ThisHotkey) {
            this(key, 'On')
            (UpCallback?)(ThisHotkey)
        }, upOptions?)
    }
})


/************************************************************************
 * @String
 ***********************************************************************/
; Allows accessing letters by index e.g. 'World'[3] returns r
; If index is a string, it returns the starting position if found in string
DefinePrimitive(String.Prototype, '__Item', {
    Get: (this, index) {
        if index is String {
            return InStr(this, index)
        } else if index is Integer {
            return SubStr(this, index, 1) or 0
        }
    }
})