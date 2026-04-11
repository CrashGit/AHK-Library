#Include WinEvent.ahk

SetWinDelay(-1)


;---------------------------------------------
;--------------Window Management--------------
;---------------------------------------------
class Window {
	static underMouse => (MouseGetPos(,, &winUnderMouse), winUnderMouse) ; doesn't rely on Mouse class

	; windows (by class name) to ignore (taskbar, secondary taskbar, desktop, ahk guis, alt-tab menu)
	static exceptions := '(Shell_TrayWnd|Shell_SecondaryTrayWnd|WorkerW|AutoHotkeyGUI|XamlExplorerHostIslandWindow|TaskListThumbnailWnd|tooltips_class32|#32768|#32770)'
	static criteria => ['A']
	; static lastFound {
	; 	get => super('A')
	; 	set {
	; 		if value is Window {
	; 			this.DefineProp('LastFound', {Get: (*) => value})
	; 		}
	; 	}
	; }
	; static lastFound 	:= this.criteria
	static active := WinExist('A')
	static lastFound := 0
	static excludeTitle => ''	; append to instance exludeTitle
	static excludeText  => ''	; append to instance excludeText

	lastFound 		=> WinGetIDLast(this.criteria*)
	title 			=> WinGetTitle(this.criteria*)
	hwnd 			=> WinGetID(this.criteria*)
	id 				=> WinGetID(this.criteria*)
	pid 			=> WinGetPID(this.criteria*)
	className		=> WinGetClass(this.criteria*)

	isMinimized 	=> WinGetMinMax(this.criteria*) = -1	; check if window is minimized
	isMaximized		=> WinGetMinMax(this.criteria*) = 1		; check if window is maximized

	isActive		=> WinActive(this.criteria*)
	exists			=> WinExist(this.criteria*)

	processPath 	=> WinGetProcessPath(this.criteria*)	; get window's process path
	processName 	=> WinGetProcessName(this.criteria*)	; get window's process name
	count			=> WinGetCount(this.criteria*)			;
	controls		=> WinGetControls(this.criteria*)		; returns an array of names (ClassNNs) for all controls in the specified window
	controlsHwnd	=> WinGetControlsHwnd(this.criteria*)	; returns an array of unique ID numbers (HWNDs) for all controls in the specified window
	text			=> WinGetText(this.criteria*)			; retrieves the text from the specified window
	style			=> WinGetStyle(this.criteria*)
	exStyle			=> WinGetExStyle(this.criteria*)
	transColor		=> WinGetTransColor(this.criteria*)
	alwaysOnTop		=> WinGetAlwaysOnTop(this.criteria*)
	enabled 		=> this.style & 0x8000000

	dpi 			=> DllCall('User32\GetDpiForWindow', 'Ptr', WinExist(this.criteria*), 'UInt')

	transparency {
		get => WinGetTransparent(this.criteria*)
		set => this.SetTransparency(value, this.criteria*)
	}

	x 				=> (this.GetPos(&x), x)					; x position of window
	y 				=> (this.GetPos(, &y), y)				; y position of window
	width 			=> (this.GetPos(,, &w), w)				; width of window
	height			=> (this.GetPos(,,, &h), h)				; height of window

