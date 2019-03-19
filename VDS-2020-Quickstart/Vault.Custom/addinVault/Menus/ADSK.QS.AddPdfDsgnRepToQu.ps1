#region disclaimer
	#===============================================================================
	# PowerShell script sample														
	# Author: Markus Koechl															
	# Copyright (c) Autodesk 2017													
	#																				
	# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER     
	# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES   
	# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.    
	#===============================================================================
#endregion

$mFileMstrIds=$vaultContext.CurrentSelectionSet
Foreach($item in $mFileMstrIds)
{
	$mFile = ($vault.DocumentService.FindLatestFilesByMasterIds(@($item.Id)))[0]
	$mTemp = $mFile.Name.Split(".")
	$mExt = $mTemp[$mTemp.Count-1]
	If($mExt -eq "idw" -or $mExt -eq "dwg")
	{
		#region params for PDF Creation
			$mJobParamFile = New-Object Autodesk.Connectivity.WebServices.JobParam
			$mJobParams = @()
			$mJobParamFile.Name = "FileVersionId"
			$mJobParamFile.Val = $mFile.Id
			$mJobParams += $mJobParamFile

			$mJobParamUpdtViewOpt = New-Object Autodesk.Connectivity.WebServices.JobParam
			$mJobParamUpdtViewOpt.Name = "UpdateViewOption"
			$mJobParamUpdtViewOpt.Val = $false
			$mJobParams += $mJobParamUpdtViewOpt
		#endregion params PDF creation

		$vault.JobService.AddJob("Autodesk.Vault.PDF.Create."+$mExt, "Create/Update PDF View (VDS User Command) : "+ $mFile.Name, $mJobParams, 10)
	}
}