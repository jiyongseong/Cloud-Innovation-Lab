$resourceGroupnName = "rg-sqlcluster-krc"
$md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$utf8 = New-Object -TypeName System.Text.UTF8Encoding
$hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($resourceGroupnName)))

$hash.ToLower() -replace '-', ''