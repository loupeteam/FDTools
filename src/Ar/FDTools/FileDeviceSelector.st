(*
 * File: FileDeviceSelector.st
 * Copyright (c) 2023 Loupe
 * https://loupe.team
 * 
 * This file is part of FDTools, licensed under the MIT License.
 * 
  ********************************************************************
 * Implementation of program USBLinker
 ********************************************************************) 

(* Selects  *)
FUNCTION_BLOCK FileDeviceSelector

	(* Make sure perm memory will link on bootup *)
	(* Check if permanent memory is used, if so assign it *)
	IF Selector.Selection = 0 THEN
		IF pConfiguredDevice <> 0 THEN
			Selector.Selection:=		pConfiguredDevice;
			TempString ACCESS pConfiguredDevice;
			IF TempString <> '' THEN 
				internal.FileDeviceManager.Execute:=1;
			END_IF
		ELSE
			Selector.Selection:=		ADR(internal.iSelectedDevice);		
		END_IF
	END_IF

	//If a directory location is given, allow the user to select CF
	brsmemset(ADR(Locations),0,SIZEOF(Locations));
	Selector.MaxDP:=0;
	IF ADR(pDirectory) <> 0 THEN
		Locations[Selector.MaxDP]:= 'Disk';
		Selector.MaxDP:=Selector.MaxDP+1;		
	END_IF

	//If a network configuration is given, allow the user to select Network share
	IF ADR(pNetworkConfiguration) <> 0 THEN
		Locations[Selector.MaxDP]:= 'Network';
		Selector.MaxDP:=Selector.MaxDP+1;		
	END_IF	

	//Add any USB storage devices to the list as USBn
	IF ADR(pUSBList) <> 0 THEN
		IF pUSBList.OUT.NumMassStorages > 0 THEN 
			FOR internal.USBIndex:=0 TO pUSBList.OUT.NumMassStorages -1 DO				
				Locations[Selector.MaxDP]:=	REPLACE(pUSBList.OUT.MassStorageDevice[internal.USBIndex],'USB',3,1);
				Selector.MaxDP:=			Selector.MaxDP+1;
			END_FOR
		END_IF
		//Call selection function block to update screen list
		Selector.Enable:= 	Enable;// AND (pUSBList.OUT.STAT.Done); 	// Only enable while the USB list is done to make sure we don't get flashing, or lose settings between during update			
	ELSE
		Selector.Enable:=	Enable;
	END_IF
	
	Selector.MinDP:=			0;									
	Selector.SelectionList:=	ADR(Locations);// Set up the list of device to look at
	Selector();
	
	IF pConfiguredDevice <> 0 THEN //Check if permanent memory is used, if so copy into internal memory
		brsmemcpy(ADR(internal.iSelectedDevice),pConfiguredDevice,SIZEOF(internal.iSelectedDevice));
	END_IF

	//Completion means the user has made a change
	IF Selector.CompletionDP THEN
		status:=0;			
		IF FIND(internal.iSelectedDevice,'USB') <> 0 THEN 
			internal.DeviceString:=				CONCAT('/DEVICE=',REPLACE(internal.iSelectedDevice,'/bd',3,1));
			internal.FileDeviceManager.pParam:=	ADR(internal.DeviceString);			
			internal.FileDeviceManager.Execute:=1;			
		ELSIF FIND(internal.iSelectedDevice,'Disk') <> 0 THEN
			internal.DeviceString:=				CONCAT('/DEVICE=',pDirectory);
			internal.FileDeviceManager.pParam:=	ADR(internal.DeviceString);			
			internal.FileDeviceManager.Execute:=1;
		ELSIF FIND(internal.iSelectedDevice,'Network') <> 0 THEN
			internal.FileDeviceManager.pParam:=	ADR(pNetworkConfiguration);			
			internal.FileDeviceManager.Execute:=1;
		END_IF	
	END_IF
	
	internal.FileDeviceManager.pDevice:=ADR(FileDevice);
	internal.FileDeviceManager();	
	IF internal.FileDeviceManager.error THEN		
		status:= internal.FileDeviceManager.status;
	END_IF
	
	internal.FileDeviceManager.Execute:=	0;
	
	handle:= internal.FileDeviceManager.handle;
	
END_FUNCTION_BLOCK