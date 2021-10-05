(********************************************************************
 * COPYRIGHT --  
 ********************************************************************
 * Program: USBLinker
 * File: FileDeviceMgr.st
 * Author: Josh
 * Created: September 19, 2013
 ********************************************************************
 * Implementation of program USBLinker
 ********************************************************************) 

(* Links/Unlinks file devices *)
FUNCTION_BLOCK FileDeviceMgr

	//If execute is false, reset all statuses
	IF NOT Execute THEN

		busy:= 		0;
		done:= 		0;
		status:=	0;
		error:=		0;		
		internal.iExecute:=	0;

	END_IF
	
	//If we have a handle it means that we have devlinked
	//Completion means the user has made a change
	//If so, unlink, then link to the new one
	IF internal.DevUnlinkFub.handle <> 0 AND NOT internal.iExecute AND Execute THEN

		busy:= 		1;
		done:= 		0;
		error:=		0;		
		status:= ERR_FUB_BUSY;
		
		internal.iExecute:=	1;
		internal.DevUnlinkFub.enable:=	1;
		
	//If we don't have a handle, we can just link.
	//If we actually are linked, it will thow it back to unlink anyway
	ELSIF NOT internal.iExecute AND Execute THEN

		busy:= 		1;
		done:= 		0;
		error:=		0;
		
		status:= ERR_FUB_BUSY;
		
		internal.iExecute:=	1;		
		internal.DevLinkFub.enable:=		1;
		
	END_IF
	
	internal.DevUnlinkFub();

	//When we finish unlinking or have an error, start a link
	IF internal.DevUnlinkFub.status = ERR_OK OR internal.DevUnlinkFub.status = fiERR_SYSTEM THEN
		internal.DevUnlinkFub.enable:=		0;		
		internal.DevUnlinkFub.handle:=		0;
		internal.DevLinkFub.enable:=		1;
	ELSIF internal.DevUnlinkFub.status <> ERR_FUB_ENABLE_FALSE THEN	
		status:= internal.DevUnlinkFub.status;
		busy:= 		0;
		done:= 		0;		
	END_IF

	internal.DevLinkFub.pDevice:=	pDevice;
	internal.DevLinkFub.pParam:=	pParam;
	internal.DevLinkFub();

	CASE internal.DevLinkFub.status OF
		//Link is done, grab the handle for unlinking later
		ERR_OK://Done, grab the handle to unlink later
			internal.DevLinkFub.enable:=		0;
			internal.DevUnlinkFub.handle:= 	internal.DevLinkFub.handle;

			busy:= 		0;
			done:= 		1;

			status:=	internal.DevLinkFub.status;
		
		//Already linked to different device, unlink and relink when it is finished.
		fiERR_DEVICE_ALREADY_EXIST://Already exist, must unlink first
			//Disable link
			internal.DevLinkFub.enable:=		0;

			//Do an unlink
			IF internal.DevLinkFub.handle <> 0 THEN
				internal.DevUnlinkFub.handle:= internal.DevLinkFub.handle;
				internal.DevUnlinkFub.enable:=	1;
			ELSE
				busy:= 		0;
				done:= 		0;				
				status:=	internal.DevLinkFub.status;				
			END_IF
		
		//Working			
		ERR_FUB_BUSY:
			status:=	internal.DevLinkFub.status;

		//Do nothing
		ERR_FUB_ENABLE_FALSE:
		
		fiERR_SYSTEM: 
			internal.DevLinkFub.enable:=		0;
			busy:= 		0;
			done:= 		0;
			error:=		1;
			status:=	FileIoGetSysError();
			
		ELSE	

			internal.DevLinkFub.enable:=		0;
			
			error:=		1;
			busy:= 		0;
			done:= 		0;
			status:=	internal.DevLinkFub.status;
		//OOPS!
		
	END_CASE	
	
	handle:=	internal.DevUnlinkFub.handle;
	
END_FUNCTION_BLOCK