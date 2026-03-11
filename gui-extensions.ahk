OnExit((*) {
    if IsSet(hBITMAP) and hBITMAP {
        DllCall("gdi32\DeleteObject", "ptr", hBITMAP)
    }
})


/**
 * the @this keyword is always implicity passed so it must be specified in the definitions (such as below the prototype)
 * but isn't explicitly passed when calling the methods
 */
Gui.Prototype.DefineProp('AddBorder',               {Call: __CreateBorder})
Gui.Prototype.DefineProp('CornerRadius',            {Call: __CornerRadius})
Gui.Prototype.DefineProp('ColorShift',              {Call: __ColorShift})
Gui.Prototype.DefineProp('Dec_to_Hex_Color',        {Call: __Dec_to_Hex_Color})
Gui.Prototype.DefineProp('AnimateWindow',           {Call: __AnimateWindow})
Gui.Prototype.DefineProp('JustifyCtrlText',         {Call: __JustifyCtrlText})
Gui.Text.Prototype.DefineProp('GuiCtrlTextSize',    {Call: __GuiCtrlTextSize})
Gui.Pic.Prototype.DefineProp('CreateGradient',      {Call: __CreateGradient})
gui_control_add_pos_props()



/**
 * @param {String} @side what side, or all, to add a border
 * @param {Int} @borderSize thickness of border
 * @param {String} @borderColor color of border
 * @param {String} @Owner_or_Parent use owner if you destroy the gui. use parent if you hide the gui.
 * @param {Boolean} @extendBorder whether the border should be added to the dimensions of the gui or be included in its original size, see guard clause for exception
 * @returns {Gui} useful if you want to alter the border created here with another class method
 * @notes from limited testing, these 2 things are mandatory:
 * 1. make sure gui is visible when applying border
 * 2. x and y positions of gui (not sure why, if the gui is shown, an x and y should exist so... ¯\_(ツ)_/¯)
 * Example:
 * MyGui.Show('x0 y0')
 * MyGui.AddBorder()
 * MyGui.Hide() // if applicable
 */
__CreateBorder(this, side := 'all', borderSize := 2, borderColor := 'ffffff', Owner_or_Parent := 'Parent', extendBorder := false) {
    if extendBorder and Owner_or_Parent = 'Parent' {    ; guard clause
        return MsgBox('Cannot make target gui the parent because the border position and dimensions are locked to the parent gui position '
                      'and dimensions which means the border will never show.`n`nPlease change/remove the argument for the extendBorder parameter.')
    }

    border := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border +E0x20 +' Owner_or_Parent this.Hwnd)
    border.BackColor := borderColor

    this.GetPos(&x, &y, &width, &height)   ; get gui dimensions to position border correctly

    extendBorder ? border.Show('x' x-borderSize ' y' y-borderSize ' w' width+(borderSize*2) ' h' height+(borderSize*2) ' NoActivate')
                 : border.Show('x' x ' y' y ' w' width ' h' height ' NoActivate')

    border.GetPos(,, &width, &height)
    dpi := A_ScreenDPI / 96
    width *= dpi, height *= dpi

    switch side, 'Off' {
    case 'top':
        frame := '0-0 ' width '-0 ' width '-' borderSize ' 0-' borderSize ' 0-0'
    case 'bottom':
        frame := '0-' height-borderSize ' ' width '-' height-borderSize ' ' width '-' height ' 0-' height ' 0-' height-borderSize
    case 'left':
        frame := '0-0 ' borderSize '-0 ' borderSize '-' height ' 0-' height ' 0-0'
    case 'right':
        frame := width-borderSize '-0 ' width '-0 ' width '-' height ' ' width-borderSize '-' height ' ' width-borderSize '-0'
    default:
        outer := '0-0 ' width '-0 ' width '-' height ' 0-' height ' 0-0 ' borderSize '-' borderSize ' ' width-borderSize '-' borderSize
        inner := borderSize '-' borderSize ' ' width-borderSize '-' borderSize ' ' width-borderSize '-' height-borderSize ' ' borderSize '-' height-borderSize ' ' borderSize '-' borderSize
        frame := outer ' ' inner
    }

    try WinSetRegion(frame, border)
    return border
}


