
#include <GUIConstants.au3>
#include <ColorConstants.au3>
#include <Array.au3>
#include <Math.au3>
#include <Date.au3>

; SETUP

CONST $DEBUG = False
CONST $CONTROLLER_INDEX = 0

Const $LEFT_X_AXIS = 0
CONST $LEFT_Y_AXIS = 1
CONST $RIGHT_X_AXIS = 2
CONST $RIGHT_Y_AXIS = 3
CONST $TRIGGER = 4
CONST $POV = 5
CONST $BUTTON = 6

CONST $MAX_CAMS = 3

Global $camIndex = 0
Global $camCount = 0

Global $speedPan = 5
Global $speedTilt = 5
Global $speedZoom = 4

Global $limitPan = 10 ; max = 18
Global $limitTilt = 8 ; max = 14

Global $stepTilt, $stepPan, $offsetTilt, $offsetPan
calcLimits()

Global $switchIsPressed = False

Global $camNames[$MAX_CAMS]
Global $camIps[$MAX_CAMS]
Global $camPorts[$MAX_CAMS]
Global $camSockes[$MAX_CAMS]
Global $camGuiElements[$MAX_CAMS]

Local $controller
Local $coord
Local $msg
Local $temp
Local $lastCommand
Local $commandPanTilt
Local $commandZoom
Local $commandPreset

Local $controller = initController()


Cam("Cam L", "10.11.4.1", 5678)
Cam("Cam M", "10.11.4.2", 5678)
Cam("Cam R", "10.11.4.3", 5678)


Func calcLimits()
	; (65535 - 1) / 2 = 32767
	$stepTilt = Int(32767 / $limitTilt) - 40
	$stepPan = Int(32767 / $limitPan) - 20
	$offsetTilt = Mod(32767, $stepTilt)
	$offsetPan = Mod(32767, $stepPan)

	If $DEBUG Then
		ConsoleWrite('calc Limits')
	EndIf
EndFunc

Func initController()
	Local $controller
	Global $controllerStruct = "dword[13]"

	$controller = DllStructCreate($controllerStruct)
	if @error Then Return 0

	DllStructSetData($controller, 1, DllStructGetSize($controller), 1)
	DllStructSetData($controller, 1, 255, 2)
	return $controller
EndFunc

Func getControllerCoordinates($controller, $index)
	Local $coord, $ret

	Dim $coord[7]
	DllCall("Winmm.dll", "int", "joyGetPosEx", "int", $index, "ptr", DllStructGetPtr($controller))

	if Not @error Then
		$coord[$LEFT_X_AXIS] 	= DllStructGetData($controller, 1, 3)
		$coord[$LEFT_Y_AXIS] 	= DllStructGetData($controller, 1, 4)
		$coord[$RIGHT_X_AXIS] 	= DllStructGetData($controller, 1, 6)
		$coord[$RIGHT_Y_AXIS] 	= DllStructGetData($controller, 1, 7)
		$coord[$TRIGGER] 		= DllStructGetData($controller, 1, 5)
		$coord[$POV] 			= DllStructGetData($controller, 1, 11)
		$coord[$BUTTON] 		= DllStructGetData($controller, 1, 9)
	EndIf

	return $coord
EndFunc

; Buttons

Func isButtonPressed($coord)
	Return $coord[$BUTTON] > 0
EndFunc

Func isButtonCrossPressed($coord)
	Return BitAND($coord[$BUTTON], 1) = 1
EndFunc

Func isButtonCirclePressed($coord)
	Return BitAND($coord[$BUTTON], 2) = 2
EndFunc

Func isButtonSquarePressed($coord)
	Return BitAND($coord[$BUTTON], 4) = 4
EndFunc

Func isButtonTrianglePressed($coord)
	Return BitAND($coord[$BUTTON], 8) = 8
EndFunc

Func isButtonL1Pressed($coord)
	Return BitAND($coord[$BUTTON], 16) = 16
EndFunc

Func isButtonR1Pressed($coord)
	Return BitAND($coord[$BUTTON], 32) = 32
EndFunc

Func isButtonSelectPressed($coord)
	Return BitAND($coord[$BUTTON], 64) = 64
EndFunc

Func isButtonStartPressed($coord)
	Return BitAND($coord[$BUTTON], 128) = 128