	right			=> (this.GetPos(&x,, &w),   x + w)      ; right side position of window
	bottom      	=> (this.GetPos(, &y,, &h), y + h)     	; bottom side position of window
	centerX     	=> (this.GetPos(&x,, &w),   x + (w//2))	; center x
	centerY     	=> (this.GetPos(, &y,, &h), y + (h//2))	; center y

	; @aliases
	left        	=> this.x                       		; alias for x
	top         	=> this.y                       		; alias for y
	l           	=> this.x                   			; alias for left
	r           	=> this.right      						; alias for right
	t           	=> this.y                   			; alias for top
	b           	=> this.bottom     						; alias for bottom
	w           	=> this.width               			; alias for width
	h           	=> this.height              			; alias for height

	Reposition  	=> Window.Reposition(this)
	Resize 			=> Window.Resize(this)


	static __Get(key, *) {
		try return Window('A').%key%
	}
	static __Call(name, params) {
		try return Window('A').%name%(params*)
	}


	static MinimizeAll() {
		WinMinimizeAll()
		return this
	}

	static MinimizeAllUndo() {
		WinMinimizeAllUndo()
		return this
	}

	static FromPoint(x, y) {
		static GWL_EXSTYLE := -20,
			WS_EX_TOOLWINDOW := 0x00000080,
			GW_OWNER := 4

		; pack POINT into 64-bit (high dword = y, low dword = x)
		pack := (x & 0xFFFFFFFF | y << 32)

		; get innermost hwnd under the point
		hwnd := DllCall("user32\WindowFromPoint", "Int64", pack, "ptr")
		if !hwnd {
			return 0
		}

		; jump to top-level ancestor
		top := DllCall("user32\GetAncestor", "ptr", hwnd, "uint", 2, "ptr") ; GA_ROOT = 2
		candidate := top

		; walk owner chain; return first visible & not-toolwindow top-level
		while candidate {
			if DllCall("user32\IsWindowVisible", "ptr", candidate, "int") {
				ex := DllCall("user32\GetWindowLongPtr", "ptr", candidate, "int", GWL_EXSTYLE, "ptr")
				if !(ex & WS_EX_TOOLWINDOW) {
					return candidate
				}
			}

			; move to owner (skip to owner if this one is a tool/hidden)
			candidate := DllCall("user32\GetWindow", "ptr", candidate, "uint", GW_OWNER, "ptr")
		}

		return 0
	}


	static Call(winTitle?, winText?, excludeTitle?, excludeText?) {
		hwnd := WinExist(winTitle?, winText?, excludeTitle?, excludeText?)

		if !hwnd || Window.IsException(hwnd) {
			Window.ErrorTooltip('Window not found or is an exception.')
		}

		return super(winTitle?, winText?, excludeTitle?, excludeText?)
	}

	__New(winTitle?, winText?, excludeTitle?, excludeText?) {
		if IsSet(winTitle) && Type(winTitle) = 'Integer' {
			this.criteria := [winTitle]
		} else {
			this.criteria := [winTitle?, winText?, excludeTitle?, excludeText?]
		}

		this.events := []
		uncountedRef := ObjPtr(this)

		this.events.Push(WinEvent.MoveEnd((*) {
			; Can't use 'this' because then the function definition expression contains a reference that can never decrement.
			; My understanding of why this works is ObjFromPtr returns the object from the address but until it is saved, it is just considered some object retrieved from memory.
			; Once it is saved, it is then seen as a proper object created by ahk and reference counting can properly be taken into account.
			; So AddRef increments the count, and scope loss naturally decrements it, bringing reference count back to equililbrium.
			try ObjFromPtrAddRef(uncountedRef).SavePosition()
		}, winTitle?,, winText?, excludeTitle?, excludeText?))
	}

	__Delete() {
		; Window.ErrorTooltip('Window released:`n' this.title ?? 'Unknown title')

		for event in this.events {
			event.Stop()
		}
	}

	GetPos(&x?, &y?, &w?, &h?) {
		try {
			WinGetPos(&x, &y, &w, &h, this.criteria*)
		} catch {
			Window.ErrorTooltip('Window not found.')
		}

		return this
	}


	GetClientPos(&x?, &y?, &w?, &h?) {
		try {
			WinGetClientPos(&x, &y, &w, &h, this.criteria*)
		} catch {
			Window.ErrorTooltip('Window not found.')
		}

		return this
	}

	/**
	 * @author plankoe
	 * @source https://old.reddit.com/r/AutoHotkey/comments/14xjya7/force_window_size_and_position/
	 */
	GetPosWithoutExtendedFrameBounds(&x?, &y?, &w?, &h?) {
		static DWMWA_EXTENDED_FRAME_BOUNDS := 9
		hwnd := this.hwnd

		if !hwnd is Integer {
			hwnd := WinExist(hwnd)
		}

		DllCall(
			'dwmapi\DwmGetWindowAttribute',
			'Ptr' , hwnd,
			'UInt', DWMWA_EXTENDED_FRAME_BOUNDS,
			'Ptr' , RECT := Buffer(16, 0),
			'Int' , RECT.size,
			'UInt'	; return unsigned int
		)

		x := NumGet(RECT,  0, 'Int')
		y := NumGet(RECT,  4, 'Int')
		w := NumGet(RECT,  8, 'Int') - x
		h := NumGet(RECT, 12, 'Int') - y

		return this
	}

	GetCenterPos(&x?, &y?) {
		WinGetPos(&x, &y, &w, &h, this.criteria*)
		x := x + (w // 2)
		y := y + (h // 2)
		return this
	}


	ReturnCoords() {
		return {
			x:       this.x,
			y:       this.y,
			width:   this.width,
			height:  this.height,
			right:   this.right,    ; right side position of window
			bottom:  this.bottom,   ; bottom side position of window
			centerX: this.centerX,	; center x
			centerY: this.centerY,  ; center y
		}
	}


	/**
	 * @Win_Functions
	 */

	Close(secondsToWait?) {
		criteria := this.criteria.Clone()
		criteria.InsertAt(3, secondsToWait?)
		WinClose(criteria*)
		return this
	}

	Kill(secondsToWait?) {
		criteria := this.criteria.Clone()
		criteria.InsertAt(3, secondsToWait?)
		WinKill(criteria*)
		return this
	}

	Activate() {
		WinActivate(this.criteria*)
		return this
	}

	ActivateBottom() {
		WinActivateBottom(this.criteria*)
		return this
	}

	Minimize() {
		WinMinimize(this.criteria*)
		return this
	}

	Maximize() {
		WinMaximize(this.criteria*)
		return this
	}

	Hide() {
		WinHide(this.criteria*)
		return this
	}

	Show() {
		WinShow(this.criteria*)
		return this
	}

	WaitClose(timeout?) {
		criteria := this.criteria.Clone()
		criteria.InsertAt(3, timeout?)
		WinWaitClose(criteria*)
		return this
	}

	WaitActive(timeout?) {
		criteria := this.criteria.Clone()
		criteria.InsertAt(3, timeout?)
		WinWaitActive(criteria*)
		return this
	}

	WaitNotActive(timeout?) {
		criteria := this.criteria.Clone()
		criteria.InsertAt(3, timeout?)
		WinWaitNotActive(criteria*)
		return this
	}

	WaitExist(timeout?) {
		criteria := this.criteria.Clone()
		criteria.InsertAt(3, timeout?)
		WinWait(criteria*)
		return this
	}

	SetTransColor(color) {
		WinSetTransColor(color, this.criteria*)
		return this
	}

	SetTitle(newTitle) {
		WinSetTitle(newTitle, this.criteria*)
		return this
	}

	SetStyle(value) {
		WinSetStyle(this.criteria*)
		return this
	}

	SetExStyle(value) {
		WinSetExStyle(this.criteria*)
		return this
	}

	SetRegion(options) {
		WinSetRegion(options, this.criteria*)
		return this
	}

	SetEnabled(newSetting) {
		WinSetEnabled(newSetting, this.criteria*)
		return this
	}

	SetAlwaysOnTop(newSetting := true) {
		WinSetAlwaysOnTop(newSetting, this.criteria*)
	}

	Restore() {
		WinRestore(this.criteria*)
		return this
	}

	Redraw() {
		WinRedraw(this.criteria*)
		return this
	}

	MoveTop() {
		WinMoveTop(this.criteria*)
		return this
	}

	MoveBottom() {
		WinMoveBottom(this.criteria*)
		return this
	}

	Move(x?, y?, width?, height?) {
		WinMove(x?, y?, width?, height?, this.criteria*)
		return this
	}

	Position(x?, y?) {
		WinMove(x?, y?,,, this.criteria*)
		return this
	}

	; Resize(width?, height?) {
	; 	WinMove(,, width?, height?, this.criteria*)
	; 	return this
	; }

	; what values should toggle swap?
	ToggleTransparency() {
		if WinGetTransparent(this.hwnd) != 255 {
			WinSetTransparent(255, this.hwnd)
		} else {
			WinSetTransparent(128, this.hwnd)
		}
		return this
	}

	AdjustTransparency(value) {		; increase/decrease transparency value with +/- value
		value := this.transparency + value
		this.SetTransparency(value)
		return this
	}

	IncreaseTransparency(value) {	; increase transparency with value
		value := this.transparency + Abs(value)
		this.SetTransparency(value)
		return this
	}

	DecreaseTransparency(value) {	; decrease transparency with value
		value := this.transparency - Abs(value)
		this.SetTransparency(value)
		return this
	}

	SetTransparency(value) {		; set explicit transparency value
		value := this.ClampTransparency(value)
		WinSetTransparent(value, this.hwnd)
		return this
	}

	; should minimum value be 1?
	ClampTransparency(value) => Min(255, Max(0, value))    ; confines value to minimum and maximum possible transparency values

	Fade(time := 1000, final_transparency := 255) {
		transparency := this.transparency

		if transparency < final_transparency {
			this.FadeIn(time, final_transparency)
		} else if transparency > final_transparency {
			this.FadeOut(time, final_transparency)
		}
	}


	/**
	 * @param {Integer} time how long it takes for window to go from current transparency to final transparency
	 * @param {Integer 0-255} final_transparency transparency of window by end of fade
	 */
	FadeIn(time := 1000, final_transparency := 255) {
		transparency := this.transparency
		difference := final_transparency - transparency

		if difference <= 0 {
			return
		}

		div := time // 1000
		; variance := Round(time / difference) // div * 2      ; how much to increase transparency
		; speed    := Ceil(difference / variance) * div * 2    ; how many iterations to perform
		variance := Round(time / difference)      ; how much to decrease transparency
		speed    := Ceil(difference / variance)   ; how many iterations to perform
		; ToolTip(variance '`n' speed)

		loop speed {
			this.IncreaseTransparency(variance)
			Sleep(div)
		}
		this.transparency := final_transparency
	}


	/**
	 * @param {Integer} time how long it takes for window to go from current transparency to final transparency
	 * @param {Integer 0-255} final_transparency transparency of window by end of fade
	 */
	FadeOut(time := 1000, final_transparency := 0) {
		transparency := this.transparency
		difference := transparency - final_transparency

		if difference <= 0 {
			return
		}
		div := time // 1000
		iters := Round(time / difference) // div      ; how much to decrease transparency
		speed := Ceil(difference / iters) * div   ; how many iterations to perform
		ToolTip(iters '`n' speed)
		start := A_TickCount
		loop speed {
			this.DecreaseTransparency(1)
			Sleep(iters)
		}
		ToolTip(A_TickCount - start)
		this.transparency := final_transparency
		; transparency := this.GetTransparency()
		; difference := transparency - final_transparency

		; if difference <= 0 {
		;    return
		; }
		; div := time // 1000
		; ; variance := Round(time / difference) // div * 2     ; how much to increase transparency
		; ; speed    := Ceil(difference / variance) * div * 2  ; how many iterations to perform
		; variance := Round(time / difference)      ; how much to decrease transparency
		; speed    := Ceil(difference / variance)   ; how many iterations to perform
		; ToolTip(variance '`n' speed)

		; loop speed {
		;    this.DecreaseTransparency(variance)
		;    Sleep(div)
		; }
		; this.transparency := final_transparency
	}

	Send(keys, controlID?) {
		ControlSend(keys, controlID?, this.criteria*)
		return this
	}

	SendText(keys, controlID?) {
		ControlSendText(keys, controlID?, this.criteria*)
		return this
	}

	GetDpi() {
		return DllCall('User32\GetDpiForWindow', 'Ptr', WinExist(this.criteria*), 'UInt')
	}


	/**
	 * @Class_Methods
	 */


	static IsException(id := 'A') => WinExist(id) ? InStr(this.exceptions, WinGetClass(id)) : 0


	/**
	 * @description similar to WinGetList but has option to look for windows on a specified monitor
	 * @param {Number} mon
	 * @param winTitle
	 * @param winText
	 * @param excludeTitle
	 * @param {String} excludeText
	 * @returns {Array}
	 */
	static GetList(mon := -1, winTitle?, winText?, excludeTitle?, excludeText?) {
		if mon > MonitorGetCount() {                                                    		; if monitor is invalid (0 is used to get monitor based on mouse position)
			return []                                                                        	; return empty array
		}

		if mon = 0 {                                                                            ; if should use monitor mouse is on
			DllCall('GetCursorPos', 'UInt64*', &point := 0)                                     ; get cursor position as point struct
			hMonitor := DllCall('MonitorFromPoint', 'UInt64', point, 'uint', 0x2, 'Ptr')        ; get monitor handle from point struct
		} else if mon > 0 {                                                                     ; valid monitor
			hMonitorList := ''                                                                  ; initialize list for monitor handles
			if DllCall('EnumDisplayMonitors', 'Ptr', 0, 'Ptr', 0,                               ; enumerate monitors
						'Ptr', CallbackCreate(EnumMonitors, 'Fast', 4), 'UInt', 0) {
				loop parse hMonitorList, '`n' {                                                 ; loop through hMonitorList
					if mon = A_Index {                                                          ; if monitor matches index
						hMonitor := A_LoopField                                                 ; assign hMonitor to the monitor handle at that index
						break                                                                   ; end early
					}
				}
			}

			EnumMonitors(hMonitor, *) {                                                         ; used as callback to add monitor handles to hMonitorList
				hMonitorList .= hMonitor '`n'                                                   ; add monitor handle to list and newline
				return true                                                                     ; return true (necessary for callback)
			}
		}

		windowList := []                                                                        ; initialize array that saves all windows
		DetectHiddenWindows(false)                                                              ; makes IsWindowVisible and DWMWA_CLOAKED unnecessary in subsequent call to WinGetList()

		for hwnd in WinGetList(winTitle?, winText?, excludeTitle?, excludeText?) {              ; gather a list of running programs
			if mon < 0 ||
				hMonitor = DllCall('MonitorFromWindow', 'Ptr', hwnd, 'UInt', 0x2, 'Ptr') {      ; Check if the window is on the same monitor.
				windowList.Push(hwnd)
			}
		}

		return windowList                                                                       ; return list of windows
	}

	/**
	 * @description - Gets a list of windows that show up on the alt-tab window. Can specify a monitor for windows on a specific monitor.
	 *
     * @author iseahound - modernized
     * 		@source - https://www.autohotkey.com/boards/viewtopic.php?f=83&p=566016#p566016
	 *
	 * @author ophthalmos - original
	 * 		@source - https://www.autohotkey.com/boards/viewtopic.php?t=13288*
	 *
	 * @author crash - heavily modified
	 *
	 * @param {Integer} [mon = -1] The monitor to retrieve alt-tab windows from. There are 3 distinct values.
	 * @values
	 *     -1 or less = All alt-tab windows.
	 *      0 or Mouse = Windows on the monitor the mouse is currently on.
	 *      1 to MonitorGetCount() = Windows on the specified monitor number.
	 *
	 * @param {Number} mon
	 * @param {String} winTitle
	 * @param {String} winText
	 * @param {String} excludeTitle
	 * @param {String} excludeText
	 * @returns {Array}
     */
	static GetAltTabList(mon := -1, winTitle?, winText?, excludeTitle?, excludeText?) {
		hMonitor := DetermineMonitor(mon)
		if !hMonitor {
			return []
		}

		DetectHiddenWindows(false)	; makes IsWindowVisible and DWMWA_CLOAKED unnecessary in subsequent call to WinGetList()
		windows := WinGetList(winTitle?, winText?, excludeTitle?, excludeText?)
		return GetValidWindows(windows)

		GetValidWindows(windows) {
			; Deprecated code I thought was needed, unless I find a reason it should exist.
			; static  WS_EX_APPWINDOW  := 0x40000	; has a taskbar button
			; if !(ex & WS_EX_APPWINDOW) {
			; 	continue
			; }
			; if WinGetClass(hwnd) = 'ApplicationManager_ImmersiveShellWindow' {		; I think this is the Gaming Bar. Excluding Program from text had weird effects with Discord if there were more than 2 (including Discord) windows on that monitor
			; 	continue
			; }
			static WS_EX_TOOLWINDOW := 0x80,
				   GA_ROOTOWNER     := 3

			AltTabList := []

			for hwnd in windows {
				if !HwndIsOnMonitor(hwnd) {
					continue
				}

				owner := DllCall('GetAncestor', 'Ptr', hwnd, 'UInt', GA_ROOTOWNER, 'Ptr')
				owner := owner || hwnd

				if DllCall('GetLastActivePopup', 'Ptr', owner) != hwnd {
					continue
				}

				ex := WinGetExStyle(hwnd)
				; don't add window to list if any of these conditions are true
				if !DllCall('IsWindowVisible', 'Ptr', hwnd)
				|| (ex & WS_EX_TOOLWINDOW)
				|| !IsWindowOnCurrentVirtualDesktop(hwnd)
				|| !HasShowInSwitcherFlag(hwnd) {
					continue
				}

				AltTabList.Push(hwnd)
			}
			return AltTabList
		}

		HwndIsOnMonitor(hwnd) {
			result := mon < 0 || hMonitor = DllCall('MonitorFromWindow', 'Ptr', hwnd, 'UInt', 0x2, 'Ptr')
			return result
		}

		IsWindowOnCurrentVirtualDesktop(hwnd) {
			static IVirtualDesktopManager := ''

			if !IVirtualDesktopManager {
				IVirtualDesktopManager := ComObject(CLSID_VirtualDesktopManager := '{AA509086-5CA9-4C25-8F95-589D3C07B48A}', IID_IVirtualDesktopManager := '{A5CD92FF-29BE-454C-8D04-D82879FB3F1B}')
			}

			ComCall(3, IVirtualDesktopManager, 'UPtr', hwnd, 'Int*', &onCurrentDesktop := 0)   ;
			return onCurrentDesktop
		}

		HasShowInSwitcherFlag(hwnd) {
			static IApplicationViewCollection := GetIApplicationViewCollection()
			try ComCall(GetViewForHwnd := 6, IApplicationViewCollection, 'UPtr', hwnd, 'Ptr*', &pView := 0)
			pView ??= 0

			if pView {
				ComCall(GetShowInSwitchers := 27, pView, 'Int*', &ShowInSwitchers := 0)
				ObjRelease(pView)
			}
			return ShowInSwitchers ?? 0

			GetIApplicationViewCollection() {
				OSbuildNumber := StrSplit(A_OSVersion, '.')[3]
				if OSbuildNumber <= 17134 {   ; Windows 10 1607 to 1803 and Windows Server 2016
					IID_IApplicationViewCollection := '{2C08ADF0-A386-4B35-9250-0FE183476FCC}'
				} else {
					IID_IApplicationViewCollection := '{1841C6D7-4F9D-42C0-AF41-8747538F10E5}'
				}

				CLSID_ImmersiveShell := '{C2F03A33-21F5-47FA-B4BB-156362A2F239}'
				IID_IUnknown := '{00000000-0000-0000-C000-000000000046}'
				ImmersiveShell := ComObject(CLSID_ImmersiveShell, IID_IUnknown)
				return ComObjQuery(ImmersiveShell, IID_IApplicationViewCollection, IID_IApplicationViewCollection)
			}
		}


		DetermineMonitor(mon) {
			switch {
			case mon = 0 || mon = 'Mouse':
				return GetHMonitorFromMouse()
			case mon > MonitorGetCount():
				return false
			case mon > 0:
				return GetHMonitorFromMon()
			default:
				return true
			}

			GetHMonitorFromMouse() {
				DllCall('GetCursorPos', 'UInt64*', &point := 0)                         ; get cursor position as point struct
				return DllCall('MonitorFromPoint', 'UInt64', point, 'UInt', 0x2, 'Ptr') ; return monitor handle from point struct
			}

			GetHMonitorFromMon() {
				hMonitorList := ''                                                      ; initialize list for monitor handles

				if EnumerateDisplays() {
					loop parse hMonitorList, '`n' {                                     ; loop through hMonitorList
						if mon = A_Index {                                              ; if monitor matches index
							return A_LoopField                                          ; hMonitor to the monitor handle at that index
						}
					}
				}

				EnumerateDisplays() {
					return DllCall('EnumDisplayMonitors',
							'Ptr', 0,
							'Ptr', 0,
							'Ptr', CallbackCreate(EnumSuccessfulCallback, 'Fast', 4),
							'UInt', 0)
				}

				EnumSuccessfulCallback(hMonitor, *) {                                	; used as callback to add monitor handles to hMonitorList
					hMonitorList .= hMonitor '`n'                                       ; add monitor handle to list and newline
					return true                                                         ; return true (necessary for callback)
				}
			}
		}
	}




	/**
	 * Do I even use this?
	 */
	__Enum(*) {
		i := 1
		list := WinGetList(this.criteria*)
		return (&hwnd) {
			if i > list.Length {
				return 0
			}

			hwnd := list[i]
			i++
		}
	}

	static ErrorTooltip(message) {
        try {
			tt := ToolTip.Bind(,,, 20)
			hwnd := tt(message)
			WinGetPos(,, &w,, 'ahk_id' hwnd)
			WinMove(A_ScreenWidth//2 - w//2, 0,,, 'ahk_id' hwnd)
			SetTimer(tt, -2000)
		}
	}

	;-------------------------------------------------------------------------------
	;-------------------------------------------------------------------------------
	;-------------------------------------------------------------------------------
	; END OF BASIC WINDOW CLASS
	; NESTED CLASSES BELOW
	;-------------------------------------------------------------------------------
	;-------------------------------------------------------------------------------
	;-------------------------------------------------------------------------------

	class Reposition {
		__New(window) {
			this.Window := window
		}

		static __Get(key, *) {
			try return Window('A').Reposition.%key%
		}
		static __Call(name, params) {
			try return Window('A').Reposition.%name%(params*)
		}

		Call(self, x?, y?) {
			this.Window.GetPosWithoutExtendedFrameBounds(&xEx, &yEx)   ; get dimensions of window without invisible border

			IsSet(x) && x := x - (xEx - this.Window.x)              ; get requested x position without invisible border offset
			IsSet(y) && y := y - (yEx - this.Window.y)              ; get requested y position without invisible border offset
			WinMove(x?, y?,,, this.Window.criteria*)                  ; move window to position

			return this
		}

		static Update() => this.Update()
	}


	class Resize {
		__New(window) {
			this.Window := window
		}

		static __Get(key, *) {
			try return Window('A').Resize.%key%
		}
		static __Call(name, params) {
			try return Window('A').Resize.%name%(params*)
		}

		Call(self, width?, height?) {
			this.Window.GetPosWithoutExtendedFrameBounds(&xEx,, &wEx, &hEx)   ; get dimensions of window without invisible border

			IsSet(width)  && width  := width  + (this.Window.width - wEx)               ; get requested x position without invisible border offset
			IsSet(height) && height := height + (this.Window.height - hEx)
			WinMove(,, width?, height?, this.Window.winTitle)

			return this
		}
	}


	; keep track of all windows at all times?
	class Registry {	; hmm
		;
	}
}