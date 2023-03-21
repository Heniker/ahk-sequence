SetCapsLockState("AlwaysOff")

CapsLock & f::{
	CreateSequence := SequenceRegister()

  CreateSequence("test", (*) => MsgBox("test"))
  CreateSequence("hello", (*) => 0)
  CreateSequence("world", (*) => 0)
  CreateSequence("magic", (*) => 0)
  CreateSequence("42", (*) => 0)
}

SequenceRegister(wantUi := true) {
	; #todo> Allow keys other than chars in sequences

	inputLen := 0
	actions := Map()
	hasSuccess := false

	currentInput := ""
	currentItems := []
	ui := wantUi && CanShowUi() ? MakeUi(&currentItems, &currentInput) : (*) => 0

	setTimer(ui, -1)

	return SequenceClosure

	SequenceClosure(seq := "", ActionCb := () => true) {
		currentItems.Push(seq)
		if (actions.Count = 0) {
			h := InputHook("B I")
			h.KeyOpt("{All}", "N")
			h.OnKeyDown := KeyDownHandler
			h.NotifyNonText := true
			h.Start()
		}

		actionKey := actions.Count
		actions.Set(actionKey, Action)

		return

		Action(hook, VK, SC) {
			if (GetKeyName(Format("vk{:x}sc{:x}", VK, SC)) = SubStr(seq, inputLen, 1) && inputLen < StrLen(seq)) {
				return
			}

			if (GetKeyName(Format("vk{:x}sc{:x}", VK, SC)) = SubStr(seq, inputLen, 1) && inputLen = StrLen(seq)) {
				ActionCb()
				hasSuccess := true
				ui("close")
				SoundBeep 500, 500
			}

			if (actions.Count = 1) { ; All actions finished
				hook.Stop()
				ui("close")

				if (!hasSuccess) {
					; Send("{Blind}" . Format("{{}vk{:x}sc{:x}{}}", VK, SC)) ; Repeat missed key
					SoundBeep 3000, 250
				}

				return
			}

			actions.delete(actionKey)
		}
	}

	KeyDownHandler(hook, VK, SC) {
		inputLen++
		currentInput := currentInput . GetKeyName(Format("vk{:x}sc{:x}", VK, SC))
		for key, value in actions.Clone() {
			value(hook, VK, SC)
		}
		ui()
	}

	static CanShowUi() {
		ptr := Buffer(A_PtrSize)
		; dll call returns pointer to int
		; https://learn.microsoft.com/en-us/windows/win32/api/shellapi/ne-shellapi-query_user_notification_state
		dllCall("shell32.dll\SHQueryUserNotificationState", "Ptr", ptr)
		; NumGet implicitly converts inner-pointer to int
		return  NumGet(ptr, 0, "Int") = 5
	}
}