EndFunc

Func isButtonL3Pressed($coord)
	Return BitAND($coord[$BUTTON], 256) = 256
EndFunc

Func isButtonR3Pressed($coord)
	Return BitAND($coord[$BUTTON], 512) = 512
EndFunc

Func isConfigPressed($coord)
	;Return BitAND($coord[$BUTTON], 48) = 48
	Return isButtonR3Pressed($coord)
EndFunc


; POV

Func hasPOV($coord)
	Return $coord[$POV] < 65535
EndFunc

Func isPOVUp($coord)
	Return $coord[$POV] = 0
EndFunc

Func isPOVUpRight($coord)
	Return $coord[$POV] = 4500
EndFunc

Func isPOVRight($coord)
	Return $coord[$POV] = 9000
EndFunc

Func isPOVDownRight($coord)
	Return $coord[$POV] = 13500
EndFunc

Func isPOVDown($coord)
	Return $coord[$POV] = 18000
EndFunc

Func isPOVDownLeft($coord)
	Return $coord[$POV] = 22500
EndFunc

Func isPOVLeft($coord)
	Return $coord[$POV] = 27000
EndFunc

Func isPOVUpLeft($coord)
	Return $coord[$POV] = 31500
EndFunc

; Trigger

#CS
	65408 - 32767 = 32641
	32641 / 8 = 4080 = 4050
	32641 % 4050 = 241
	32641 + 241 = 32882

	32767 - 128 = 32639
	32767 / 8 = 4080 = 4050
	32641 + 128 % 4050 = 32769
#CE

Func getTriggerLeft($coord)
	Return Int(_Max($coord[$TRIGGER] - 32882, 0) / 4050)
EndFunc

Func getTriggerRight($coord)
	Return Int(_Max(32769 - $coord[$TRIGGER], 0) / 4050)
EndFunc

; Left Joystick

Func getLUp($coord)
	Return Int(_Max(32768 - $offsetTilt - $coord[$LEFT_Y_AXIS], 0) / $stepTilt)
EndFunc

Func getLRight($coord)
	Return Int(_Max($coord[$LEFT_X_AXIS] - 32767 + $offsetPan, 0) / $stepPan)
EndFunc

Func getLDown($coord)
	Return Int(_Max($coord[$LEFT_Y_AXIS] - 32767 + $offsetTilt, 0) / $stepTilt)
EndFunc

Func getLLeft($coord)
	Return Int(_Max(32768 - $offsetPan - $coord[$LEFT_X_AXIS], 0) / $stepPan)
EndFunc



Func isLUp($coord)
	Return $coord[$LEFT_X_AXIS] < 15000
EndFunc

Func isLRight($coord)
	Return $coord[$LEFT_Y_AXIS] > 55000
EndFunc

Func isLDown($coord)
	Return $coord[$LEFT_X_AXIS] > 55000
EndFunc

Func isLLeft($coord)
	Return $coord[$LEFT_Y_AXIS] < 15000
EndFunc


; Right Joystick

Func isRUp($coord)
	Return $coord[$RIGHT_X_AXIS] < 15000
EndFunc

Func isRRight($coord)
	Return $coord[$RIGHT_Y_AXIS] > 55000
EndFunc

Func isRDown($coord)
	Return $coord[$RIGHT_X_AXIS] > 55000
EndFunc

Func isRLeft($coord)
	Return $coord[$RIGHT_Y_AXIS] < 15000
EndFunc


Func Z($number)
	If $number < 10 Then
		Return String(0 & $number)
	EndIf

	Return String($number)
EndFunc


