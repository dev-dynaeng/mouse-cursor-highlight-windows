#Requires AutoHotkey v2.0
#Include "./Utils.ahk"
#SingleInstance Force
#MaxThreadsPerHotkey 3
#UseHook

A_MaxHotkeysPerInterval := 100

SetBatchLines "-1"
SetWinDelay "-1"
CoordMode "Mouse", "Screen"

global ClickEvents := []
global AlreadyCreatedRegionForRipples := Map()
global IsStillDrawingRipples := false

SetupMouseClickRipple() {
    global SETTINGS, ClickRippleWindowWidth
    
    SETTINGS := ReadConfigFile("settings.ini") 
    InitializeClickRippleGUI() 

    if (SETTINGS.cursorLeftClickRippleEffect.enabled = true) { 
        Hotkey "~*LButton", ProcessMouseClick
    }
    if (SETTINGS.cursorRightClickRippleEffect.enabled = true) {
        Hotkey "~*RButton", ProcessMouseClick
    }
    if (SETTINGS.cursorMiddleClickRippleEffect.enabled = true) {
        Hotkey "~*MButton", ProcessMouseClick
    }
}

InitializeClickRippleGUI() { 
    global ClickRippleWindowHwnd, ClickRippleWindowWidth
    
    MouseClickRippleWindow := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20") ;+E0x20 click thru    
    ClickRippleWindowHwnd := MouseClickRippleWindow.Hwnd
    
    ClickRippleWindowWidth := Max(SETTINGS.cursorLeftClickRippleEffect.rippleDiameterStart
        , SETTINGS.cursorLeftClickRippleEffect.rippleDiameterEnd
        , SETTINGS.cursorMiddleClickRippleEffect.rippleDiameterStart
        , SETTINGS.cursorMiddleClickRippleEffect.rippleDiameterEnd
        , SETTINGS.cursorRightClickRippleEffect.rippleDiameterStart
        , SETTINGS.cursorRightClickRippleEffect.rippleDiameterEnd) + 2

    Return
}

ProcessMouseClick(*) {
    global SETTINGS, ClickEvents
    local params
    
    if (InStr(A_ThisHotkey, "LButton")) {
        params := SETTINGS.cursorLeftClickRippleEffect 
    } else if (InStr(A_ThisHotkey, "MButton")) {
        params := SETTINGS.cursorMiddleClickRippleEffect 
    } else if (InStr(A_ThisHotkey, "RButton")) { 
        params := SETTINGS.cursorRightClickRippleEffect 
    }
    
    ; Add an event to the event array and call the DrawRipple function.
    MouseGetPos(&mousePositionX, &mousePositionY)

    params.mousePositionX := mousePositionX
    params.mousePositionY := mousePositionY
    ClickEvents.Push(params)
    CheckToDrawNextClickEvent()
}

CheckToDrawNextClickEvent() { 
    global IsStillDrawingRipples, ClickEvents, ClickRippleWindowWidth, ClickRippleWindowHwnd
    
    if (IsStillDrawingRipples || ClickEvents.Length == 0) {
        Return
    }

    ; Get the first event from the ClickEvents array and then delete it
    global RippleEventParams := ClickEvents[1]
    ClickEvents.RemoveAt(1)

    if (RippleEventParams.playClickSound == true) {
        SoundPlay A_ScriptDir "\MouseClickSound.wav"
    }

    IsStillDrawingRipples := true
    global CurrentRippleDiameter := RippleEventParams.rippleDiameterStart
    global CurrentRippleAlpha := RippleEventParams.rippleAlphaStart
    global TotalCountOfRipples := Abs(Round((RippleEventParams.rippleDiameterEnd - RippleEventParams.rippleDiameterStart) / RippleEventParams.rippleDiameterStep))
    global RippleAlphaStep := Round((RippleEventParams.rippleAlphaEnd - RippleEventParams.rippleAlphaStart) / TotalCountOfRipples)

    global RippleWindowPositionX := RippleEventParams.mousePositionX - Round(ClickRippleWindowWidth/2)
    global RippleWindowPositionY := RippleEventParams.mousePositionY - Round(ClickRippleWindowWidth/2) 
    
    MouseClickRippleWindow := Gui("MouseClickRippleWindow")
    MouseClickRippleWindow.BackColor := RippleEventParams.rippleColor
    MouseClickRippleWindow.Show("x" RippleWindowPositionX " y" RippleWindowPositionY " w" ClickRippleWindowWidth " h" ClickRippleWindowWidth " NoActivate")
    
    global AlreadyDrawnRipples := 0 
    SetTimer DRAW_RIPPLE, RippleEventParams.rippleRefreshInterval
}

