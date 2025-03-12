#Requires AutoHotkey v2.0
#Include "./Utils.ahk"
#SingleInstance Force
#MaxThreadsPerHotkey 3
#UseHook

A_MaxHotkeysPerInterval := 100

SetBatchLines "-1"
SetWinDelay "-1"
CoordMode "Mouse", "Screen"

global ModifierKeyList := ["Shift", "Alt", "Ctrl", "LWin", "RWin"] 

SetupKeyStrokeOSD() {
    global SETTINGS, TheKeyStrokeOSDHwnd
    SETTINGS := ReadConfigFile("settings.ini") 
    if (SETTINGS.keyStrokeOSD.enabled == true) {
        InitializeKeyStrokeOSDGUI()
        AddHotkeysForKeyStrokeOSD()
    }
}

InitializeKeyStrokeOSDGUI() {
    global TheKeyStrokeOSDHwnd
    KeyStrokeOSDWindow := Gui("+LastFound +AlwaysOnTop -Caption +ToolWindow +E0x20")
    KeyStrokeOSDWindow.BackColor := SETTINGS.keyStrokeOSD.osdWindowBackgroundColor
    KeyStrokeOSDWindow.SetFont("s" SETTINGS.keyStrokeOSD.osdFontSize, SETTINGS.keyStrokeOSD.osdFontFamily)
    KeyStrokeOSDWindow.Add("Text", "x0 y0 center vKeyStrokeOSDTextControl c" SETTINGS.keyStrokeOSD.osdFontColor " w" SETTINGS.keyStrokeOSD.osdWindowWidth " h" SETTINGS.keyStrokeOSD.osdWindowHeight)
    TheKeyStrokeOSDHwnd := KeyStrokeOSDWindow.Hwnd
    WinSetTransparent SETTINGS.keyStrokeOSD.osdWindowOpacity, "ahk_id " TheKeyStrokeOSDHwnd
    KeyStrokeOSDWindow.Show("x" SETTINGS.keyStrokeOSD.osdWindowPositionX " y" SETTINGS.keyStrokeOSD.osdWindowPositionY " w" SETTINGS.keyStrokeOSD.osdWindowWidth " h" SETTINGS.keyStrokeOSD.osdWindowHeight " NoActivate")
    WinHide "ahk_id " TheKeyStrokeOSDHwnd 
    Return
}

AddHotkeysForKeyStrokeOSD() {
    ProcessKeyStrokeFunc := ProcessKeyStroke
    SetFormat "Integer", "hex"
    start := 0 
    Loop 227 {
        key := GetKeyName("vk" start++)
        if (key != "")
            Hotkey "~*" key, ProcessKeyStrokeFunc
    }

    for _, key in StrSplit("Up,Down,Left,Right,End,Home,PgUp,PgDn,Insert,NumpadEnter,#,^,!,+", ",") {
        Hotkey "~*" key, ProcessKeyStrokeFunc
    }

    SetFormat "Integer", "dec"

    for _, char in StrSplit("!@#$%^&*()_+:<>{}|?~" Chr(34)) {
        Hotkey "~+" char, ProcessKeyStrokeFunc
    }

    Hotkey "~*Delete", ProcessKeyStrokeFunc
}

; Global variables for ProcessKeyStroke
global PressedModifierKeys := []
global PreviouseDisplayedText := ""
global PreviouseHotkeyText := ""
global LastTickCount := 0