Func commandPanTilt($coord)
	Local $command = '01 06 01 01 01 03 03'

	If hasPOV($coord) Then
		Switch $coord[$POV]
			Case 0 ; Up
				$command = '01 06 01 01 ' & Z($speedTilt) & ' 03 01'
			Case 4500 ; UpRight
				$command = '01 06 01 ' & Z($speedPan) & ' ' & Z($speedTilt) & ' 02 01'
			Case 9000 ; Right
				$command = '01 06 01 ' & Z($speedPan) & ' 01 02 03'
			Case 13500 ; DownRight
				$command = '01 06 01 ' & Z($speedPan) & ' ' & Z($speedTilt) & ' 02 02'
			Case 18000 ; Down
				$command = '01 06 01 01 ' & Z($speedTilt) & ' 03 02'
			Case 22500 ; DownLeft
				$command = '01 06 01 ' & Z($speedPan) & ' ' & Z($speedTilt) & ' 01 02'
			Case 27000 ; Left
				$command = '01 06 01 ' & Z($speedPan) & ' 01 01 03'
			Case 31500 ; UpLeft
				$command = '01 06 01 ' & Z($speedPan) & ' ' & Z($speedTilt) & ' 01 01'
		EndSwitch
	Else
		Local $up = getLUp($coord)
		Local $right = getLRight($coord)
		Local $down = getLDown($coord)
		Local $left = getLLeft($coord)

		If $left > 0 Then
			If $down > 0 Then
				; DownLeft
				$command = '01 06 01 ' & Z($left) & ' ' & Z($down) & ' 01 02'
			ElseIf $up > 0 Then
				; UpLeft
				$command = '01 06 01 ' & Z($left) & ' ' & Z($up) & ' 01 01'
			Else
				; Left
				$command = '01 06 01 ' & Z($left) & ' 01 01 03'
			EndIf
		ElseIf $right > 0 Then
			If $down > 0 Then
				; DownRight
				$command = '01 06 01 ' & Z($right) & ' ' & Z($down) & ' 02 02'
			ElseIf $up > 0 Then
				; UpRight
				$command = '01 06 01 ' & Z($right) & ' ' & Z($up) & ' 02 01'
			Else
				; Right
				$command = '01 06 01 ' & Z($right) & ' 01 02 03'
			EndIf
		ElseIf $down > 0 Then
			; Down
			$command = '01 06 01 01 ' & Z($down) & ' 03 02'
		ElseIf $up > 0 Then
			; Up
			$command = '01 06 01 01 ' & Z($up) & ' 03 01'
		EndIf
	EndIf

	Return $command
EndFunc

Func commandZoom($coord)
	Local $command = '01 04 07 00'

	If isButtonL1Pressed($coord) Then
		$command = '01 04 07 3' & ($speedZoom - 1)
	ElseIf isButtonR1Pressed($coord) Then
		$command = '01 04 07 2' & ($speedZoom - 1)
	Else
		$zoom = getTriggerLeft($coord)
		If $zoom > 0 Then
			$command = '01 04 07 3' & ($zoom - 1)
		Else
			$zoom = getTriggerRight($coord)

			If $zoom > 0 Then
				$command = '01 04 07 2' & ($zoom - 1)
			EndIf
		EndIf
	EndIf

	Return $command
EndFunc


Func commandPresetSave($coord)
	Local $command = False

	If isButtonPressed($coord) Then
		Local $offset = 0

		If isButtonSelectPressed($coord) Then
			$offset = 4
		EndIf
		If isButtonStartPressed($coord) Then
			$offset = $offset + 4
		EndIf

		If isButtonTrianglePressed($coord) Then
			$command = '01 04 3F 01 ' & Z($offset)
		ElseIf isButtonCirclePressed($coord) Then
			$command = '01 04 3F 01 ' & Z($offset + 1)
		ElseIf isButtonCrossPressed($coord) Then
			$command = '01 04 3F 01 ' & Z($offset + 2)
		ElseIf isButtonSquarePressed($coord) Then
			$command = '01 04 3F 01 ' & Z($offset + 3)
		EndIf
	EndIf

	Return $command
EndFunc

Func commandPresetRecall($coord)
	Local $command = False

	If isButtonPressed($coord) Then
		Local $offset = 0

		If isButtonSelectPressed($coord) Then
			$offset = 4
		EndIf
		If isButtonStartPressed($coord) Then
			$offset = $offset + 4
		EndIf

		If isButtonTrianglePressed($coord) Then
			$command = '01 04 3F 02 ' & Z($offset)
		ElseIf isButtonCirclePressed($coord) Then
			$command = '01 04 3F 02 ' & Z($offset + 1)
		ElseIf isButtonCrossPressed($coord) Then
			$command = '01 04 3F 02 ' & Z($offset + 2)
		ElseIf isButtonSquarePressed($coord) Then
			$command = '01 04 3F 02 ' & Z($offset + 3)
		EndIf
	EndIf

	Return $command
