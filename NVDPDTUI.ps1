if ($Host.Name -ne "ConsoleHost"){
    Start-Process "conhost.exe" -ArgumentList "powershell.exe -c '"
}
Write-Host "Importing TweakList Functions..."
Invoke-RestMethod "https://raw.githubusercontent.com/couleur-tweak-tips/TweakList/master/Master.ps1" | Invoke-Expression
Write-Host "Importing NVIDIA Driver Package Downloader Functions..."
Invoke-RestMethod "https://raw.githubusercontent.com/Aetopia/NVIDIA-Driver-Package-Downloader/main/NVDPD.ps1" |  Invoke-Expression
Write-Host "Obtaining NVIDIA GPU Information..."
$NvidiaGpu = Get-NvidiaGpu

Function Invoke-DownloadMenu {
    $DriverType = "Game Ready"
    $DriverPackageType = "DCH"
    $DriverVersions = { return Get-NvidiaDriverVersions $NvidiaGpu -Studio: ($DriverType -eq "Studio") -Standard: ($DriverPackageType -eq "Standard") }
    $DriverPackageComponents = "Display Driver"
    $DriverVersion = (& $DriverVersions)[0]
    $Loop = $True

    while ($Loop) {
        switch -Wildcard (
            Write-Menu @(
                "Driver Type: $DriverType", 
                "Driver Package Type: $DriverPackageType", 
                "Driver Version: $DriverVersion", 
                "Driver Package Components: $DriverPackageComponents",
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
                $DriverPackageComponents = Write-Menu @("Display Driver",
                    "Display Driver + HD Audio", 
                    "Display Driver + PhysX", 
                    "Display Driver + HD Audio + PhysX", 
                    "All Driver Components") "Select Driver Package Components"
            }
            "Accept" {
                $DriverType
                $DriverPackageType
                $DriverVersion
                $DriverPackageComponents
                return $True
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
                if ((Write-Menu @("Yes", "No") "Reboot System to Apply Changes?") -eq "Yes"){shutdown.exe /r /t 0 /f}
            }
            "Back" { $Loop = $False }
        }
    }
}

$Loop = $True
while ($Loop) {
    switch (Write-Menu @("Download", 
            "Extract",
            "Properties",
            "Exit") "NVIDIA Driver Package Downloader") {
        "Download" { Invoke-DownloadMenu }
        "Extract" { "" }
        "Properties" { Invoke-PropertiesMenu }
        "Exit" { $Loop = $False }
    }
}