/**
 * @param {number} curveRadius strength of curve
 */
__CornerRadius(this, curveRadius := 15) {
    this.GetPos(,, &width, &height)                                                ; get width and height of gui
    WinSetRegion('0-0 w' width ' h' height ' r' curveRadius '-' curveRadius, this) ; curve corners of gui
}


/**
 * how to use: bind this method to a gui
 * class gui example:
 * border := MyGui.AddBorder('bottom', 1)
 * this.border_rgb := ObjBindMethod(border, 'ColorShift')
 * then just add a start and stop timer where appropriate:
 * SetTimer(this.border_rgb, 10) & SetTimer(this.border_rgb, 0)
 */
__ColorShift(this) {
    static red       := 255     ; state of red color
    static green     := 0       ; state of green color
    static blue      := 0       ; state of blue color
    static index     := 1       ; state of what color is increasing or decreasing
    static increment := 4       ; amount (speed) to change color


    switch index {
        case 1: green := green + increment <= 255 ? green + increment : (index++, 255)
        case 2: red   := red   - increment >= 0   ? red   - increment : (index++,   0)
        case 3: blue  := blue  + increment <= 255 ? blue  + increment : (index++, 255)
        case 4: green := green - increment >= 0   ? green - increment : (index++,   0)
        case 5: red   := red   + increment <= 255 ? red   + increment : (index++, 255)
        case 6: blue  := blue  - increment >= 0   ? blue  - increment : (index := 1, 0)
    }

    try this.BackColor := this.Dec_to_Hex_Color(red, green, blue)
}


/**
 * @param R red
 * @param G green
 * @param B blue
 * @returns {String}
 * converts 0-255 decimal colors to hexidecimal
 */
__Dec_to_Hex_Color(this, R, G, B) => Format('0x{1:02X}{2:02X}{3:02X}', R, G, B)


/**
 * @param {String} animation animation to use
 * @param {Int} time time it takes to complete the animation in milliseconds
 * @thanks skan from their script @source https://www.autohotkey.com/boards/viewtopic.php?f=83&t=94044
 * make sure the gui has been shown at least once
 */
__AnimateWindow(this, animation, time) {
    hwnd  := this.Hwnd
    Flags := Map()
    Flags.CaseSense := 'Off'

    Flags.Set('Fade',           '0x00080000',       'Zoom',             '0x00000010',
              'SlideEast',      '0x00040001',       'RollEast',         '0x00000001',
              'SlideNorth',     '0x00040008',       'RollNorth',        '0x00000008',
              'SlideWest',      '0x00040002',       'RollWest',         '0x00000002',
              'SlideSouth',     '0x00040004',       'RollSouth',        '0x00000004',
              'SlideNorthEast', '0x00040009',       'RollNorthEast',    '0x00000009',
              'SlideNorthWest', '0x0004000A',       'RollNorthWest',    '0x0000000A',
              'SlideSouthWest', '0x00040006',       'RollSouthWest',    '0x00000006',
              'SlideSouthEast', '0x00040005',       'RollSouthEast',    '0x00000005')

    animation := Flags.Has(animation) ? Flags[animation] : Flags['Fade']
    animation |= DllCall('User32.dll\IsWindowVisible', 'Ptr', hwnd) ? 0x10000 : 0

    DllCall('User32.dll\AnimateWindow', 'Ptr', hwnd, 'Int', time, 'Int', animation)
}