EndFunc


Func Speed($coord)
	If isPOVUp($coord) Then
		$speedTilt = _Min($speedTilt + 1, 14)
	ElseIf isPOVDown($coord) Then
		$speedTilt = _Max($speedTilt - 1, 1)
	EndIf

	If isPOVLeft($coord) Then
		$speedPan = _Max($speedPan - 1, 1)
	ElseIf isPOVRight($coord) Then
		$speedPan = _Min($speedPan + 1, 18)
	EndIf

	If isButtonR1Pressed($coord) Then
		$speedZoom = _Min($speedZoom + 1, 8)
	EndIf
	If isButtonL1Pressed($coord) Then
		$speedZoom = _Max($speedZoom - 1, 1)
	EndIf
EndFunc


Func CamSwitch($coord)
	If isRRight($coord) Then
		If Not $switchIsPressed Then
			GUICtrlSetStyle($camGuiElements[$camIndex], $GUI_SS_DEFAULT_BUTTON)
			$camIndex = Mod($camIndex + 1, $camCount)
			GUICtrlSetBkColor($camGuiElements[$camIndex], $COLOR_RED)
		EndIf

		$switchIsPressed = True
	ElseIf isRLeft($coord) Then
		If Not $switchIsPressed Then
			GUICtrlSetStyle($camGuiElements[$camIndex], $GUI_SS_DEFAULT_BUTTON)
			$camIndex = Mod($camIndex + $camCount - 1, $camCount)
			GUICtrlSetBkColor($camGuiElements[$camIndex], $COLOR_RED)
		EndIf

		$switchIsPressed = True
	Else
		$switchIsPressed = False
	EndIf
EndFunc

Func commandSend($command)
	Local $hex = ''
	Local $helper = _ArrayToString(StringSplit('81 ' & $command & ' FF', ' '), '', 1)

	For $i = 1 To StringLen($helper) Step 2
		$hex &= Chr(Dec(StringMid($helper, $i, 2)))
	Next

	$lastCommand = $command & '(' & _NowTime() & ')'

	If $DEBUG Then
		ConsoleWrite($command & @CRLF)
	EndIf

	TCPSend($camSockes[$camIndex], $hex)
EndFunc


Func Cam($name, $ip, $port)
	If $camCount >= $MAX_CAMS Then
		Return
	EndIf

	Local $socket = TCPConnect($ip, $port)

	If @error Then
		Local $error = @error
		MsgBox(0, "", "Server:" & @CRLF & "Could not bind, Error code: " & $error)
		Return False
    EndIf

	$camNames[$camCount] = $name
	$camIps[$camCount] = $ip
	$camPorts[$camCount] = $port
	$camSockes[$camCount] = $socket
	$camGuiElements[$camCount] = GUICtrlCreateButton ($name, 65 * $camCount + 5, 5, 60, 40)

	If $camCount = 0 Then
		GUICtrlSetBkColor($camGuiElements[0], $COLOR_RED)
	EndIf

	$camCount = $camCount + 1
EndFunc

TCPStartup()
OnAutoItExitRegister("OnAutoItExit")
Func OnAutoItExit()
	For $i = 0 To $camCount Step 1
		TCPCloseSocket($camSockes[$i])
	Next

	UDPShutdown()
EndFunc


; GUI

Local $windowWidth = 250

If $DEBUG Then
	$windowWidth = 1500
EndIf

Local $elementLimitPan = slider('Limit (Pan)', 5, 50, 200, 20, 1, 18, $limitPan)
Local $elementLimitTilt = slider('Limit (Tilt)', 5, 70, 200, 20, 1, 14, $limitTilt)

Local $elementSpeedPan= slider('Speed (Pan)', 5, 100, 200, 20, 1, 18, $speedPan)
Local $elementSpeedTilt = slider('Speed (Tilt)', 5, 120, 200, 20, 1, 14, $speedTilt)
Local $elementSpeedZoom = slider('Speed (Zoom)', 5, 140, 200, 20, 1, 8, $speedZoom)

GUICreate('Joystick Test', $windowWidth, 250)
$label = GuiCtrlCreatelabel('', 200, 10 , 1430, 230)
GUICtrlSetFont($label, 12, 0, 0, "Courier New")

