#Requires AutoHotkey v2.0

ReadConfigFile(configFileName) {
    result := Map()
    allSections := StrSplit(IniRead(configFileName), "`n", "`r")
    for index, oneSection in allSections {
        if (oneSection = "comment") {
            continue
        }
        textInOneSection := IniRead(configFileName, oneSection)
        items := []
        lines := StrSplit(textInOneSection, ["`n"], "`r")
        for _, oneLine in lines {
            if (SubStr(oneLine, 1, 1) == "#") {
                ;Ignore comments in the ini file
                continue
            }
            keyAndValue := StrSplit(oneLine, ["="], "`r")
            items.Push(keyAndValue[1])
            items.Push(keyAndValue[2])            
        }
        
        for index2, oneItem in items {
            if (Mod(index2, 2) == 0) {
                if (oneItem = "True") {
                    items[index2] := true
                } else if (oneItem = "False") {
                    items[index2] := false
                }
            }
        }
        
        result[oneSection] := Map()
        for i := 1; i <= items.Length; i += 2 {
            if (i+1 <= items.Length) {
                result[oneSection][items[i]] := items[i+1]
            }
        }
    }
    Return result
}

Max(num*) {
    max := -9223372036854775807
    For _, val in num
        max := (val > max) ? val : max
    Return max
}

Min(num*) {
    min := 9223372036854775807
    For _, val in num
        min := (val < min) ? val : min
    Return min
}

HasVal(haystack, needle) {
    if (!IsObject(haystack) || haystack.Length = 0)
        return 0
    for index, value in haystack
        if (value = needle)
            return index
    return 0
}


; *************** The following are functions related gdi plus ***************
ReleaseDC(hdc, hwnd:=0) {
    return DllCall("ReleaseDC", "Ptr", hwnd, "Ptr", hdc)
}

GetDC(hwnd:=0) {
    return DllCall("GetDC", "Ptr", hwnd)
}

Gdip_Startup() {
    if !DllCall("GetModuleHandle", "Str", "gdiplus", "Ptr")
        DllCall("LoadLibrary", "Str", "gdiplus")
    si := Buffer(24, 0)
    NumPut("UChar", 1, si, 0)
    DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken:=0, "Ptr", si, "Ptr", 0)
    return pToken
}

CreateDIBSection(w, h, hdc:="", bpp:=32, &ppvBits:=0) {
    hdc2 := hdc ? hdc : GetDC()
    bi := Buffer(40, 0)
    
    NumPut("UInt", 40, bi, 0)
    NumPut("UInt", w, bi, 4)
    NumPut("UInt", h, bi, 8)
    NumPut("UShort", 1, bi, 12)
    NumPut("UShort", bpp, bi, 14)
    NumPut("UInt", 0, bi, 16)
    
    hbm := DllCall("CreateDIBSection",
                   "Ptr", hdc2,
                   "Ptr", bi,
                   "UInt", 0,
                   "Ptr*", &ppvBits:=0,
                   "Ptr", 0,
                   "UInt", 0, "Ptr")

    if !hdc
        ReleaseDC(hdc2)
    return hbm
}

CreateCompatibleDC(hdc:=0) {
   return DllCall("CreateCompatibleDC", "Ptr", hdc)
}

SelectObject(hdc, hgdiobj) {
    return DllCall("SelectObject", "Ptr", hdc, "Ptr", hgdiobj)
}

Gdip_GraphicsFromHDC(hdc) {
    DllCall("gdiplus\GdipCreateFromHDC", "Ptr", hdc, "Ptr*", &pGraphics:=0)
    return pGraphics
}

Gdip_SetSmoothingMode(pGraphics, SmoothingMode) {
   return DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", SmoothingMode)
}

Gdip_GraphicsClear(pGraphics, ARGB:=0x00ffffff) {
    return DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "Int", ARGB)
}

Gdip_CreatePen(ARGB, w) {
   DllCall("gdiplus\GdipCreatePen1", "UInt", ARGB, "Float", w, "Int", 2, "Ptr*", &pPen:=0)
   return pPen
}

Gdip_DrawEllipse(pGraphics, pPen, x, y, w, h) {
    return DllCall("gdiplus\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pPen, "Float", x, "Float", y, "Float", w, "Float", h)
}

Gdip_DrawLine(pGraphics, pPen, x1, y1, x2, y2) {
    return DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", x1, "Float", y1, "Float", x2, "Float", y2)
}

Gdip_DrawLines(pGraphics, pPen, Points) {
    PointsArray := StrSplit(Points, "|")
    PointF := Buffer(8 * PointsArray.Length)
    
    For i, coordPair in PointsArray {
        Coord := StrSplit(coordPair, ",")
        NumPut("Float", Coord[1], PointF, 8*(i-1))
        NumPut("Float", Coord[2], PointF, (8*(i-1))+4)
    }
    
    return DllCall("gdiplus\GdipDrawLines", "Ptr", pGraphics, "Ptr", pPen, "Ptr", PointF, "Int", PointsArray.Length)
}

Gdip_DeletePen(pPen) {
   return DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
}

UpdateLayeredWindow(hwnd, hdc, x:="", y:="", w:="", h:="", Alpha:=255) {
    if ((x != "") && (y != "")) {
        pt := Buffer(8)
        NumPut("UInt", x, pt, 0)
        NumPut("UInt", y, pt, 4)
    }

    if (w = "") || (h = "")
        WinGetPos(,, &w, &h, "ahk_id " hwnd)
   
    return DllCall("UpdateLayeredWindow",
                   "Ptr", hwnd,
                   "Ptr", 0,
                   "Ptr", ((x = "") && (y = "")) ? 0 : pt,
                   "Int64*", w|h<<32,
                   "Ptr", hdc,
                   "Int64*", 0,
                   "UInt", 0,
                   "UInt*", Alpha<<16|1<<24,
                   "UInt", 2)
}

BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster:="") {
    return DllCall("gdi32\BitBlt",
                   "Ptr", dDC,
                   "Int", dx,
                   "Int", dy,
                   "Int", dw,
                   "Int", dh,
                   "Ptr", sDC,
                   "Int", sx,
                   "Int", sy,
                   "UInt", Raster ? Raster : 0x00CC0020)
}

CreateCompatibleBitmap(hdc, w, h) {
    return DllCall("gdi32\CreateCompatibleBitmap", "Ptr", hdc, "Int", w, "Int", h)
}

DeleteDC(hdc) {
   return DllCall("DeleteDC", "Ptr", hdc)
}

DeleteObject(hObject) {
   return DllCall("DeleteObject", "Ptr", hObject)
}

Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h) {
    return DllCall("gdiplus\GdipDrawRectangle", "Ptr", pGraphics, "Ptr", pPen, "Float", x, "Float", y, "Float", w, "Float", h)
}