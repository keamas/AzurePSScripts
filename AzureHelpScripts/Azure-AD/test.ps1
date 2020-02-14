$myArray = @()

$myObject = New-Object System.Object

$myObject | Add-Member -type NoteProperty -name Name -Value "Ryan_PC"
$myObject | Add-Member -type NoteProperty -name Manufacturer -Value "Dell"
$myObject | Add-Member -type NoteProperty -name ProcessorSpeed -Value "3 Ghz"

$myArray = @(64,"Hello",3.5,"World")

$myObject | Add-Member -type NoteProperty -name Other -Value $myArray

$myObject2 | Add-Member -type NoteProperty -name Name -Value "Ryan_PC1"
$myObject2 | Add-Member -type NoteProperty -name Manufacturer -Value "Dell"
$myObject2 | Add-Member -type NoteProperty -name ProcessorSpeed -Value "3 Ghz"

$myArray2 = @(64,"Hello",3.5,"World")

$myObject2 | Add-Member -type NoteProperty -name Other -Value $myArray2




