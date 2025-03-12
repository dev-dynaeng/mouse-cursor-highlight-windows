#Requires AutoHotkey v2.0
#Include "./Utils.ahk"
#SingleInstance Force
#MaxThreadsPerHotkey 3
#UseHook
#MaxHotkeysPerInterval 100

SetBatchLines -1
SetWinDelay -1
CoordMode "Mouse", "Screen"
SetWorkingDir A_ScriptDir

global ClickEvents := []

SetupMouseSpotlight() {
    global SETTINGS
    SETTINGS := ReadConfigFile("settings.ini")
    InitializeSpotlightGUI()
}

InitializeSpotlightGUI() { 
    global CursorSpotlightHwnd, SETTINGS, CursorSpotlightDiameter
    if (SETTINGS.cursorSpotlight.enabled == true) { 
        CursorSpotlightDiameter := SETTINGS.cursorSpotlight.spotlightDiameter
        spotlightOuterRingWidth := SETTINGS.cursorSpotlight.spotlightOuterRingWidth
        
        CursorSpotlightWindow := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        CursorSpotlightWindow.BackColor := SETTINGS.cursorSpotlight.spotlightColor
        CursorSpotlightHwnd := CursorSpotlightWindow.Hwnd
        CursorSpotlightWindow.Show("x0 y0 w" CursorSpotlightDiameter " h" CursorSpotlightDiameter " NA")
        WinSetTransparent SETTINGS.cursorSpotlight.spotlightOpacity, "ahk_id " CursorSpotlightHwnd
        
        ; Create a ring region to highlight the cursor
        finalRegion := DllCall("CreateEllipticRgn", "Int", 0, "Int", 0, "Int", CursorSpotlightDiameter, "Int", CursorSpotlightDiameter)
        if (spotlightOuterRingWidth < CursorSpotlightDiameter/2) {
            inner := DllCall("CreateEllipticRgn", "Int", spotlightOuterRingWidth, "Int", spotlightOuterRingWidth, "Int", CursorSpotlightDiameter-spotlightOuterRingWidth, "Int", CursorSpotlightDiameter-spotlightOuterRingWidth)
            DllCall("CombineRgn", "UInt", finalRegion, "UInt", finalRegion, "UInt", inner, "Int", 3) ; RGN_XOR = 3                                      
            DllCall("DeleteObject", "UInt", inner)
        }
        DllCall("SetWindowRgn", "UInt", CursorSpotlightHwnd, "UInt", finalRegion, "UInt", true)
        SetTimer DrawSpotlight, 10
        return
    }
}

DrawSpotlight() {            
    ; SETTINGS.cursorSpotlight.enabled can be changed by other script such as Annotation.ahk
    if (SETTINGS.cursorSpotlight.enabled == true) {
        MouseGetPos(&X, &Y)
        X -= CursorSpotlightDiameter / 2
        Y -= CursorSpotlightDiameter / 2
        WinMove X, Y, , , "ahk_id " CursorSpotlightHwnd
        WinSetAlwaysOnTop true, "ahk_id " CursorSpotlightHwnd
    } else {
        WinMove -999999999, -999999999, , , "ahk_id " CursorSpotlightHwnd
    }
}

SetupMouseSpotlight()