if ($Host.Name -ne "ConsoleHost" -or !(New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process "conhost.exe" -ArgumentList "powershell.exe -c `"Invoke-RestMethod 'https://raw.githubusercontent.com/Aetopia/NVIDIA-Driver-Package-Downloader-TUI/main/NVDPDTUI.ps1' | Invoke-Expression`"" -Verb "RunAs"
    return
}
Invoke-RestMethod "https://raw.githubusercontent.com/couleur-tweak-tips/TweakList/master/Master.ps1" | Invoke-Expression
Invoke-RestMethod "https://raw.githubusercontent.com/Aetopia/NVIDIA-Driver-Package-Downloader/main/NVDPD.ps1" |  Invoke-Expression
$NvidiaGpu = Get-NvidiaGpu

Function Invoke-DownloadMenu {
    $DriverType = "Game Ready"
    $DriverPackageType = "DCH"
    $DriverVersions = { return Get-NvidiaDriverVersions $NvidiaGpu -Studio: ($DriverType -eq "Studio") -Standard: ($DriverPackageType -eq "Standard") }
    $DriverPackageComponentsString = "Display Driver"
    $DriverVersion = (& $DriverVersions)[0]
    $Loop = $True

    while ($Loop) {
        switch -Wildcard (
            Write-Menu @(
                "Driver Type: $DriverType", 
                "Driver Package Type: $DriverPackageType", 
                "Driver Version: $DriverVersion", 
                "Driver Package Components: $DriverPackageComponentsString",
                "Accept", 
                "Back") "NVIDIA Driver Package Downloader: Download") {

            "Driver Type*" {
                switch ($DriverType) {
                    "Game Ready" { $DriverType = "Studio" }
                    "Studio" { $DriverType = "Game Ready" }
                }
                $DriverVersion = (& $DriverVersions)[0]
            }
            "Driver Package Type*" {
                switch ($DriverPackageType) {
                    "DCH" { $DriverPackageType = "Standard" } 
                    "Standard" { $DriverPackageType = "DCH" }
                }
                $DriverVersion = (& $DriverVersions)[0]
            }
            "Driver Version*" {
                $DriverVersion = Write-Menu ((& $DriverVersions)) "Select Driver Version" 
            }
            "Driver Package Components*" {
                $DriverPackageComponentsString = Write-Menu @("Display Driver",
                    "Display Driver + HD Audio", 
                    "Display Driver + PhysX", 
                    "Display Driver + HD Audio + PhysX", 
                    "All Driver Components") "Select Driver Package Components"
            }
            "Accept" {
                $DriverPackageComponents = @()
                $All = $False
                switch ($DriverPackageComponentsString) {
                    "Display Driver + HD Audio" { $DriverPackageComponents = @("HDAudio") }
                    "Display Driver + PhysX" { $DriverPackageComponents = @("PhysX") }
                    "Display Driver + HD Audio + PhysX" { $DriverPackageComponents = @("HDAudio", "PhysX") }
                    "All Driver Components" { $All = $True }
                }
                Invoke-NvidiaDriverPackage $NvidiaGpu $DriverVersion -Studio: ($DriverType -eq "Studio") -Standard: ($DriverPackageType -eq "Standard") -Components: $DriverPackageComponents -All: $All
                $Loop = $False
            }
            "Back" { $Loop = $False }
        }
    }

}

Function Invoke-PropertiesMenu {
    $Properties = Get-NvidiaGpuProperties $NvidiaGpu
    $DynamicPState = $Properties.DynamicPState
    $HDCP = $Properties.HDCP
    $Loop = $True
    
    while ($Loop) {
        switch -Wildcard (Write-Menu @(
                "Dynamic P-State: $DynamicPState",
                "HDCP: $HDCP",
                "Apply",
                "Back")) {
            "Dynamic P-State*" {
                switch ($DynamicPState) {
                    $True { $DynamicPState = $False } 
                    $False { $DynamicPState = $True }
                }
            }
            "HDCP*" {
                switch ($HDCP) {
                    $True { $HDCP = $False } 
                    $False { $HDCP = $True }
                }
            }
            "Apply" { 
                Set-NvidiaGpuProperty DynamicPState $DynamicPState
                Set-NvidiaGpuProperty HDCP $HDCP
                if ((Write-Menu @("Yes", "No") "Reboot System to Apply Changes?") -eq "Yes") { shutdown.exe /r /t 0 /f }
            }
            "Back" { $Loop = $False }
        }
    }
}

$Loop = $True
while ($Loop) {
    switch (Write-Menu @("Download", 
            "Properties",
            "Exit") "NVIDIA Driver Package Downloader") {
        "Download" { Invoke-DownloadMenu }
        "Properties" { Invoke-PropertiesMenu }
        "Exit" { $Loop = $False }
    }
}
