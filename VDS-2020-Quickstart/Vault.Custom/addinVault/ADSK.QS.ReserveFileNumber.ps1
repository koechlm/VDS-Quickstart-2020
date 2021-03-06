#region disclaimer
#=============================================================================#
# PowerShell script sample for Vault Data Standard                            #
#                                                                             #
# Copyright (c) Autodesk - All rights reserved.                               #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#
#endregion

function Reserve 
{
#	$dsDiag.Trace(">> Start Reserve ...")
	try
	{
		$dsWindow.FindName("Range").Text = ""
		#retrieve inputs
		$NumschemeName = $dsWindow.FindName("NumSchms").Text
		$global:numSchems = $vault.NumberingService.GetNumberingSchemes('FILE', 'Activated')
		$ns = $global:numSchems | Where-Object { $_.Name.Equals($NumschemeName) }
		$TotalNum = $dsWindow.FindName("TotalNum").Text
		#prepare numbering
		$NumGenArgs = @()
		$mNumCtrl = $dsWindow.DataContext.NumSchemeCtrlViewModel
		#Filter Freetext and pre-defined list
		foreach ($mField in $mNumCtrl.NumSchmFields) 
			{
				IF (($mField.FieldTyp -eq "FreeText") -or ($mField.FieldTyp -eq "PreDefinedList"))
					{
						$NumGenArgs += $mField.Value
					}
			}
		if ($NumGenArgs.Count -eq 0) {$NumGenArgs = @("")}
		$nsIDs = @($ns.SchmID)
		#create the numbers in given quantity
		for ($i=1; $i -le $TotalNum; $i++)
			{
				$num = $vault.DocumentService.GenerateFileNumber($ns.SchmID, $NumGenArgs)
				$dsWindow.FindName("Range").Text = $dsWindow.FindName("Range").Text + $num + "`n"
			}
			[Windows.Forms.Clipboard]::SetText($dsWindow.FindName("Range").Text)
	} #end try
	catch 
		{
	  		$dsDiag.Trace("...Error during number reservation...")
	  	}
#	$dsDiag.Trace(" ...Reserve finished successfully<<")
}