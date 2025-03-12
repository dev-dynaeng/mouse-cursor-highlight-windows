#Requires AutoHotkey v2.0
#Include "./Utils.ahk"
#SingleInstance Force
#MaxThreadsPerHotkey 3
#UseHook

A_MaxHotkeysPerInterval := 100

A_BatchLines := -1
A_WinDelay := -1
CoordMode "Mouse", "Screen"

global ClickEvents := []
global IsStillDrawingRipples := false
global RippleEventParams := Map()
global CurrentRippleDiameter := 0
global CurrentRippleAlpha := 0
global TotalCountOfRipples := 0
global RippleAlphaStep := 0
global AlreadyDrawnRipples := 0
global RippleWindowPositionX := 0
global RippleWindowPositionY := 0
global MouseClickRippleWindow := ""

SetupMouseClickRipple() {
    global SETTINGS, ClickRippleBitMapWidth, ClickRippleWindowHwnd, ClickRippleHbm
    global ClickRippleHdc, ClickRippleGraphics
    
    SETTINGS := ReadConfigFile("settings.ini") 
    InitializeClickRippleGUI() 

    if (SETTINGS["cursorLeftClickRippleEffect"]["enabled"] = true) { 
        Hotkey("~*LButton", ProcessMouseClick)
    }
    if (SETTINGS["cursorRightClickRippleEffect"]["enabled"] = true) {
        Hotkey("~*RButton", ProcessMouseClick)
    }
    if (SETTINGS["cursorMiddleClickRippleEffect"]["enabled"] = true) {
        Hotkey("~*MButton", ProcessMouseClick)
    }
}

InitializeClickRippleGUI() {
    global ClickRippleBitMapWidth, ClickRippleWindowHwnd, ClickRippleHbm
    global ClickRippleHdc, ClickRippleGraphics, MouseClickRippleWindow
    
    ; Calculate the width/height of the bitmap we are going to create
    ClickRippleBitMapWidth := Max(SETTINGS["cursorLeftClickRippleEffect"]["rippleDiameterStart"]
        , SETTINGS["cursorLeftClickRippleEffect"]["rippleDiameterEnd"]
        , SETTINGS["cursorMiddleClickRippleEffect"]["rippleDiameterStart"]
        , SETTINGS["cursorMiddleClickRippleEffect"]["rippleDiameterEnd"]
        , SETTINGS["cursorRightClickRippleEffect"]["rippleDiameterStart"]
        , SETTINGS["cursorRightClickRippleEffect"]["rippleDiameterEnd"]) + 2

    ; Start gdi+    
    if (!Gdip_Startup()) {
        MsgBox "gdiplus error!`nGdiplus failed to start. Please ensure you have gdiplus on your system", 48
        ExitApp
    }

    ; Create a layered window (+E0x80000), and it must be used with UpdateLayeredWindow() to trigger repaint.
    MouseClickRippleWindow := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x80000")
    ClickRippleWindowHwnd := MouseClickRippleWindow.Hwnd
    MouseClickRippleWindow.Show("NA")

    ; Create a gdi bitmap that we are going to draw onto.
    ClickRippleHbm := CreateDIBSection(ClickRippleBitMapWidth, ClickRippleBitMapWidth)

    ; Get a device context compatible with the screen
    ClickRippleHdc := CreateCompatibleDC()

    ; Select the bitmap into the device context
    obm := SelectObject(ClickRippleHdc, ClickRippleHbm)

    ; Get a pointer to the graphics of the bitmap
    ClickRippleGraphics := Gdip_GraphicsFromHDC(ClickRippleHdc)

    ; Set the smoothing mode to antialias = 4 to make shapes appear smother
    Gdip_SetSmoothingMode(ClickRippleGraphics, 4)

    Return
}

ProcessMouseClick(*) {
    global SETTINGS, ClickEvents
    local params
    
    if (InStr(A_ThisHotkey, "LButton")) {
        params := SETTINGS["cursorLeftClickRippleEffect"]
    } else if (InStr(A_ThisHotkey, "MButton")) {
        params := SETTINGS["cursorMiddleClickRippleEffect"]
    } else if (InStr(A_ThisHotkey, "RButton")) { 
        params := SETTINGS["cursorRightClickRippleEffect"]
    }

    ; Add an event to the event array and call the CheckToDrawNextClickEvent function.
    MouseGetPos(&rippleMousePositionX, &rippleMousePositionY)
    params["rippleMousePositionX"] := rippleMousePositionX
    params["rippleMousePositionY"] := rippleMousePositionY
    ClickEvents.Push(params)
    CheckToDrawNextClickEvent()
}