MakeUi(suggestionsRef, needleRef, cb := () => 0) {
	static xSize := 350
	static ySize := 60
	static maxSize := xSize / 8 ; Symbol to pixel ratio (kinda)

	static wrapper := CreateWrapper()
	static main := CreateMain(wrapper)
	; Spaces are required to set expected width, so that future Text edits work correctly
	static mainOutput := main.Add("Text","r1 ys", "______________________________________________________________")
	static statusBar := CreateStatusBar(main)

	statusBarItems := CreateStatusBarItems(statusBar)
	statusBarItemsMap := Map()
	hightlightedIndex := 0
	isClosed := false
	suggestions := %suggestionsRef%

	Update()
	return Update

	Update(arg := "") {
		if (isClosed || !IsSet(suggestions) || suggestions.Length = 0) {
			return
		}

		needle := %needleRef%
		suggestions := StrSplit(Sort(ArrToString(suggestions, ","), "D,", (a,b,*) =>
			(SubStr(b, strLen(needle), 1) = SubStr(needle, strLen(needle), 1)) - (SubStr(a, strLen(needle), 1) = SubStr(needle, strLen(needle), 1))
			), ",")

		if (arg = "close") {
			wrapper.Hide()
			main.Hide()
			statusBar.Hide()
			statusBarItems.Hide()
			isClosed := true
			return
		}

		if (arg = "right") {
			if (hightlightedIndex < suggestions.Length) {
				statusBarItemsMap.Get(suggestions[hightlightedIndex]).Opt("c16181C")
				statusBarItemsMap.Get(suggestions[hightlightedIndex + 1]).Opt("c3CAB70")
			}
			return
		}

		if (arg = "left") {
			if (hightlightedIndex > 1) {
				statusBarItemsMap.Get(suggestions[hightlightedIndex]).Opt("c16181C")
				statusBarItemsMap.Get(suggestions[hightlightedIndex - 1]).Opt("c3CAB70")
			}
			return
		}

		_ := statusBarItems
		SetTimer(() => _.Destroy(), -1) ; Makes transition a bit smoother

		statusBarItems := CreateStatusBarItems(statusBar)
		statusBarItemsMap.Clear()
		sizeCnt := 0

		for (_, it in suggestions) {
			if (sizeCnt > maxSize) {
				break
			}
			sizeCnt += StrLen(it) + 1.5
			statusBarItemsMap.Set(it, statusBarItems.Add("Text", "r1 ys", it))
		}

		mainOutput.Text := needle
		highlightedIndex := 1
		statusBarItemsMap.Get(suggestions[1]).Opt("c3CAB70")

		wrapper.Show("NoActivate")
		main.Show("NoActivate")
		statusBar.Show("NoActivate")
		statusBarItems.Show("NoActivate")
	}

	static CreateWrapper() {
		wrapper := Gui("+AlwaysOnTop +Disabled -SysMenu -Caption +LastFound +Owner","Wrapper")
		wrapper.BackColor := "393535"
		WinSetTransparent(190)
		wrapper.Show("NoActivate")
		wrapper.Move(A_ScreenWidth / 2 - xSize/2, 10, xSize, ySize)
		wrapper.Hide()
		return wrapper
	}

	static CreateMain(wrapper) {
		main := Gui("+AlwaysOnTop +Disabled -SysMenu -Caption +LastFound","Main")
		main.Opt("+Owner" wrapper.Hwnd)
		main.BackColor := "5A5A5A"
		WinSetTransparent(190)
		main.Show("NoActivate")
		main.Move(A_ScreenWidth / 2 - (xSize-15)/2, 15, xSize-15, ySize - 10)
		main.Hide()
		main.SetFont("s10 cWhite w800", "Segoe UI")
		main.Add("Text","r1 section", "▷")
		main.SetFont("s10 w600", "Segoe UI") ; c1C1E21 ?

		return main
	}

	static CreateStatusBar(main) {
		statusBar := Gui("+AlwaysOnTop +Disabled -SysMenu -Caption +LastFound","BetterStatusBar") ; "c808080 +Theme +Background525151"
		statusBar.Opt("+Owner" main.Hwnd)
		statusBar.BackColor := "393535"
		statusBar.Show("NoActivate")
		statusBar.Move(A_ScreenWidth / 2 - (xSize-15)/2, ySize - 15, (xSize-15), 20)
		statusBar.Hide()
		
		return statusBar
	}

	static CreateStatusBarItems(statusBar) {
		textElements := Gui("+AlwaysOnTop +Disabled -SysMenu -Caption +LastFound","BetterStatusBarItems")
		textElements.Opt("+Owner" statusBar.Hwnd)
		textElements.BackColor := "393535"
		WinSetTransparent(190)
		textElements.Show("NoActivate")
		textElements.Move(A_ScreenWidth / 2 - (xSize-15)/2, ySize - 15, (xSize-15), 20)
		textElements.Hide()
		textElements.SetFont("s8 c1F2023 w600", "Segoe UI")
		textElements.Add("Text", "r1 section y+4 x+-20", "")

		return textElements
	}

	; ----------

	static ArrToString(arr, sep := ",") {
		str := ""
		for (_, val in arr) {
			str .= sep . val
		}
		return LTrim(str, sep)
	}
}