Func slider($text, $x, $y, $width, $height, $min, $max, $value)
	Local $element = GUICtrlCreateSlider($x + 70, $y, $width - 70, $height)
	GUICtrlSetLimit($element, $max, $min)
	GUICtrlSetData($element, $value)

	Local $label = GuiCtrlCreatelabel($text, $x, $y , 70, $height)

	Return $element
EndFunc


GUISetState()


while 1
	$coord = getControllerCoordinates($controller, $CONTROLLER_INDEX)

	If isConfigPressed($coord) Then
		Speed($coord)

		$temp = commandPresetSave($coord)
		If $commandPreset <> $temp Then
			$commandPreset = $temp
			If $temp <> False Then
				commandSend($temp)
			EndIf
		EndIf
	Else
		$temp = commandPanTilt($coord)
		If $commandPanTilt <> $temp Then
			$commandPanTilt = $temp
			commandSend($temp)
		EndIf

		$temp = commandZoom($coord)
		If $commandZoom <> $temp Then
			$commandZoom = $temp
			commandSend($temp)
		EndIf

		$temp = commandPresetRecall($coord)
		If $commandPreset <> $temp Then
			$commandPreset = $temp
			If $temp <> False Then
				commandSend($temp)
			EndIf
		EndIf

		CamSwitch($coord)
	EndIf

	If $DEBUG Then
		Local $output[] = [ _
			StringFormat('Selected Camera: %s (%02s/%02s)' & @CRLF, $camNames[$camIndex] , $camIndex, $camCount), _
			StringFormat('%-10s %02s(P) %02s(T) %02s(Z)' & @CRLF, '[Speed]', $speedPan , $speedTilt, $speedZoom), _
			StringFormat('%-10s %05s/%05s %02s(U) %02s(R) %02s(D) %02s(L)', '[Left]', $coord[$LEFT_X_AXIS], $coord[$LEFT_Y_AXIS], getLUp($coord), getLRight($coord), getLDown($coord), getLLeft($coord)), _
			StringFormat('%-10s %05s/%05s %s(U) %s(R) %s(D) %s(L)', '[Right]', $coord[$RIGHT_X_AXIS], $coord[$RIGHT_Y_AXIS], isRUp($coord), isRRight($coord), isRDown($coord), isRLeft($coord)), _
			StringFormat('%-10s %05s %s(U) %s(UR) %s(R) %s(DR) %s(D) %s(DL) %s(L) %s(UL)', '[Pad]', $coord[$POV], isPOVUp($coord), isPOVUpRight($coord), isPOVRight($coord), isPOVDownRight($coord), isPOVDown($coord), isPOVDownLeft($coord), isPOVLeft($coord), isPOVUpLeft($coord)), _
			StringFormat('%-10s %05s %02s %02s', '[Trigger]', $coord[$TRIGGER], getTriggerLeft($coord), getTriggerRight($coord)), _
			StringFormat('%-10s %03s %s(Cross) %s(Circle) %s(Square) %s(Triangle) %s(L1) %s(R1) %s(Select) %s(Start) %s(L3) %s(R3)', '[Buttons]', $coord[$BUTTON], isButtonCrossPressed($coord), isButtonCirclePressed($coord), isButtonSquarePressed($coord), isButtonTrianglePressed($coord), isButtonL1Pressed($coord), isButtonR1Pressed($coord), isButtonSelectPressed($coord), isButtonStartPressed($coord), isButtonL3Pressed($coord), isButtonR3Pressed($coord)), _
			StringFormat(@CRLF & 'Last Command: %s', $lastCommand) _
		]

		GUICtrlSetData($label, _ArrayToString($output, @CRLF))

	EndIf

	GUICtrlSetData($elementSpeedPan, $speedPan)
	GUICtrlSetData($elementSpeedTilt, $speedTilt)
	GUICtrlSetData($elementSpeedZoom, $speedZoom)

	$temp = GUICtrlRead($elementLimitPan)
	If $temp <> $limitPan Then
		$limitPan = $temp
		calcLimits()
	Else
		$temp = GUICtrlRead($elementLimitTilt)
		If $temp <> $limitTilt Then
			$limitTilt = $temp
			calcLimits()
		EndIf
	EndIf

	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE
			ExitLoop
	EndSwitch

	sleep(70)
WEnd

$controller = 0