/**
 * @Thanks FanaticGuru
 * @Source https://www.autohotkey.com/boards/viewtopic.php?p=520130#p520130:~:text=Here%20is%20an%20example%20to%20at%20least%20calculate%20the%20number%20of%20spaces%20to%20use%20to%20make%20text%20take%20up%20the%20whole%20button%20width.
 * @param {Gui Control} GuiCtrlObj gui control
 *
 * Evenly spaces text across the gui control. Just separate the text with the pipe | character
 *
 *
 * Examples:
 *
 * MyButton := MyGui.Add('Button', 'wp', 'More than one word button name.|(COW)')   ; First way of calling method
 * MyGui.JustifyCtrlText(MyButton)
 *
 * MyGui.JustifyCtrlText(MyButton := MyGui.Add('Button', 'wp', 'OK.|(WOW)|Now'))    ; Second way of calling method
 *
 * MyGui.JustifyCtrlText(MyGui.Add('Button', 'wp', 'OK.|(WOW)|Now'))                ; Third way of calling method
 */
__JustifyCtrlText(this, GuiCtrlObj) {
    spaceSize             := (__GuiCtrlTextSize(GuiCtrlObj, '          ').width / 10)                   ; get pixel size of a space
    ctrlTextSegments      := StrSplit(GuiCtrlObj.Text, '|')                                             ; separate gui control's text into array
    ctrlTextSegments.Size := __GuiCtrlTextSize(GuiCtrlObj, RegExReplace(GuiCtrlObj.Text, '\|')).width   ; add size property to array and set to width of text to be in gui control

    GuiCtrlObj.GetPos(, , &width), width -= 10                                                          ; 5 margin on each side
    numberOfSpaces := Floor((width - ctrlTextSegments.Size) / spaceSize - spaceSize)                    ; subtract text size from gui control width, then dividie by the size of a space, and subtract one space size

    spaces := Array()       ; initialize array

    for x in Range(ctrlTextSegments.Length - 1, 1, -1) {
        thisSpaces := Ceil(numberOfSpaces / x)
        numberOfSpaces -= thisSpaces
        spaces.Push(StrReplace(Format('{:' thisSpaces '}', ''), ' ', ' '))
    }

    for index, ctrlTextSegment in ctrlTextSegments {
        result .= ctrlTextSegment
        try result .= spaces[index]
    }

    GuiCtrlObj.Text := result

    Range(start, stop, step := 1) {
        return (&n) => (
            n := start,
            start += step,
            (step > 0 ? n <= stop : n >= stop)
        )
    }
}

/**
 * @param {Gui Control} GuiCtrlObj
 * @returns {object} that contains the width and height of the text object
 */
__GuiCtrlTextSize(this, text?) {
    static WM_GETFONT   := 0x0031                                                                           ; retrieves the font with which the control is currently drawing its text
    static DT_CALCRECT  := 0x400                                                                            ; determines the width and height of the rectangle.
    rect := Buffer(16)                                                                                      ; reserve space for rectangle
    text ??= this.Value

    hDC      := DllCall('GetDC', 'Ptr', this.Hwnd, 'Ptr')                                                   ; get device context
    hPrevObj := DllCall('SelectObject', 'Ptr', hDC, 'Ptr', SendMessage(WM_GETFONT,,, this))                 ; saves object in the specified device context to later be freed

    height   := DllCall('DrawText', 'Ptr', hDC, 'Str', text, 'Int', -1, 'Ptr', rect, 'UInt', DT_CALCRECT)   ; draws formatted text in the specified rectangle, returns the height
    width    := NumGet(rect, 8, 'Int') - NumGet(rect, 'Int')                                                ; first set of 4 bytes if the left side, third set of 4 bytes is the right side

    DllCall('SelectObject', 'Ptr', hDC, 'Ptr', hPrevObj)                                                    ; selects the previous object in the specified device context
    DllCall('ReleaseDC', 'Ptr', this.Hwnd, 'Ptr', hDC)                                                      ; frees that object

    return {width:  Round(width  * 96 / A_ScreenDPI),                                                       ; return width of text object
            height: Round(height * 96 / A_ScreenDPI)}                                                       ; return height of text object
}



