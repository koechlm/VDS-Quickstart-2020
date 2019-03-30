#region disclaimer
#=============================================================================
# PowerShell script sample for Vault Data Standard                            
# Extract ADSK Exchange Component Metadata from Autodesk Vault				  
#                                                                             
# Copyright (c) Autodesk, Markus Koechl - All rights reserved.                               
#                                                                             
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  
#=============================================================================

# Important - this sample uses powerVault libraries from coolOrange.com; as of today these are available for free, but this might change. #
#
#endregion

# configure the meta properties to read here
$global:mPropValues = @{"component.props.description"=''; "component.props.manufacturer" = ''; "component.props.model" =''}
# map the read values to Vault UDPs in region UDP-Mapping below

#read UIStrings (only VDS dialogs/tabs do this as a default)
$UIString = mGetUIStrings

function mReadAdskMetaNodes($mRoot)
{
	if ($mRoot.node.HasChildNodes)
	{
		$mCount = $mRoot.node.ChildNodes.Count
		for ($x = 0; $x -lt $mCount; $x++)
		{
			if ($mRoot.node.ChildNodes.Item($x))
			{
				[System.Xml.XmlElement]$mChild = $mRoot.node.ChildNodes.Item($x)
				$mText = $mChild.Name
				mReadAdskMetaNodes $mChild
				if ($global:mPropValues.ContainsKey($mText))
					{
						$mValue = $mChild.ChildNodes.Item(0).ChildNodes.Item(0).ChildNodes.Item(0).InnerText
						#$mValue = $mChild.Data.Line.Item(0).Value
						$global:mPropValues.Set_Item($mText, $mValue)
					}
	
				}
			}
		}
}

# this functions requires powerShell 5 or higher installed
Add-Type -AssemblyName PresentationFramework
$vaultContext.ForceRefresh = $true
$mPScheck = $PSVersionTable.PSVersion
If ($mPScheck.Major -cge 5)
{
	$mFiles = $vaultContext.CurrentSelectionSet
	foreach ($mF in $mFiles)
	{
		$fileId=$mF.Id
		# check that the file is an ADSK extension	
		$_Ext = $mF.Label.Substring($mF.Label.Length -5)

		If ($_Ext -eq ".adsk")
		{
			#$pvFile = Get-VaultFile -FileId $fileId -DownloadPath 'C:\Temp\'
			#$mAdsk = Get-Item -Path $pvFile.LocalPath  
			#$mZip = $mAdsk.CopyTo($mAdsk.DirectoryName + '\' + $mAdsk.BaseName + '.zip')
			
			$fileMasterId = $vaultContext.CurrentSelectionSet[0].Id
			$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
			$folder = $vault.DocumentService.GetFolderById($file.FolderId)
			$mFileFullName = $folder.FullName + "/" + $file.Name

			#to download the file temporarily use the iLogicQuickstart class
			[System.Reflection.Assembly]::LoadFrom('C:\ProgramData\Autodesk\Vault 2020\Extensions\DataStandard\Vault.Custom\addinVault\QuickstartUtilityLibrary.dll')
			$VltHelpers = New-Object QuickstartUtilityLibrary.VltHelpers
			
			$mAdsk =  $VltHelpers.mGetFileByFullFileName($vaultConnection, $mFileFullName)
			$mAdsk = Get-Item -Path $mAdsk
			$mZip = $mAdsk.CopyTo($mAdsk.DirectoryName + '\' + $mAdsk.BaseName + '.zip')

			[Void][Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') 
			$zipTemp = [IO.Compression.ZipFile]::OpenRead($mZip.FullName)
			$zipEntries = $zipTemp.Entries

			if ($zipEntries.Item(0).FullName -eq $mZip.BaseName + "/")
			{
				#set target dir without subfolder
				$1 = "Sub exists"
				$mZipDir = $mZip.DirectoryName + '\'
				$mXmlDir = $mZip.DirectoryName + '\' + $mZip.BaseName + '\'
			}
			else {
				#set target dir as subfolder = file base name
				$1 = "no sub, create one"
				$mZipDir = $mZip.DirectoryName + '\' + $mZip.BaseName + '\'
				$mXmlDir = $mZipDir
			}
			[IO.Compression.ZipFile]::ExtractToDirectory($mZip.FullName, $mZipDir)
						
			$zipTemp.Dispose()
			
			If (Test-Path $mZip.DirectoryName)
			{
				$mDir =   $mXmlDir + 'buildingcomponent.components\'
				$mXml = New-Object XML 
				$mXml.Load($mDir+'Master.metadata.xml')        
				$mItem = Select-Xml -Xml $mXml -XPath '//Definition'
				mReadAdskMetaNodes $mItem

				#update properties expects Dictionary<Autodesk.Connectivity.WebServices.PropDef, object>
				$mPropDictionary = New-Object 'system.collections.generic.dictionary[[Autodesk.Connectivity.WebServices.PropDef],[object]]'
 
				$mPropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
				$mPropDictionary.Add(($mPropDefs | Where-Object { $_.DispName -eq $UIString["LBL2"]}), $global:mPropValues.Get_Item("component.props.model"))#Title
				$mPropDictionary.Add(($mPropDefs | Where-Object { $_.DispName -eq $UIString["ADSK-FilePropRead-00"]}), $global:mPropValues.Get_Item("component.props.manufacturer"))#manufacturer
				$mPropDictionary.Add(($mPropDefs | Where-Object { $_.DispName -eq $UIString["LBL3"]}), $global:mPropValues.Get_Item("component.props.description"))#Description
				
				# update the file with properties retrieved
				$mPropsUpdate = $VltHelpers.mUpdateFileProperties($vaultConnection, $file, $mPropDictionary)
				
				#clean up the temporary unzipped package
				$mDirToDel = Get-Item -Path ($mZipDir)
				Remove-Item $mDirToDel -Force -Recurse
				#Remove-Item $mAdsk.FullName -Force
				Remove-Item $mZip.FullName -Force
			}
		} # Extension = .ADSK
	}
} #end if powerShell 5 available          

else 
{
  [System.Windows.MessageBox]::Show("PowerShell Version 5 or higher required.","ADSK-Exchange-File Meta Reader")
	#alternatively we could offer the edit dialog to manually enter the values	
}




