#=============================================================================#
# PowerShell script sample for Vault Data Standard                            #
# Demonstrates how to navigate to a Fusion Lifecycle item that is attached    #
# to a Vault entity                                                           #
#                                                                             #
#                                                                             #
# The Vault Fusion Lifecycle Connector uses the following                     #
# Vault Entity Attributes to identify if an item has been attached:           #
# - coolorange.flc.transfer.file.attributes                                   #
# - coolorange.flc.transfer.filebom.attributes                                #
# - coolorange.flc.sync.folder.attributes                                     #
#                                                                             #
# Copyright (c) coolOrange s.r.l. - All rights reserved.                      #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#

$attributes =  New-Object System.Collections.Generic.List[Autodesk.Connectivity.WebServices.EntAttr]
$id = $vaultContext.CurrentSelectionSet[0].Id

$ns = "coolorange.flc.transfer.file.attributes";
$attributes.AddRange($vault.PropertyService.GetEntityAttributes($id, $ns))

$ns = "coolorange.flc.transfer.filebom.attributes";
$attributes.AddRange($vault.PropertyService.GetEntityAttributes($id, $ns))

$ns = "coolorange.flc.sync.folder.attributes";
$attributes.AddRange($vault.PropertyService.GetEntityAttributes($id, $ns))

if ($attributes.Count -gt 0) {
    foreach($attribute in $attributes) {
        $urn = $attribute.Val
        $contents = [array]$urn.Split(':')
        $values = $contents[$contents.Length -1].Split('.')
        $names = $contents[$contents.Length -2].Split('.')
        $tenant = $values[[array]::IndexOf($names, "tenant")]
        $workspace = $values[[array]::IndexOf($names, "workspace")]
    
        $link = "https://$($tenant).autodeskplm360.net/plm/workspaces/$($workspace)/items/itemDetails?view=full&tab=details&mode=view&itemId=$($urn.Replace(":", "%60").Replace(".", ","))"
        [System.Diagnostics.Process]::Start($link)
    }
} else {
    [System.Windows.Forms.MessageBox]::Show("There is no Fusion Lifecycle item attached to the Vault entity '$($vaultContext.CurrentSelectionSet[0].Label)'", "$($vaultContext.CurrentSelectionSet[0].Label)")
}