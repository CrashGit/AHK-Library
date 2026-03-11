SetWinDelay(-1)



Notification.CreateGui()



class Notification
{
    static Notify           := unset
    static transparency     := unset
    static prevHwnd         := 0


    ; METHODS
    static HoverShowFullMessage := ObjBindMethod(this, 'ShowFullNotificationInToolTip')
    static SlideAndFadeOut      := ObjBindMethod(this, 'SlideAndFadeOutMethod')
    static fadeOut              := () => SetTimer(this.SlideAndFadeOut, -10)


    ; colors can be passed to different parts in case you want a different color somewhere specific
    static Display( title,
                    message,
                    beepTone        := 523,
                    duration        := 3000,
                    backcolor       := '000000',
                    titleColor      := 'c05deff',
                    messageColor    := 'cffffff',
                    primaryColor    := 'cf50c98',
                    secondaryColor  := 'cd503ff'    )
    {

        this.SlideAndFadeIn := ObjBindMethod(this, 'SlideAndFadeInMethod', -duration)

        this.HideNotificationIfVisible()                ; hides existing notification
        SoundBeep(beepTone)                             ; play a tone

        this.clickToDismiss.tooltipNotify := message    ; used for tooltip when hovering over notification, let's you see full message if it gets cut off


        if StrLen(title) > 24                           ; if title is too long
            title := SubStr(title, 1, 21) . '...'

        if StrLen(message) > 35                         ; if message is too long
            message := SubStr(message, 1, 32) . '...'

        ; change colors
        this.Notify.BackColor := backcolor
        this.Notify['leftBracket'].Opt(primaryColor)
        this.Notify['title'].Opt(titleColor)
        this.Notify['slash'].Opt(secondaryColor)
        this.Notify['rightBracket'].Opt(primaryColor)
        this.Notify['message'].Opt(messageColor)

        ; change title and message
        this.Notify['title'].value := title
        this.Notify['message'].value := message


        this.Notify.GetPos(,,, &height)
        this.Notify.Show('y-' height ' AutoSize NoActivate')
        this.Notify.Opt('+AlwaysOnTop') ; had to add this because it wasn't always showing over certain windows

        SetTimer(this.SlideAndFadeIn, -10)
    }



    static SlideAndFadeInMethod(duration)
    {
        try {
            this.transparency := WinGetTransparent(this.Notify) + 5

            try WinSetTransparent(this.transparency, this.Notify)
            catch {
                WinSetTransparent(255, this.Notify)
            }


            this.Notify.GetPos(, &guiY)
            this.Notify.Move(, guiY + 2)
            this.Notify.GetPos(, &guiY)


            if guiY >= 20 {     ; pixels from the top
                WinSetTransparent(255, this.Notify)
                SetTimer(this.fadeOut, -duration)
            }

           else SetTimer(this.SlideAndFadeIn, -10)
        }
    }



    static SlideAndFadeOutMethod()
    {
        try {
            this.transparency := WinGetTransparent(this.Notify) - 5

            try WinSetTransparent(this.transparency, this.Notify)
            catch {
                WinSetTransparent(0, this.Notify)
            }


            this.Notify.GetPos(, &guiY,, &gui_height)
            this.Notify.Move(, guiY - 2)
            this.Notify.GetPos(, &guiY)


            ; gui_height above the screen (off screen)
            if guiY <= (0 - gui_height)
                this.HideNotificationIfVisible()

            else SetTimer(this.SlideAndFadeOut, -10)
        }
    }


    static ShowFullNotificationInToolTip(wParam, lParam, msg, Hwnd) {
        if Hwnd != this.prevHwnd
        {
            currCtrl := GuiCtrlFromHwnd(Hwnd)

            if currCtrl
            {
                if !currCtrl.HasProp('tooltipNotify')
                    return

                this.Notify.GetPos(&guiX, &guiY, &guiWidth, &guiHeight)             ; get position and dimensions of gui
                tooltipID := ToolTip(currCtrl.tooltipNotify)                        ; shows tooltip of the message
                WinGetPos(,, &ttWidth,, 'ahk_id' tooltipID)                         ; get width of tooltip
                WinMove(guiX + (guiWidth - ttWidth) / 2, guiHeight+10,,, tooltipID) ; move tooltip to bottom center of gui
            }
            else ToolTip()
            this.prevHwnd := Hwnd
        }
    }


    static CreateGui() {
        this.Notify := Gui('+AlwaysOnTop +ToolWindow -SysMenu -Caption -Border')
        this.Notify.MarginX   := 10
        this.Notify.MarginY   := 10
        this.Notify.BackColor := '262626'


        this.Notify.SetFont('s20 bold', 'Segoe UI')
            this.Notify.AddText('Center y2 vleftBracket', '<')

        this.Notify.SetFont('s14')
            this.Notify.AddText('Center x+9 yp+7 w250 vtitle')
            this.Notify.AddText('Center x290 yp vslash', '/')

        this.Notify.SetFont('s20')
            this.Notify.AddText('Center x+0 yp-6 vrightBracket', '>')

        this.Notify.SetFont('s11')
            this.Notify.AddText('x33 y+8 w264 Center vmessage')


        this.Notify.Show('xCenter y0 AutoSize NoActivate Hide')


        this.Notify.GetPos(,, &width, &height)
        this.clickToDismiss := this.Notify.AddText('x0 y0 w' width ' h' height ' vclick BackgroundTrans')
        this.clickToDismiss.OnEvent('Click', (*) => this.HideNotificationIfVisible())
        this.clickToDismiss.tooltipNotify := ''

        WinSetRegion('0-0 w' width ' h' height ' r15-15', this.Notify)  ; round the corners

        WinSetTransparent(0, this.Notify)


        OnMessage(0x200, this.HoverShowFullMessage)
    }


    static HideNotificationIfVisible(*)
    {
        if WinExist('ahk_id ' this.Notify.Hwnd)
        {
            SetTimer(this.fadeOut, 0)
            this.prevHwnd := 0
            WinSetTransparent(0, this.Notify)
            this.Notify.Hide()
            ToolTip()
        }
    }
}