ProcessKeyStroke(*) { 
    global PressedModifierKeys, PreviouseDisplayedText, PreviouseHotkeyText, LastTickCount, TheKeyStrokeOSDHwnd
    
    ; SETTINGS.keyStrokeOSD.enabled can be changed by other script such as the Annotation.ahk
    if (SETTINGS.keyStrokeOSD.enabled != true) {
        Return
    }

    theKeyPressed := SubStr(A_ThisHotkey, 3)

    Switch theKeyPressed {
        Case "LControl", "RControl":
            theKeyPressed := "Ctrl" 
        Case "LShift", "RShift":
            theKeyPressed := "Shift"
        Case "LAlt", "RAlt":
            theKeyPressed := "Alt" 
    }

    if (StrLen(theKeyPressed) == 1) {
        theKeyPressed := StrUpper(theKeyPressed)
    }

    CheckAndUpdatePressedModifierKeys(PressedModifierKeys)

    ; Concatenate all modifier keys
    textForPressedModifierKeys := ""
    for index, key in PressedModifierKeys {
        if (index == 1) {
            textForPressedModifierKeys := key
        } else {
            textForPressedModifierKeys := textForPressedModifierKeys "+" key
        }
    }

    valueToUpdatePreviouseHotkeyText := PreviouseHotkeyText
    shouldDisplay := false
    shouldCheckKeyChord := true
    
    if (PressedModifierKeys.Length > 0) {
        ; At least one modifier key is pressed
        if (HasVal(PressedModifierKeys, theKeyPressed)) {
            ; Only the modifier keys pressed
            PreviouseDisplayedTextBeginningStr := SubStr(PreviouseDisplayedText, 1, StrLen(textForPressedModifierKeys))
            if (PreviouseDisplayedTextBeginningStr == textForPressedModifierKeys && A_TickCount - LastTickCount < 400) {
                ; The modifier keys are the same as the previous key combinations
                textToDisplay := PreviouseDisplayedText
                shouldCheckKeyChord := false
            } else {
                ; The modifier keys are not the same as the previous key combinations
                textToDisplay := textForPressedModifierKeys
                valueToUpdatePreviouseHotkeyText := ""                
            }
        } else {
            ; Both modifier key(s) and a non-modifier key are pressed
            textToDisplay := textForPressedModifierKeys "+" theKeyPressed
            valueToUpdatePreviouseHotkeyText := textToDisplay            
        }
    } else {
        ; There is no modifier key pressed
        textToDisplay := theKeyPressed        
        valueToUpdatePreviouseHotkeyText := ""        
    }

    LastTickCount := A_TickCount

    ; Check if it's a key chord, eg: Ctrl+K M            
    if (shouldCheckKeyChord && SETTINGS.keyStrokeOSD.osdKeyChordsRegex) {        
        possibleKeyChord := PreviouseHotkeyText " " textToDisplay
        if RegExMatch(possibleKeyChord, SETTINGS.keyStrokeOSD.osdKeyChordsRegex) {
            shouldDisplay := true
            textToDisplay := possibleKeyChord            
        }
    }
    PreviouseHotkeyText := valueToUpdatePreviouseHotkeyText

    if (!shouldDisplay) {
        ; If it's not a key chord, check if it's a single hotkey key
        if (SETTINGS.keyStrokeOSD.osdHotkeyRegex) {
            if (RegExMatch(textToDisplay, SETTINGS.keyStrokeOSD.osdHotkeyRegex)) {
                shouldDisplay := true
            }
        } else {
            shouldDisplay := true
        }
    }
    
    if (shouldDisplay) { 
        SetTimer HideOSDWindow, 0
        WinShow "ahk_id " TheKeyStrokeOSDHwnd
        KeyStrokeOSDWindow := Gui("KeyStrokeOSDWindow")
        KeyStrokeOSDWindow["KeyStrokeOSDTextControl"].Text := textToDisplay
        PreviouseDisplayedText := textToDisplay
        SetTimer HideOSDWindow, SETTINGS.keyStrokeOSD.osdDuration
    }
}

HideOSDWindow() {
    global PressedModifierKeys, PreviouseDisplayedText, PreviouseHotkeyText, TheKeyStrokeOSDHwnd
    SetTimer HideOSDWindow, 0
    PressedModifierKeys := []
    PreviouseDisplayedText := ""
    PreviouseHotkeyText := ""
    WinHide "ahk_id " TheKeyStrokeOSDHwnd
}

CheckAndUpdatePressedModifierKeys(PressedModifierKeys) {
    ; Remove the keys which are already released
    index := PressedModifierKeys.Length
    while index > 0 {
        if (!GetKeyState(PressedModifierKeys[index], "P")) {
            PressedModifierKeys.RemoveAt(index)
        }
        index--
    }

    for _, key in ModifierKeyList {
        if (GetKeyState(key, "P") && !HasVal(PressedModifierKeys, key)) {
            PressedModifierKeys.Push(key)
        }
    }
}

SetupKeyStrokeOSD()