DRAW_RIPPLE() {
    global CurrentRippleDiameter, CurrentRippleAlpha, AlreadyDrawnRipples, RippleEventParams
    global TotalCountOfRipples, RippleAlphaStep, RippleWindowPositionX, RippleWindowPositionY
    global ClickRippleWindowWidth, ClickRippleWindowHwnd
    global IsStillDrawingRipples, AlreadyCreatedRegionForRipples
    
    local regionKey := RippleEventParams.rippleColor "," CurrentRippleDiameter
    local finalRegion
    
    if (AlreadyCreatedRegionForRipples.Has(regionKey)) {
        finalRegion := AlreadyCreatedRegionForRipples[regionKey]
    } else {
        local outerRegionTopLeftX := Round((ClickRippleWindowWidth-CurrentRippleDiameter)/2)
        local outerRegionTopLeftY := Round((ClickRippleWindowWidth-CurrentRippleDiameter)/2)
        local outerRegionBottomRightX := outerRegionTopLeftX + CurrentRippleDiameter
        local outerRegionBottomRightY := outerRegionTopLeftY + CurrentRippleDiameter
        local innerRegionTopLeftX := outerRegionTopLeftX + RippleEventParams.rippleLineWidth
        local innerRegionTopLeftY := outerRegionTopLeftY + RippleEventParams.rippleLineWidth
        local innerRegionBottomRightX := outerRegionBottomRightX - RippleEventParams.rippleLineWidth
        local innerRegionBottomRightY := outerRegionBottomRightY - RippleEventParams.rippleLineWidth 
        
        finalRegion := DllCall("CreateEllipticRgn", "Int", outerRegionTopLeftX, "Int", outerRegionTopLeftY, "Int", outerRegionBottomRightX, "Int", outerRegionBottomRightY)
        local inner := DllCall("CreateEllipticRgn", "Int", innerRegionTopLeftX, "Int", innerRegionTopLeftY, "Int", innerRegionBottomRightX, "Int", innerRegionBottomRightY)
        DllCall("CombineRgn", "UInt", finalRegion, "UInt", finalRegion, "UInt", inner, "Int", 3) ; RGN_XOR = 3                              
        DeleteObject(inner)
    }

    DllCall("SetWindowRgn", "UInt", ClickRippleWindowHwnd, "UInt", finalRegion, "UInt", true)
    WinSetTransparent CurrentRippleAlpha, "ahk_id " ClickRippleWindowHwnd
    DeleteObject(finalRegion)        
    
    ; Clone the current region and save it for the next usage
    local clonedRegion := DllCall("CreateRectRgn", "Int", 0, "Int", 0, "Int", 0, "Int", 0)
    local RegionType := DllCall("GetWindowRgn", "UInt", ClickRippleWindowHwnd, "UInt", clonedRegion)
    AlreadyCreatedRegionForRipples[regionKey] := clonedRegion 
    
    CurrentRippleAlpha := CurrentRippleAlpha + RippleAlphaStep        
    if (RippleEventParams.rippleDiameterEnd > RippleEventParams.rippleDiameterStart) {
        CurrentRippleDiameter := CurrentRippleDiameter + Abs(RippleEventParams.rippleDiameterStep)
    } else {
        CurrentRippleDiameter := CurrentRippleDiameter - Abs(RippleEventParams.rippleDiameterStep)
    }
    
    AlreadyDrawnRipples++
    if (AlreadyDrawnRipples >= TotalCountOfRipples) {
        IsStillDrawingRipples := false
        SetTimer DRAW_RIPPLE, 0
        MouseClickRippleWindow := Gui("MouseClickRippleWindow")
        MouseClickRippleWindow.Hide()
        ; Trigger the function again to check if there are other mouse click events waiting to be drawn
        CheckToDrawNextClickEvent()
    }
}

SetupMouseClickRipple()