CheckToDrawNextClickEvent() { 
    global IsStillDrawingRipples, ClickEvents, ClickRippleBitMapWidth, ClickRippleWindowHwnd
    global ClickRippleHdc, ClickRippleGraphics
    global RippleEventParams, CurrentRippleDiameter, CurrentRippleAlpha
    global TotalCountOfRipples, RippleAlphaStep, RippleWindowPositionX, RippleWindowPositionY
    global AlreadyDrawnRipples
    
    if (IsStillDrawingRipples || ClickEvents.Length == 0) {
        Return
    }

    ; Get the first event from the ClickEvents array and then delete it
    RippleEventParams := ClickEvents[1]
    ClickEvents.RemoveAt(1)
    
    if (RippleEventParams["playClickSound"] == true) {
        SoundPlay(A_ScriptDir "\MouseClickSound.wav")
    }

    IsStillDrawingRipples := true

    CurrentRippleDiameter := RippleEventParams["rippleDiameterStart"]
    CurrentRippleAlpha := RippleEventParams["rippleAlphaStart"]
    TotalCountOfRipples := Abs(Round((RippleEventParams["rippleDiameterEnd"] - RippleEventParams["rippleDiameterStart"]) / RippleEventParams["rippleDiameterStep"]))
    RippleAlphaStep := Round((RippleEventParams["rippleAlphaEnd"] - RippleEventParams["rippleAlphaStart"]) / TotalCountOfRipples)

    RippleWindowPositionX := RippleEventParams["rippleMousePositionX"] - Round(ClickRippleBitMapWidth/2)
    RippleWindowPositionY := RippleEventParams["rippleMousePositionY"] - Round(ClickRippleBitMapWidth/2)

    AlreadyDrawnRipples := 0    
    SetTimer(DRAW_RIPPLE, RippleEventParams["rippleRefreshInterval"])
}

DRAW_RIPPLE() {
    global CurrentRippleDiameter, CurrentRippleAlpha, AlreadyDrawnRipples, RippleEventParams
    global TotalCountOfRipples, RippleAlphaStep, RippleWindowPositionX, RippleWindowPositionY
    global ClickRippleBitMapWidth, ClickRippleWindowHwnd, ClickRippleHdc, ClickRippleGraphics
    global IsStillDrawingRipples
    
    ; Clear the previous drawing
    Gdip_GraphicsClear(ClickRippleGraphics, 0)
    ; Create a pen with ARGB (ARGB = Transparency, red, green, blue) to draw a circle
    local alphaRGB := CurrentRippleAlpha << 24 | RippleEventParams["rippleColor"]
    local pPen := Gdip_CreatePen(alphaRGB, RippleEventParams["rippleLineWidth"])

    ; Draw a circle into the graphics of the bitmap using the pen created
    Gdip_DrawEllipse(ClickRippleGraphics
        , pPen
        , (ClickRippleBitMapWidth - CurrentRippleDiameter)/2
        , (ClickRippleBitMapWidth - CurrentRippleDiameter)/2
        , CurrentRippleDiameter
        , CurrentRippleDiameter)
    Gdip_DeletePen(pPen)        
    UpdateLayeredWindow(ClickRippleWindowHwnd, ClickRippleHdc, RippleWindowPositionX, RippleWindowPositionY, ClickRippleBitMapWidth, ClickRippleBitMapWidth) 
    
    ; Calculate necessary values to prepare for drawing the next circle
    CurrentRippleAlpha := CurrentRippleAlpha + RippleAlphaStep
    if (RippleEventParams["rippleDiameterEnd"] > RippleEventParams["rippleDiameterStart"]) {
        CurrentRippleDiameter := CurrentRippleDiameter + Abs(RippleEventParams["rippleDiameterStep"])
    } else {
        CurrentRippleDiameter := CurrentRippleDiameter - Abs(RippleEventParams["rippleDiameterStep"])
    }
    AlreadyDrawnRipples++
    if (AlreadyDrawnRipples >= TotalCountOfRipples) {
        ; All circles for one click event has been drawn
        IsStillDrawingRipples := false
        SetTimer(DRAW_RIPPLE, 0)
        Gdip_GraphicsClear(ClickRippleGraphics, 0)
        UpdateLayeredWindow(ClickRippleWindowHwnd, ClickRippleHdc, RippleWindowPositionX, RippleWindowPositionY, ClickRippleBitMapWidth, ClickRippleBitMapWidth)
        ; Trigger the function again to check if there are other mouse click events waiting to be processed
        CheckToDrawNextClickEvent()
    }
}

SetupMouseClickRipple()