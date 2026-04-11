#Include <keyboard>
#Include <audio>
#Include <mouse>
#Include <gui-extensions>


Keyboard.Layer := Class('Layer')



/**
 * @getters @setters
*/
Keyboard.Layer.DefineProp('default', {Get: (this) => 'Reposition Window'})
Keyboard.Layer.DefineProp('activated', {
    Get: (this) => this._activated,
    Set: (this, value) {
        this._activated := value
        (!this._activated ? this.Disable() : 0)
    }
})

Keyboard.Layer.DefineProp('toggle_activation', {Get: (this) => (this._activated := !this._activated, !this._activated ? this.Disable() : Keyboard.Layer.Gui_Text_Update())})
Keyboard.Layer.DefineProp('enabled', {
    Get: (this) {
        if this.activated && GetKeyState(this.modifier, 'P') {
            return this._layer
        }
    },
    Set: (this, value) {
        this._layer := value
        this.Gui_Text_Update()
        this.__IfSpecificLayerIsActivated()
    }
})


/**
 * @properties
 */
Keyboard.Layer.modifier     := 'vkFF'                   ; this is the key to hold down when you press other keys to change layers
Keyboard.Layer._layer       := Keyboard.Layer.default   ; initialize default layer
Keyboard.Layer._activated   := true                     ; keeps track of on/off state


/**
 * @methods
 */
Keyboard.Layer.Enable := (this) => Keyboard.Layer.enabled := this.default

Keyboard.Layer.GetActiveWindowLayer := (this) {
    if !win := WinGetProcessName('A') {
        Keyboard.Layer.enabled := this.default
        return
    }

    switch win {  ; this can set the starting layer depending on the active window
    case 'Code.exe':    Keyboard.Layer.enabled := 'VSCode'
    case 'vivaldi.exe': Keyboard.Layer.enabled := 'Vivaldi'
    case 'Discord.exe': Keyboard.Layer.enabled := 'Discord'
    default:            Keyboard.Layer.enabled := this.default
    }
}

Keyboard.Layer.Disable := (this) {
    this._layer := this.default
    this.Layer_Gui.Hide()
    this.ShowHotkeys(false)
    SetTimer(this.border_rgb, 0)
    try Mouse.Layer.Disable()
}

Keyboard.Layer.Gui_Text_Update := (this, additionalText := '') {
    this.layerText.value      := 'Keyboard Layer:    ' . this._layer ' ' additionalText
    this.mouseLayerText.value := 'Mouse Layer:    '    . Mouse.Layer.enabled

    SetTimer(this.border_rgb, 10)   ; show rgb border
    this.Layer_Gui.Show('x0 y0 w' A_ScreenWidth*(96/A_ScreenDPI) ' h48 NoActivate')
    this.ShowHotkeys()
}

