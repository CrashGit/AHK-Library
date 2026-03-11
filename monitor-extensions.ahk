#Include <monitor>
#Include <gui-extensions>


VirtualScreen.Previous := (*) => Send('#^{Left}')   ; change virtual desktop
VirtualScreen.Next := (*) => Send('#^{Right}')      ; change virtual desktop


/**
 * @param {bool} @useBorder By default creates a white border around the gui. If false, it will round the corners instead.
 * One thing to note: the numbers you see will probably not match the Identify numbers in the Windows Display Settings.
 * Either the settings use a different way to assign numbers or it doesn't update those numbers under the appropriate conditions so you get outdated numbers.
 * The numbers here though will suffice for the purposes of using these classes to do something with a monitor.
 */
Monitor.DisplayNumberGui := __DisplayNumberGui
Screen.DisplayNumberGui := __DisplayNumberGui

__DisplayNumberGui(this, useBorder := true, duration := 3000) {
    guis := []                                                              ; stores created guis so they can be referenced later to be destroyed

    loop MonitorGetCount() {                                                ; loop amount of monitor
        CreateNumberGui(A_Index)                                            ; create gui based on number
    }

    SetTimer(() {                                                           ; when done looping monitors, destroy guis after 3 seconds
        for gui in guis {                                                   ; for each gui in guis
            gui.Destroy()                                                   ; destroy gui
        }
    }, -duration)

    CreateNumberGui(index) {
        mon := this.%index%                                                 ; get monitor number

        numberGui := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border +E0x20')
        numberGui.BackColor := '131313'                                     ; dark backcolor
        numberGui.SetFont('s80 cffffff')                                    ; large, white text
        numberGui.AddText('Center', index)                                  ; add number

        MonitorGet(mon, &left,,, &bottom)                                   ; get monitor left side and bottom
        numberGui.Show('x' left+100 ' y' bottom-300 ' AutoSize NoActivate') ; position gui using left and bottom of monitor

        if useBorder {                                                      ; if use border is true
            numberGui.AddBorder('all', 4,, 'Owner', true)                   ; create borders for gui
        } else {                                                            ; if use border is false
            numberGui.CornerRadius()                                        ; curve corners of gui
        }

        guis.Push(numberGui)                                                ; add gui to array so it can later be destroyed
    }
}