
FUNCTION USBList : BOOL (*List all USB nodes*) (*$GROUP=User,$GROUPICON=usbms01.front.png*)
	VAR_INPUT
		USB : USB_typ;
	END_VAR
END_FUNCTION

FUNCTION_BLOCK FileDeviceSelector (*Allows the user to select between multiple sources for a file device*) (*$GROUP=User*)
	VAR_INPUT
		Enable : BOOL; (*Enable this function block*)
		FileDevice : STRING[80]; (*File device to link the selected hardware to*)
		pConfiguredDevice : UDINT; (*OPTIONAL: Connect to remnant string variable to reconnect on startup*)
		pUSBList : REFERENCE TO USB_typ; (*OPTIONAL: ADR to USB_typ to populate the list with USB devices*)
		pDirectory : REFERENCE TO STRING[80]; (*OPTIONAL: ADR of String containing the directory to connect to on the CF card*)
		pNetworkConfiguration : REFERENCE TO STRING[80]; (*OPTIONAL: ADR of String containing the network configuration to connect to*)
		Selector : ListBoxFub; (*HMI Connections. Connect this structure to HMI elements to display the results and allow users to select devices.*)
	END_VAR
	VAR_OUTPUT
		Locations : ARRAY[0..12] OF STRING[LIST_BOX_STRING_SIZE]; (*HMI Connections. Connect this array to Listbox or Dropdown to display the results and allow the user to select a device.*)
		status : UINT; (*Status of internal functions*)
		handle : UDINT; (*Handle to unlink in exit routine*)
	END_VAR
	VAR
		internal : USB_Selector_Internal_typ;
		TempString : REFERENCE TO STRING[80];
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK FileDeviceMgr (*Links/Unlinks file devices*) (*$GROUP=User*)
	VAR_INPUT
		Execute : BOOL; (*Execute a DevLink*)
		pDevice : UDINT; (*File device to link to hardware*)
		pParam : UDINT; (*Parameter string. See Devlink Help.*)
	END_VAR
	VAR_OUTPUT
		busy : BOOL; (*The function block is working*)
		done : BOOL; (*The function block completed successfully*)
		error : BOOL; (*Error has occured*)
		status : UINT; (*status of devlink/unlink*)
		handle : UDINT; (*Handle to unlink in exit routine*)
	END_VAR
	VAR
		internal : FileDeviceMgr_Internal_typ;
	END_VAR
END_FUNCTION_BLOCK