Keyboard.Layer.ShowHotkeys := (this, show := true) {
    static hotkeyGui := 0
    static layer := {hotkeys: '', description: '', enabled: ''}

    try {
        if layer.enabled = this._layer && this.default != this._layer {    ; don't update gui if same layer hotkey is pressed again
            return
        }

        DestroyGui()                                                        ; destroy gui if exists

        if !show {                                                          ; return after destroy if you just want to destroy
            return
        }

        hotkeyGui := Gui('+AlwaysOnTop +Owner')
        hotkeyGui.BackColor := '262626'
        hotkeyGui.SetFont('s10 bold c000000', 'Segoe UI')
        hotkeyGui.LV := hotkeyGui.AddListView('Left h300 -E0x200 -Multi NoSortHdr', ['Hotkeys', 'Description'])

        layer := this.ParseHotkeys()                                        ; object list of hotkeys and description (comments)


        loop parse, layer.hotkeys, '`n' {
            hotkeyGui.LV.Add(, A_LoopField)                                 ; add hotkeys to list
        }

        loop parse, layer.description, '`n' {
            field := RegExReplace(A_LoopField, '\s+', ' ')                  ; remove any extra whitespace
            hotkeyGui.LV.Modify(A_Index,,, field)                           ; add descriptions to second column
        }

        loop hotkeyGui.LV.GetCount('Col') {
            hotkeyGui.LV.ModifyCol(A_Index, 'AutoHdr')                      ; auto-size
        }

        ; dpi := 96 / A_ScreenDPI
        hotkeyGui.LV.Delete(hotkeyGui.LV.GetCount())                        ; delete last blank row
        hotkeyGui.Show('xCenter yCenter AutoSize NoActivate')               ; show list
        hotkeyGui.GetPos(,, &width, &height)
        ; width := Round(width * dpi)
        ; height := Round(height * dpi)
        hotkeyGui.Move(A_ScreenWidth//2 - (width//2), A_ScreenHeight - height - 80) ; 80px offset from the bottom of the screen
    }

    DestroyGui(*) {
        try hotkeyGui.Destroy()
        try hotkeyGui := unset
        layer := {hotkeys: '', description: '', enabled: ''}
    }
}

Keyboard.Layer.ParseHotkeys := (this) {
    hotkeys := '', description := '',  tab := ''

    file := 'layer-hotkeys.ahk'

    loop read, file {
        if SubStr(A_LoopReadLine, 1, 6) = '#HotIf'                  ; if #HotIf is first on line
        && (InStr(A_LoopReadLine, this._layer)                      ; and layer.enabled is found on the line
        || (InStr(A_LoopReadLine, 'Keyboard.Layer.default')         ; or default layer is found on the line &
        && this.default = this._layer)) {                           ; as long as default is the enabled layer
            index := A_Index+1                                      ; remember next line to start on

            loop read, file {
                if index != A_Index {                               ; skip previous lines before the line we need to start at
                    continue
                }

                if InStr(A_LoopReadLine, '#HotIf') {                ; if next #HotIf is encountered, return hotkeys
                    return {
                        hotkeys: hotkeys,
                        description: description,
                        enabled: this._layer
                    }
                }


                if (half := InStr(A_LoopReadLine, '::'))            ; if hotkey found on line, remember position of hotkey
                && SubStr(A_LoopReadLine, 1, 1) != ';' {            ; if first character is not a semicolon (comment)
                    comment := InStr(A_LoopReadLine, ';',, 5)       ; get position of start of comment

                    tabs := (half-1) / 4 >= 2 ? 1 :                 ; calculates tabs to insert based on hotkey length
                            (half-1) / 4 >= 1 ? 2 : 3
                    loop tabs                                       ; loop tab count
                        tab .= '`t'                                 ; append that many tabs

                    hotkeys .= StrReplace(SubStr(A_LoopReadLine, 1, half-1), '*') '`n'      ; get hotkey, leaving out the wildcard modifier
                    description .= comment ? Trim(SubStr(A_LoopReadLine, comment+1)) '`n'   ; get comment, leaving out semicolon and leading/trailing whitespace
                                            : 'no description available`n'                   ; if no comment, use this default description
                }
                index := A_Index+1
            }
        }
    }
    MsgBox('Improperly placed #HotIfs or failed.')
}

/**
 * @private @gui
 */
Keyboard.Layer.__IfSpecificLayerIsActivated := (this) {
    switch this._layer {
    case 'AppVolume':
        this.Gui_Text_Update(Audio.GetAppVolumeAsPercent())
    default:
    }
}

Keyboard.Layer.__Create_Layer_Gui := (this) {
    this.Layer_Gui := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border +E0x20')
    this.Layer_Gui.BackColor := '000000'
    this.Layer_Gui.MarginY   := 0
    this.Layer_Gui.SetFont('s16 bold cffffff', 'Segoe UI')

    dpi     := A_ScreenDPI / 96                     ; dpi context
    ctrls   := 2                                    ; amount of text controls, change this if you add or remove text controls below
    width   := A_ScreenWidth / ctrls                ; screenwidth divided by text controls
    width   *= dpi

    ; @text_controls
    this.layerText       := this.Layer_Gui.AddText('Left y6 w' width)
    this.mouseLayerText  := this.Layer_Gui.AddText('xp+' width ' w' width)

    this.Layer_Gui.Show('x0 y0 w' A_ScreenWidth*dpi ' h48 NoActivate NA')

    border := this.Layer_Gui.AddBorder('bottom', 1)
    this.border_rgb := ObjBindMethod(border, 'ColorShift')

    this.Layer_Gui.Hide()
}

Keyboard.Layer.__Create_Layer_Gui()