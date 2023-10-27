(********************************************************************
 * COPYRIGHT --  
 ********************************************************************
 * Program: USBLinker
 * File: USBList.st
 * Author: Josh
 * Created: September 16, 2013
 ********************************************************************
 * Implementation of program USBLinker
 ********************************************************************) 

(* List all USB nodes *)
FUNCTION USBList

	IF NOT USB.IN.CMD.Refresh AND USB.Internal.CMD.Refresh OR USB.IN.CMD.AcknowledgeError THEN

		USB.IN.CMD.AcknowledgeError:=	0;
		
		USB.Internal.CMD.Refresh:=0;
		
		//Reset status
		USB.Internal.STAT.Done:=		0;
		USB.Internal.STAT.Error:=		0;
		USB.Internal.STAT.ErrorID:=		0;
		USB.Internal.STAT.ErrorString:=	'';
		
	END_IF

	CASE USB.Internal.State OF

		USB_ST_IDLE:

			USB.Internal.STAT.Busy:=		0;
						
			IF USB.IN.CMD.Refresh AND NOT USB.Internal.CMD.Refresh THEN	

				USB.Internal.CMD.Refresh:= 1;
				
				USB.Internal.State:=	USB_ST_NODES_GET;

				//Reset statuses
				USB.Internal.STAT.Busy:=	1;
				USB.Internal.STAT.Done:=	0;

				//Reset outputs
				USB.Internal.NumMassStorage:=	0;				
				USB.Internal.NumAuxInterface:=	0;
				brsmemset(ADR(USB.Internal.MassStorageDevices),0,SIZEOF(USB.Internal.MassStorageDevices));
				brsmemset(ADR(USB.Internal.AuxInterfaces),0,SIZEOF(USB.Internal.AuxInterfaces));				

				//Clear out old node data
				brsmemset(ADR(USB.Internal.NodeList),0,SIZEOF(USB.Internal.NodeList));
				brsmemset(ADR(USB.Internal.DescriptorList),0,SIZEOF(USB.Internal.DescriptorList));

			END_IF

		USB_ST_NODES_GET:

			USB.Internal.FUB.NodeListGet.enable:=					1;

			CASE USB.Internal.FUB.NodeListGet.status OF

				ERR_OK:

					USB.Internal.State:=	USB_ST_NODES_READ;
				
				asusbERR_USB_NOTFOUND:

					USB.Internal.State:=	USB_ST_IDLE;
					USB.Internal.STAT.Done:=	1;

					brsmemcpy(ADR(USB.OUT.Interface),ADR(USB.Internal.AuxInterfaces),SIZEOF(USB.OUT.Interface));
					brsmemcpy(ADR(USB.OUT.MassStorageDevice),ADR(USB.Internal.MassStorageDevices),SIZEOF(USB.OUT.MassStorageDevice));			

				ERR_FUB_ENABLE_FALSE,
				ERR_FUB_BUSY:

				ELSE
					
					USB.Internal.STAT.Error:=		1;
					USB.Internal.STAT.ErrorID:=		USB.Internal.FUB.NodeListGet.status;
					USB.Internal.STAT.ErrorString:=	'Error getting node list';
					USB.Internal.State:=			USB_ST_ERROR;

			END_CASE

		USB_ST_NODES_READ:

			CASE USB.Internal.FUB.NodeGet.status OF
				
				ERR_OK:

					IF USB.Internal.NodeList[USB.Internal.NodeIndex].interfaceClass = 8 THEN
						USB.Internal.MassStorageDevices[USB.Internal.NumMassStorage]:=	USB.Internal.NodeList[USB.Internal.NodeIndex].ifName;
						USB.Internal.NumMassStorage:=	USB.Internal.NumMassStorage+1;
					ELSIF USB.Internal.NodeList[USB.Internal.NodeIndex].interfaceClass = 255 THEN	
						USB.Internal.AuxInterfaces[USB.Internal.NumAuxInterface]:=	USB.Internal.NodeList[USB.Internal.NodeIndex].ifName;
						USB.Internal.NumAuxInterface:=	USB.Internal.NumAuxInterface+1;
					END_IF
						
					USB.Internal.NodeIndex:=USB.Internal.NodeIndex+1;
					
					IF USB.Internal.FUB.NodeListGet.listNodes > 0 
						AND USB.Internal.FUB.NodeListGet.listNodes > USB.Internal.NodeIndex 
						AND USB.Internal.NodeIndex < SIZEOF(USB.Internal.NodeIDList)/SIZEOF(USB.Internal.NodeIDList[0]) THEN
		
						USB.Internal.FUB.NodeGet.enable:=		1;
					
					ELSE
	
						USB.Internal.State:=	USB_ST_DESCRIPTORS_READ;					
	
					END_IF
	
				ERR_FUB_BUSY:

					//WAIT
					USB.Internal.FUB.NodeGet.enable:=		1;

				ERR_FUB_ENABLE_FALSE:

					USB.Internal.NodeIndex:= 0;
					USB.Internal.FUB.NodeGet.enable:=		1;
				
				ELSE

					USB.Internal.STAT.Error:=		1;
					USB.Internal.STAT.ErrorID:=		USB.Internal.FUB.NodeGet.status;
					USB.Internal.STAT.ErrorString:=	'Error reading nodes';
					USB.Internal.State:=			USB_ST_ERROR;
				
			END_CASE
		
		USB_ST_DESCRIPTORS_READ:
			
			CASE USB.Internal.FUB.DescriptorGet.status OF
				ERR_OK:
					
					USB.Internal.NodeIndex:=USB.Internal.NodeIndex+1;
				
					IF USB.Internal.FUB.NodeListGet.listNodes > 0 
						AND USB.Internal.FUB.NodeListGet.listNodes > USB.Internal.NodeIndex 
						AND USB.Internal.NodeIndex < SIZEOF(USB.Internal.NodeIDList)/SIZEOF(USB.Internal.NodeIDList[0]) THEN
		
						USB.Internal.FUB.DescriptorGet.enable:=		1;
					
					ELSE
	
						USB.Internal.State:=		USB_ST_IDLE;
						USB.Internal.STAT.Done:=	1;						

						brsmemcpy(ADR(USB.OUT.Interface),ADR(USB.Internal.AuxInterfaces),SIZEOF(USB.OUT.Interface));
						brsmemcpy(ADR(USB.OUT.MassStorageDevice),ADR(USB.Internal.MassStorageDevices),SIZEOF(USB.OUT.MassStorageDevice));			

						USB.OUT.NumInterfaces:= USB.Internal.NumAuxInterface;
						USB.OUT.NumMassStorages:= USB.Internal.NumMassStorage;
						
					END_IF
	
				ERR_FUB_BUSY:

					//WAIT
					USB.Internal.FUB.DescriptorGet.enable:=		1;

				ERR_FUB_ENABLE_FALSE:

					USB.Internal.NodeIndex:= 0;
					USB.Internal.FUB.DescriptorGet.enable:=		1;
				
				ELSE

					USB.Internal.STAT.Error:=		1;
					USB.Internal.STAT.ErrorID:=		USB.Internal.FUB.DescriptorGet.status;
					USB.Internal.STAT.ErrorString:=	'Error reading node descriptions';
					USB.Internal.State:=			USB_ST_ERROR;
				
			END_CASE

		USB_ST_ERROR:
			
			USB.Internal.State:=			USB_ST_IDLE;
		
	END_CASE


	USB.Internal.RefreshTimer.IN:=	USB.Internal.STAT.Done;
	USB.Internal.RefreshTimer.PT:=	T#3s;
	USB.Internal.RefreshTimer();
	IF USB.Internal.RefreshTimer.Q THEN
		USB.Internal.CMD.Refresh:=	0;	
	END_IF
	
	USB.Internal.FUB.NodeListGet.pBuffer:= 					ADR(USB.Internal.NodeIDList[0]); 
	USB.Internal.FUB.NodeListGet.bufferSize:= 				SIZEOF(USB.Internal.NodeIDList); 
	USB.Internal.FUB.NodeListGet.filterInterfaceClass:= 	USB.IN.PAR.filterInterfaceClass; 
	USB.Internal.FUB.NodeListGet.filterInterfaceSubClass:= 	USB.IN.PAR.filterInterfaceSubClass;
	USB.Internal.FUB.NodeListGet(); 
	USB.Internal.FUB.NodeListGet.enable:=	0;

	USB.Internal.FUB.NodeGet.nodeId:= 		USB.Internal.NodeIDList[USB.Internal.NodeIndex];					
	USB.Internal.FUB.NodeGet.pBuffer:= 		ADR(USB.Internal.NodeList[USB.Internal.NodeIndex]); 
	USB.Internal.FUB.NodeGet.bufferSize:= 	SIZEOF(USB.Internal.NodeList[0]); 
	USB.Internal.FUB.NodeGet(); 
	USB.Internal.FUB.NodeGet.enable:=	0;
	
	USB.Internal.FUB.DescriptorGet.nodeId:= 		USB.Internal.NodeIDList[USB.Internal.NodeIndex];					
	USB.Internal.FUB.DescriptorGet.pBuffer:= 		ADR(USB.Internal.DescriptorList[USB.Internal.NodeIndex]); 
	USB.Internal.FUB.DescriptorGet.bufferSize:= 	SIZEOF(USB.Internal.DescriptorList[0]); 
	//	USB.Internal.FUB.DescriptorGet.descriptorIndex
	//	USB.Internal.FUB.DescriptorGet.descriptorType	
	//	USB.Internal.FUB.DescriptorGet.languageId
	//	USB.Internal.FUB.DescriptorGet.requestType
	USB.Internal.FUB.DescriptorGet.descriptorType:= 2;
	USB.Internal.FUB.DescriptorGet(); 
	USB.Internal.FUB.DescriptorGet.enable:=	0;
	
	USB.OUT.STAT:=	USB.Internal.STAT;

	USBList:=	USB.OUT.STAT.Done;
	
END_FUNCTION