gui_control_add_pos_props() {
    new_props := ['top','bottom','left','right','x','y','width','height','center']
    control_list := ['ActiveX','Button','CheckBox','ComboBox','Custom','DateTime','DDL','Edit','GroupBox','Hotkey','Link','ListBox','ListView','MonthCal','Pic','Progress','Radio','Slider','StatusBar','Tab','Text','TreeView','UpDown']

    for con_name in control_list {
        for prop_name in new_props {
            desc := {
                get:get_pos.Bind(prop_name),
                set:set_pos.Bind(prop_name)
            }
            Gui.%con_name%.Prototype.DefineProp(prop_name, desc)
        }
    }

    get_pos(name, this) {
        switch name {
            case 'x', 'left':   this.GetPos(&value)
            case 'y', 'top':    this.GetPos(, &value)
            case 'width':       this.GetPos(,, &value)
            case 'height':      this.GetPos(,,, &value)
            case 'right':       this.GetPos(&l,, &w), value := l+w
            case 'bottom':      this.GetPos(, &t,, &h), value := 1
            case 'center':      this.GetPos(,, &w), value := w/2
            default: throw Error('Invalid Position name', A_ThisFunc, 'Expected: x y width height left right top bottom`nReceived: ' name)
        }
        return value
    }

    set_pos(name, this, value) {
        switch name {
        case 'x', 'left':   this.move(value)
        case 'y', 'top':    this.move(, value)
        case 'width':       this.move(,, value)
        case 'height':      this.move(,,, value)
        case 'right':
                            this.GetPos(,, &w)
                            this.move(value-w)
        case 'bottom':
                            this.GetPos(,,, &h)
                            this.move(,value-h)
        case 'center':
                            this.GetPos(,, &w, &h)
                            value.Has(1) ? x := value[1]-(w/2) : unset
                            value.Has(2) ? y := value[2]-(h/2) : unset
                            this.move(x?, y?)
        default: throw Error('Invalid Position name', A_ThisFunc, 'Expected: x y width height left right top bottom`nReceived: ' name)
        }
    }
}


/**
 * @source - https://github.com/jNizM/ahk-scripts-v2/blob/main/src/Gui/CreateGradient.ahk
 * @param {variadic} colors - hexidecimal
 */
__CreateGradient(this, colors*) {
    static IMAGE_BITMAP        := 0
    static LR_COPYDELETEORG    := 0x00000008
    static LR_CREATEDIBSECTION := 0x00002000
    static STM_SETIMAGE        := 0x0172
    global hBITMAP

    ControlGetPos(,, &OutW, &OutW, this.Hwnd)
    Addr := Bits := Buffer(colors.Length * 2 * 4)
    for each, color in colors
        Addr := NumPut("UInt", color, "UInt", color, Addr)

    hBITMAP := DllCall("gdi32\CreateBitmap", "Int", 2, "Int", colors.Length, "UInt", 1, "UInt", 32, "Ptr", 0, "Ptr")
    hBITMAP := DllCall("user32\CopyImage", "Ptr", hBITMAP, "UInt", IMAGE_BITMAP, "Int", 0, "Int", 0, "UInt", LR_COPYDELETEORG | LR_CREATEDIBSECTION, "Ptr")
    DllCall("gdi32\SetBitmapBits", "Ptr", hBITMAP, "UInt", Bits.Size, "Ptr", Bits)
    hBITMAP := DllCall("user32\CopyImage", "Ptr", hBITMAP, "UInt", 0, "Int", OutW, "Int", OutW, "UInt", LR_COPYDELETEORG | LR_CREATEDIBSECTION, "Ptr")
    SendMessage(STM_SETIMAGE, IMAGE_BITMAP, hBitMAP, this.Hwnd)
}