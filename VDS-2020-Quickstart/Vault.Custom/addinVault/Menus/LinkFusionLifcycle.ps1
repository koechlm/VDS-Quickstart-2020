$selection = $vaultContext.CurrentSelectionSet[0]
$id = $selection.Id

$attributeNamespace = "coolorange.flc.transfer.filebom.attributes"

function GetFusionLifecycleUri([string]$url) {
    $uri = [System.Uri]$url
    if ($null -eq $uri.AbsolutePath -or (-not $uri.Host.EndsWith(".autodeskplm360.net")) -or ($null -eq $uri.Query) -or (-not $uri.Query.Contains("itemId"))) {
        return $null
    }
    return $uri
}

$url = Get-Clipboard -Format Text
$uri = GetFusionLifecycleUri -url $url

if ($null -eq $uri) {
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
    $url = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter the URL to the existing item in Fusion Lifecycle that you want to attach to the selected Vautl entity '$($selection.Label)'", "Fusion Lifecycle Item Link")
    if ([string]::IsNullOrEmpty($url)) { return }
    $uri = GetFusionLifecycleUri -url $url
}

if ($null -eq $uri) {
    [System.Windows.Forms.MessageBox]::Show("Please provide a valid Fusion Lifecycle item URL!", "Invalid URL")
    return
}

$segments = $uri.Query.Split(@('?','&'))
$segment = $segments | Where-Object { $_.StartsWith("itemId=") }
$urn = $segment.Substring(7).Replace("%60", ":").Replace(',','.')

$attributes = $vault.PropertyService.FindEntityAttributes($attributeNamespace, "Urn")
$attribute = $attributes | Where-Object { $_.Val -eq $urn }

if (-not $attribute) {
    $vault.PropertyService.SetEntityAttribute($id, $attributeNamespace, "Urn", $urn)
    $vaultContext.ForceRefresh = $true
} else {
    [System.Windows.Forms.MessageBox]::Show("There is already a link to the specified Fusion Lifecycle item. One item can only be assigned once!")
}