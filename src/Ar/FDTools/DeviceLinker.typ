(*
 * File: DeviceLinker.typ
 * Copyright (c) 2023 Loupe
 * https://loupe.team
 * 
 * This file is part of FDTools, licensed under the MIT License.
 * 
  ********************************************************************
 * Local data types of program USBLinker
 ********************************************************************)

TYPE
	USB_typ : 	STRUCT 
		IN : USB_IN_typ;
		OUT : USB_OUT_typ;
		Internal : USB_Internal_typ;
	END_STRUCT;
	USB_IN_typ : 	STRUCT 
		PAR : USB_PAR_typ;
		CMD : USB_CMD_typ;
	END_STRUCT;
	USB_PAR_typ : 	STRUCT 
		filterInterfaceClass : UINT;
		filterInterfaceSubClass : UINT;
	END_STRUCT;
	USB_CMD_typ : 	STRUCT 
		Refresh : BOOL;
		AcknowledgeError : BOOL;
	END_STRUCT;
	USB_OUT_typ : 	STRUCT 
		STAT : USB_STAT_typ;
		Interface : ARRAY[0..USB_MAI_NODES]OF STRING[80];
		NumInterfaces : USINT;
		MassStorageDevice : ARRAY[0..USB_MAI_NODES]OF STRING[80];
		NumMassStorages : USINT;
	END_STRUCT;
	USB_STAT_typ : 	STRUCT 
		Done : BOOL;
		Busy : BOOL;
		Error : BOOL;
		ErrorID : UINT;
		ErrorString : STRING[80];
	END_STRUCT;
	USB_Internal_typ : 	STRUCT 
		State : USB_STATE;
		CMD : USB_CMD_typ;
		STAT : USB_STAT_typ;
		NodeIDList : ARRAY[0..USB_MAI_NODES]OF UDINT;
		NodeList : ARRAY[0..USB_MAI_NODES]OF usbNode_typ;
		DescriptorList : ARRAY[0..USB_MAI_NODES]OF usbDeviceDescr_typ;
		FUB : USB_Internal_FUB_typ;
		NodeIndex : INT;
		AuxInterfaces : ARRAY[0..USB_MAI_NODES]OF STRING[80];
		NumAuxInterface : USINT;
		MassStorageDevices : ARRAY[0..USB_MAI_NODES]OF STRING[80];
		NumMassStorage : USINT;
		RefreshTimer : TON;
	END_STRUCT;
	USB_Internal_FUB_typ : 	STRUCT 
		NodeListGet : UsbNodeListGet;
		NodeGet : UsbNodeGet;
		DescriptorGet : UsbDescriptorGet;
	END_STRUCT;
	USB_Selector_Internal_typ : 	STRUCT 
		DeviceString : STRING[80];
		iSelectedDevice : STRING[LIST_BOX_STRING_SIZE];
		FileDeviceManager : FileDeviceMgr;
		USBIndex : DINT;
		USBIndexString : STRING[80];
	END_STRUCT;
	FileDeviceMgr_Internal_typ : 	STRUCT 
		DevLinkFub : DevLink;
		DevUnlinkFub : DevUnlink;
		iExecute : BOOL;
	END_STRUCT;
	USB_STATE : 
		(
		USB_ST_IDLE,
		USB_ST_NODES_GET,
		USB_ST_NODES_READ,
		USB_ST_DESCRIPTORS_READ,
		USB_ST_ERROR,
		USB_ST_
		);
END_TYPE
