;wp7_simple_sync.au3
;A simple script to start a http server which can used to sync files for your wp7
;mobile phone. If you want to import PDF or doc without skydrive, you may use this
;tool. Hope it helps...
;author: knktc
;created on 2012-02-26

#include <ListviewConstants.au3>
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#Include <GuiListView.au3>
#Include <GuiButton.au3>
#include <File.au3>

;configuration
$SHS_path = @ScriptDir & "\SimpleHTTPServer.exe"
$default_port = "8000"
$default_filefolder = @HomeDrive & @HomePath
$shs_pid = 0
$host_ip = _GetDomainIP()

;create GUI components
GUICreate("WP7 简易文件传输 - www.knktc.com", 535, 269, -1, -1, -1, $WS_EX_ACCEPTFILES)

;create host ip display area
GUICtrlCreateLabel("本机IP：", 51, 29, 53, 12)
GUICtrlCreateLabel($host_ip, 110, 29, 291, 21)

;build port input section
GUICtrlCreateLabel("设置端口：", 39, 58, 65, 12)
$Editbox_port = GUICtrlCreateInput($default_port, 110, 54, 166, 21, $ES_NUMBER)
GUICtrlSetLimit($Editbox_port, 5)
GUICtrlCreateLabel("（5001-65535）", 282, 58, 100, 12)

;build file folder choose section
GUICtrlCreateLabel("文件存储目录：", 15, 87, 89, 12)
$Editbox_filefolder = GUICtrlCreateInput("", 110, 83, 210, 21, $ES_NOHIDESEL)
GUICtrlSetState($Editbox_filefolder, $GUI_DROPACCEPTED)
$Button_browse = GUICtrlCreateButton("浏览", 326, 81, 75, 23)

;start button
$Button_start = GUICtrlCreateButton("开始", 420, 20, 100, 87)

;stop button
$Button_stop = GUICtrlCreateButton("停止", 420, 20 , 100, 87)
_GUICtrlButton_Show($Button_stop,  False)
;build status box section
$Editbox_statusinfo = GUICtrlCreateEdit("", 15, 122, 505, 130, $WS_VSCROLL + $ES_READONLY)
GUICtrlSetData($Editbox_statusinfo, "使用“浏览”按钮选择文件存储目录，或直接拖动文件到文件存储目录框中" & @CRLF & "===========================" & @CRLF, 1)
;GUICtrlSetState($Editbox_statusinfo, $GUI_DROPACCEPTED)

;show the gui dialog
GUISetState(@SW_SHOW)

While 1
	$guimsg = GUIGetMsg()
	Select
		Case $guimsg = $GUI_EVENT_CLOSE
			;close the process before program closed
			If $shs_pid <> 0 Then
				ProcessClose($shs_pid)
			EndIf
			ExitLoop
			
		;case when the browse button pushed
		Case $guimsg = $Button_browse
			$chosen_file_folder = FileSelectFolder("选择文件存储目录", "", 1)
			GUICtrlSetData($Editbox_filefolder, $chosen_file_folder)
		
		;case when the start button pushed
		Case $guimsg = $Button_start
			;get config
			;deal with input port
			$port = GUICtrlRead($Editbox_port)
			$port = _DealWithPort($port, $default_port)
			GUICtrlSetData($Editbox_port, $port)
			
			;deal with input filefolder
			$filefolder = GUICtrlRead($Editbox_filefolder)
			$filefolder = _DealWithFilefolder($filefolder, $default_filefolder)
			GUICtrlSetData($Editbox_filefolder, $filefolder)
			
			;check config
			If FileExists($SHS_path) = 0 Then
				GUICtrlSetData($Editbox_statusinfo, "SimpleHTTPServer.exe 文件丢失，程序无法运行！" & @CRLF & "===========================" & @CRLF, 1)
			Else
				$shs_pid = _StartHTTPServer($SHS_path, $port, $filefolder)
				If $shs_pid = 0 Then
					GUICtrlSetData($Editbox_statusinfo, "HTTP服务器启动失败！" & @CRLF & "===========================" & @CRLF, 1)
				Else
					_GUICtrlButton_Show($Button_start, False)
					_GUICtrlButton_Show($Button_stop, True)
					GUICtrlSetData($Editbox_statusinfo, "HTTP服务器已启动！" & @CRLF, 1)
					GUICtrlSetData($Editbox_statusinfo, "共享目录为 " & $filefolder & @CRLF, 1)
					GUICtrlSetData($Editbox_statusinfo, "请使用 http://" & $host_ip & ":" & $port & " 来访问资源" & @CRLF, 1)
					GUICtrlSetData($Editbox_statusinfo, "===========================" & @CRLF, 1)
				EndIf
			EndIf
			
		Case $guimsg = $Button_stop
			;stop the running Process
			ProcessClose($shs_pid)
			
			;show the start button
			GUICtrlSetData($Editbox_filefolder, "")
			_GUICtrlButton_Show($Button_stop, False)
			_GUICtrlButton_Show($Button_start, True)
			GUICtrlSetData($Editbox_statusinfo, "HTTP服务器已停止！" & @CRLF, 1)
			GUICtrlSetData($Editbox_statusinfo, "===========================" & @CRLF, 1)
	EndSelect
WEnd

;functions
;get domain ip
Func _GetDomainIP()
	Return @IPAddress1
EndFunc

;deal with the input port
Func _DealWithPort($func_input_port, $func_default_port)
	$func_input_port = Number($func_input_port)
	If $func_input_port = 0 Then
		Return $func_default_port
	ElseIf $func_input_port < 5001 Then
		Return $func_default_port
	ElseIf $func_input_port > 65535 Then
		Return $func_default_port
	Else
		Return $func_input_port
	EndIf
EndFunc

;deal with the input filefolder
Func _DealWithFilefolder($func_input_filefolder, $func_default_filefolder)
	If FileExists($func_input_filefolder) = 0 Then
		Return $func_default_filefolder
	Else
		$file_attrib = FileGetAttrib($func_input_filefolder)
		$is_dir = StringInStr($file_attrib, "D")
		If $is_dir = 0 Then
			$func_input_filefolder = StringRegExpReplace($func_input_filefolder, '(.+)\\.+', '$1')
			Return $func_input_filefolder
		Else
			Return $func_input_filefolder
		EndIf
	EndIf
EndFunc	

;use SimpleHTTPServer to start a http server and return the pid
Func _StartHttpServer($func_shs_path, $func_port, $func_filefolder)
	$command = '"' & $func_shs_path & '"' & ' "' & $func_port & '"'
	$func_pid = Run($command, $func_filefolder, @SW_HIDE)
	Return $func_pid
EndFunc

