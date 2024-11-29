# Author: William Lam
# Website: www.williamlam.com
# Contributor: Abbed Sedkaoui
# Website: strivevirtually.net

# vCenter Server used to deploy VCF Import Lab
$VIServer = "FILL_ME_IN"
$VIUsername = "FILL_ME_IN"
$VIPassword = "FILL_ME_IN"

# Full Path to the Nested ESXi 8.0u3b OVA, SDDC 5.2.1.0 OVA, VCF Import Tool 5.2.1.0 & Extracted VCSA 8.0.3d ISO
$NestedESXiApplianceOVA = "L:\Downloads\Nested_ESXi8.0u3b_Appliance_Template_v1.ova"
$VCSAInstallerPath = "L:\Downloads\VMware-VCSA-all-8.0.3-24322831"
$SDDCManagerOVA = "L:\Downloads\VCF-SDDC-Manager-Appliance-5.2.1.0-24307856.ova"
$VCFImportToolpath = "L:\Downloads\vcf-brownfield-import-5.2.1.0-24307788.tar.gz"

# Full Path to VCF 5.2.1 NSX 4.2.1 Bundle and NSX spec file
$NSXBundlePath = "L:\Downloads\bundle-133764.zip"
$NsxSpecJsonPath = "L:\Downloads\nsx-deployment-spec.json"

# Nested ESXi VMs to deploy
$NestedESXiHostnameToIPs = @{
    "esxi-01" = "172.30.0.101"
    "esxi-02" = "172.30.0.102"
    "esxi-03" = "172.30.0.103"
    "esxi-04" = "172.30.0.104"
}

# Nested ESXi VM Resources
$NestedESXivCPU = "6"
$NestedESXivMEM = "46" #GB
$NestedESXiCachingvDisk = "8" #GB
$NestedESXiCapacityvDisk = "500" #GB

# SDDC Manager Configuration
$SddcManagerDisplayName = "sddcm"
$SddcManagerIP = "172.30.0.100"
$SddcManagerHostname = "sddcm"
$SddcManagerVcfPassword = "VMware1!VMware1!"
$SddcManagerRootPassword = "VMware1!VMware1!"
$SddcManagerAdminPassword = "VMware1!VMware1!"
$SddcManagerLocalPassword = "VMware1!VMware1!"
$SddcManagerBackupPassword = "VMware1!VMware1!"
$SddcManagerFIPSEnable = $false
$VCFManagementDomainName = "wlam-mgmt"

# VCSA Deployment Configuration
$VCSADeploymentSize = "tiny"
$VCSADisplayName = "vcsa"
$VCSAIPAddress = "172.30.0.99"
$VCSAHostname = "vcsa"
$VCSAPrefix = "22"
$VCSASSODomainName = "vsphere.local"
$VCSASSOPassword = "VMware1!"
$VCSARootPassword = "VMware1!"
$VCSASSHEnable = "true"

# General Deployment Configuration for Nested ESX & VCSA VM
$VMDatacenter = "Palo Alto"
$VMCluster = "Production"
$VMNetwork = "production-network"
$VMDatastore = "vsanDatastore"
$VMNetmask = "255.255.255.0"
$VMGateway = "172.30.0.1"
$VMDNS = "172.30.0.2"
$VMNTP = "172.30.0.3"
$VMPassword = "VMware1!"
$VMDomain = "williamlam.com"
$VMSyslog = "172.30.0.4"
$VMFolder = "wlam-vcf-deployment-testing"
# Applicable to Nested ESXi only
$VMSSH = "true"

# Name of new vSphere Datacenter/Cluster when VCSA is deployed
$NewVCDatacenterName = "Datacenter"
$NewVCVSANClusterName = "Cluster"
$NewVCVDSName = "VDS"
$NewVCVDSMTU = 9000 # Needs to match your physical MTU
$NewVCMgmtPortgroupName = "DVPG-Management-Network"
$StoragePolicyName = "vsan-ftt-storage-policy"
$hostFailuresToTolerate = 0

# Deployment Configuration for NSX
$NsxFormFactor = "small"
$NSXClusterVipHostname = "$VCFManagementDomainName-nsxm-vip"
$NSXClusterVip = "172.30.0.95"
$NSXManagerNode1Hostname = "$VCFManagementDomainName-nsxm-1"
$NSXManagerNode1IP = "172.30.0.96"
$NSXManagerNode2Hostname = "$VCFManagementDomainName-nsxm-2"
$NSXManagerNode2IP = "172.30.0.97"
$NSXManagerNode3Hostname = "$VCFManagementDomainName-nsxm-3"
$NSXManagerNode3IP = "172.30.0.98"


# Advanced Configurations
# Set to 1 only if you have DNS (forward/reverse) for ESXi hostnames
$addHostByDnsName = 1

#### DO NOT EDIT BEYOND HERE ####

$verboseLogFile = "vcf-import-lab-deployment.log"
$random_string = -join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_})
$VAppName = "Nested-VCF-Import-Lab-$random_string"
$bootStrapNode = $($NestedESXiHostnameToIPs.Keys|Sort-Object)[0]

$preCheck = 1
$confirmDeployment = 1
$deployNestedESXiVMs = 1
$moveVMsIntovApp = 1
$bootStrapFirstNestedESXiVM = 1
$deployVCSA = 1
$setupNewVC = 1
$addESXiHostsToVC = 1
$configureVSANDiskGroup = 1
$setupVsanStoragePolicy = 1
$configureVDS = 1
$migrateVMstoVDS = 1
$migrateVmkernelToVDS = 1
$removeVSS = 1
$finalCleanUp = 1
$deploySDDCManager = 1
$uploadVCFImportTool = 1
$generateNsxSpecJson = 1
$uploadNSXBundlePath = 1
$generateVCFImportConvertCommand = 1


$vcsaSize2MemoryStorageMap = @{
"tiny"=@{"cpu"="2";"mem"="14";"disk"="415"};
"small"=@{"cpu"="4";"mem"="21";"disk"="480"};
"medium"=@{"cpu"="8";"mem"="30";"disk"="700"};
"large"=@{"cpu"="16";"mem"="39";"disk"="1065"};
"xlarge"=@{"cpu"="24";"mem"="58";"disk"="1805"}
}

$esxiTotalCPU = 0
$vcsaTotalCPU = 0
$esxiTotalMemory = 0
$vcsaTotalMemory = 0
$esxiTotalStorage = 0
$vcsaTotalStorage = 0

$StartTime = Get-Date

Function My-Logger {
    param(
    [Parameter(Mandatory=$true)][String]$message,
    [Parameter(Mandatory=$false)][String]$color="green"
    )

    $timeStamp = Get-Date -Format "MM-dd-yyyy_hh:mm:ss"

    Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
    Write-Host -ForegroundColor $color " $message"
    $logMessage = "[$timeStamp] $message"
    $logMessage | Out-File -Append -LiteralPath $verboseLogFile
}

if($preCheck -eq 1) {
    if(!(Test-Path $NestedESXiApplianceOVA)) {
        Write-Host -ForegroundColor Red "`nUnable to find $NestedESXiApplianceOVA ...`n"
        exit
    }

    if(!(Test-Path $VCSAInstallerPath)) {
        Write-Host -ForegroundColor Red "`nUnable to find $VCSAInstallerPath ...`n"
        exit
    }

    if(!(Test-Path $SDDCManagerOVA)) {
        Write-Host -ForegroundColor Red "`nUnable to find $SDDCManagerOVA ...`n"
        exit
    }

    if(!(Test-Path $VCFImportToolpath)) {
        Write-Host -ForegroundColor Red "`nUnable to find $VCFImportToolpath ...`n"
        exit
    }
    
    if(!(Test-Path $NSXBundlePath)) {
        Write-Host -ForegroundColor Red "`nUnable to find $NSXBundlePath ...`n"
        exit
    }

    if($PSVersionTable.PSEdition -ne "Core") {
        Write-Host -ForegroundColor Red "`tPowerShell Core was not detected, please install that before continuing ... `n"
        exit
    }
}

if($confirmDeployment -eq 1) {
    Write-Host -ForegroundColor Magenta "`nPlease confirm the following configuration will be deployed:`n"

    Write-Host -ForegroundColor Yellow "---- VMware Cloud Foundation (VCF) Import Lab Deployment Configuration ---- "
    Write-Host -NoNewline -ForegroundColor Green "Nested ESXi Image Path: "
    Write-Host -ForegroundColor White $NestedESXiApplianceOVA
    Write-Host -NoNewline -ForegroundColor Green "VCSA Image Path: "
    Write-Host -ForegroundColor White $VCSAInstallerPath
    Write-Host -NoNewline -ForegroundColor Green "SDDC Manager Image Path: "
    Write-Host -ForegroundColor White $SDDCManagerOVA
    Write-Host -NoNewline -ForegroundColor Green "VCF Import Utility Path: "
    Write-Host -ForegroundColor White $VCFImportToolpath
    
    if($generateNsxSpecJson -eq 1 -and $uploadNSXBundlePath -eq 1){
        Write-Host -ForegroundColor Yellow "---- VMware Cloud Foundation (VCF) Import Lab NSX Deployment Configuration ---- "
        Write-Host -NoNewline -ForegroundColor Green "NSX Form factor: "
        Write-Host -ForegroundColor White $NsxFormFactor
        Write-Host -NoNewline -ForegroundColor Green "NSX Bundle Path: "
        Write-Host -ForegroundColor White $NSXBundlePath
        Write-Host -NoNewline -ForegroundColor Green "NSX Spec Json Path: "
        Write-Host -ForegroundColor White $NsxSpecJsonPath
        
        Write-Host -NoNewline -ForegroundColor Green "NSX Cluster Vip Hostname: "
        Write-Host -ForegroundColor White $NSXClusterVipHostname
        Write-Host -NoNewline -ForegroundColor Green "NSX Cluster Vip : "
        Write-Host -ForegroundColor White $NSXClusterVip
        Write-Host -NoNewline -ForegroundColor Green "NSX Manager Node1 Hostname: "
        Write-Host -ForegroundColor White $NSXManagerNode1Hostname
        Write-Host -NoNewline -ForegroundColor Green "NSX Manager Node2 Hostname: "
        Write-Host -ForegroundColor White $NSXManagerNode2Hostname
        Write-Host -NoNewline -ForegroundColor Green "NSX Manager Node3 Hostname: "
        Write-Host -ForegroundColor White $NSXManagerNode3Hostname
    }

    Write-Host -ForegroundColor Yellow "`n---- vCenter Server Deployment Target Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "vCenter Server Address: "
    Write-Host -ForegroundColor White $VIServer
    Write-Host -NoNewline -ForegroundColor Green "VM Network: "
    Write-Host -ForegroundColor White $VMNetwork

    Write-Host -NoNewline -ForegroundColor Green "VM Storage: "
    Write-Host -ForegroundColor White $VMDatastore
    Write-Host -NoNewline -ForegroundColor Green "VM Cluster: "
    Write-Host -ForegroundColor White $VMCluster
    Write-Host -NoNewline -ForegroundColor Green "VM vApp: "
    Write-Host -ForegroundColor White $VAppName

    Write-Host -ForegroundColor Yellow "`n---- vESXi Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "# of Nested ESXi VMs: "
    Write-Host -ForegroundColor White $NestedESXiHostnameToIPs.count
    Write-Host -NoNewline -ForegroundColor Green "vCPU: "
    Write-Host -ForegroundColor White $NestedESXivCPU
    Write-Host -NoNewline -ForegroundColor Green "vMEM: "
    Write-Host -ForegroundColor White "$NestedESXivMEM GB"
    Write-Host -NoNewline -ForegroundColor Green "Caching VMDK: "
    Write-Host -ForegroundColor White "$NestedESXiCachingvDisk GB"
    Write-Host -NoNewline -ForegroundColor Green "Capacity VMDK: "
    Write-Host -ForegroundColor White "$NestedESXiCapacityvDisk GB"
    Write-Host -NoNewline -ForegroundColor Green "IP Address(s): "
    Write-Host -ForegroundColor White ($NestedESXiHostnameToIPs.Values | Sort-Object)
    Write-Host -NoNewline -ForegroundColor Green "Netmask "
    Write-Host -ForegroundColor White $VMNetmask
    Write-Host -NoNewline -ForegroundColor Green "Gateway: "
    Write-Host -ForegroundColor White $VMGateway
    Write-Host -NoNewline -ForegroundColor Green "DNS: "
    Write-Host -ForegroundColor White $VMDNS
    Write-Host -NoNewline -ForegroundColor Green "DNS Domain Name (TLD must be =< 6 chars): "
    Write-Host -ForegroundColor White $VMDomain
    Write-Host -NoNewline -ForegroundColor Green "NTP: "
    Write-Host -ForegroundColor White $VMNTP
    Write-Host -NoNewline -ForegroundColor Green "Syslog: "
    Write-Host -ForegroundColor White $VMSyslog
    Write-Host -NoNewline -ForegroundColor Green "Enable SSH: "
    Write-Host -ForegroundColor White $VMSSH

    Write-Host -ForegroundColor Yellow "`n---- VCSA Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "Deployment Size: "
    Write-Host -ForegroundColor White $VCSADeploymentSize
    Write-Host -NoNewline -ForegroundColor Green "SSO Domain: "
    Write-Host -ForegroundColor White $VCSASSODomainName
    Write-Host -NoNewline -ForegroundColor Green "Enable SSH: "
    Write-Host -ForegroundColor White $VCSASSHEnable
    Write-Host -NoNewline -ForegroundColor Green "Hostname: "
    Write-Host -ForegroundColor White $VCSAHostname
    Write-Host -NoNewline -ForegroundColor Green "IP Address: "
    Write-Host -ForegroundColor White $VCSAIPAddress
    Write-Host -NoNewline -ForegroundColor Green "Netmask "
    Write-Host -ForegroundColor White $VMNetmask
    Write-Host -NoNewline -ForegroundColor Green "Gateway: "
    Write-Host -ForegroundColor White $VMGateway

    Write-Host -ForegroundColor Yellow "`n---- SDDC Manager Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "Hostname: "
    Write-Host -ForegroundColor White $SddcManagerHostname
    Write-Host -NoNewline -ForegroundColor Green "IP Address: "
    Write-Host -ForegroundColor White $SddcManagerIP
    Write-Host -NoNewline -ForegroundColor Green "Netmask "
    Write-Host -ForegroundColor White $VMNetmask
    Write-Host -NoNewline -ForegroundColor Green "Gateway: "
    Write-Host -ForegroundColor White $VMGateway
    Write-Host -NoNewline -ForegroundColor Green "FIPS Enabled: "
    Write-Host -ForegroundColor White $SddcManagerFIPSEnable
    Write-Host -NoNewline -ForegroundColor Green "VCF Management Domain Name: "
    Write-Host -ForegroundColor White $VCFManagementDomainName

    $esxiTotalCPU = $NestedESXiHostnameToIPs.count * [int]$NestedESXivCPU
    $esxiTotalMemory = $NestedESXiHostnameToIPs.count * [int]$NestedESXivMEM
    $esxiTotalStorage = ($NestedESXiHostnameToIPs.count * [int]$NestedESXiCachingvDisk) + ($NestedESXiHostnameToIPs.count * [int]$NestedESXiCapacityvDisk)
    $vcsaTotalCPU = $vcsaSize2MemoryStorageMap.$VCSADeploymentSize.cpu
    $vcsaTotalMemory = $vcsaSize2MemoryStorageMap.$VCSADeploymentSize.mem
    $vcsaTotalStorage = $vcsaSize2MemoryStorageMap.$VCSADeploymentSize.disk
    $sddcmTotalCPU = 4
    $sddcmTotalMemory = 16
    $sddcmTotalStorage = 908

    Write-Host -ForegroundColor Yellow "`n---- Resource Requirements ----"
    Write-Host -NoNewline -ForegroundColor Green "ESXi     VM CPU: "
    Write-Host -NoNewline -ForegroundColor White $esxiTotalCPU
    Write-Host -NoNewline -ForegroundColor Green " ESXi    VM Memory: "
    Write-Host -NoNewline -ForegroundColor White $esxiTotalMemory "GB "
    Write-Host -NoNewline -ForegroundColor Green "ESXi     VM Storage: "
    Write-Host -ForegroundColor White $esxiTotalStorage "GB"
    Write-Host -NoNewline -ForegroundColor Green "VCSA     VM CPU: "
    Write-Host -NoNewline -ForegroundColor White $vcsaTotalCPU
    Write-Host -NoNewline -ForegroundColor Green " VCSA     VM Memory: "
    Write-Host -NoNewline -ForegroundColor White $vcsaTotalMemory "GB "
    Write-Host -NoNewline -ForegroundColor Green "VCSA     VM Storage: "
    Write-Host -ForegroundColor White $vcsaTotalStorage "GB"
    Write-Host -NoNewline -ForegroundColor Green "SDDCm    VM CPU: "
    Write-Host -NoNewline -ForegroundColor White $sddcmTotalCPU
    Write-Host -NoNewline -ForegroundColor Green " SDDCm    VM Memory: "
    Write-Host -NoNewline -ForegroundColor White $sddcmTotalMemory "GB "
    Write-Host -NoNewline -ForegroundColor Green "SDDCm    VM Storage: "
    Write-Host -ForegroundColor White $sddcmTotalStorage "GB"

    Write-Host -ForegroundColor White "---------------------------------------------"
    Write-Host -NoNewline -ForegroundColor Green "Total CPU: "
    Write-Host -ForegroundColor White ($esxiTotalCPU + $vcsaTotalCPU + $sddcmTotalCPU)
    Write-Host -NoNewline -ForegroundColor Green "Total Memory: "
    Write-Host -ForegroundColor White ($esxiTotalMemory + $vcsaTotalMemory + $sddcmTotalMemory) "GB"
    Write-Host -NoNewline -ForegroundColor Green "Total Storage: "
    Write-Host -ForegroundColor White ($esxiTotalStorage + $vcsaTotalStorage + $sddcmTotalStorage) "GB"

    Write-Host -ForegroundColor Magenta "`nWould you like to proceed with this deployment?`n"
    $answer = Read-Host -Prompt "Do you accept (Y or N)"
    if($answer -ne "Y" -or $answer -ne "y") {
        exit
    }
    Clear-Host
}

if( $deployNestedESXiVMs -eq 1) {
    My-Logger "Connecting to Management vCenter Server $VIServer ..."
    $viConnection = Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue

    $datastore = Get-Datastore -Server $viConnection -Name $VMDatastore | Select -First 1
    $cluster = Get-Cluster -Server $viConnection -Name $VMCluster
    $datacenter = $cluster | Get-Datacenter
    $vmhost = $cluster | Get-VMHost | Select -First 1
}

if($deployNestedESXiVMs -eq 1) {
    $NestedESXiHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $VMName = $_.Key
        $VMIPAddress = $_.Value

        $ovfconfig = Get-OvfConfiguration $NestedESXiApplianceOVA
        $networkMapLabel = ($ovfconfig.ToHashTable().keys | where {$_ -Match "NetworkMapping"}).replace("NetworkMapping.","").replace("-","_").replace(" ","_")
        $ovfconfig.NetworkMapping.$networkMapLabel.value = $VMNetwork

        $ovfconfig.common.guestinfo.hostname.value = $VMName
        $ovfconfig.common.guestinfo.ipaddress.value = $VMIPAddress
        $ovfconfig.common.guestinfo.netmask.value = $VMNetmask
        $ovfconfig.common.guestinfo.gateway.value = $VMGateway
        $ovfconfig.common.guestinfo.dns.value = $VMDNS
        $ovfconfig.common.guestinfo.domain.value = $VMDomain
        $ovfconfig.common.guestinfo.ntp.value = $VMNTP
        $ovfconfig.common.guestinfo.syslog.value = $VMSyslog
        $ovfconfig.common.guestinfo.password.value = $VMPassword
        if($VMSSH -eq "true") {
            $VMSSHVar = $true
        } else {
            $VMSSHVar = $false
        }
        $ovfconfig.common.guestinfo.ssh.value = $VMSSHVar

        My-Logger "Deploying Nested ESXi VM $VMName ..."
        $vm = Import-VApp -Source $NestedESXiApplianceOVA -OvfConfiguration $ovfconfig -Name $VMName -Location $cluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

        My-Logger "Adding vmnic2/vmnic3 to Nested ESXi VMs ..."
        $vmPortGroup = Get-VirtualNetwork -Name $VMNetwork -Location ($cluster | Get-Datacenter)
        if($vmPortGroup.NetworkType -eq "Distributed") {
            $vmPortGroup = Get-VDPortgroup -Name $VMNetwork
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        } else {
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }

        $vm | New-AdvancedSetting -name "ethernet2.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet2.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        $vm | New-AdvancedSetting -name "ethernet3.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet3.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vCPU Count to $NestedESXivCPU & vMEM to $NestedESXivMEM GB ..."
        Set-VM -Server $viConnection -VM $vm -NumCpu $NestedESXivCPU -CoresPerSocket $NestedESXivCPU -MemoryGB $NestedESXivMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vSAN Cache VMDK size to $NestedESXiCachingvDisk GB & Capacity VMDK size to $NestedESXiCapacityvDisk GB ..."
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 2" | Set-HardDisk -CapacityGB $NestedESXiCachingvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 3" | Set-HardDisk -CapacityGB $NestedESXiCapacityvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Powering On VM..."
        $vm | Start-Vm -RunAsync | Out-Null
    }
}

if($moveVMsIntovApp -eq 1) {
    # Check whether DRS is enabled as that is required to create vApp
    if((Get-Cluster -Server $viConnection $cluster).DrsEnabled) {
        My-Logger "Creating vApp $VAppName ..."
        $VApp = New-VApp -Name $VAppName -Server $viConnection -Location $cluster

        if(-Not (Get-Folder $VMFolder -ErrorAction Ignore)) {
            My-Logger "Creating VM Folder $VMFolder ..."
            $folder = New-Folder -Name $VMFolder -Server $viConnection -Location (Get-Datacenter $VMDatacenter | Get-Folder vm)
        }

        if($deployNestedESXiVMs -eq 1) {
            My-Logger "Moving Nested ESXi VMs into $VAppName vApp ..."
            $NestedESXiHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
                $vm = Get-VM -Name $_.Key -Server $viConnection
                Move-VM -VM $vm -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            }
        }

        My-Logger "Moving $VAppName to VM Folder $VMFolder ..."
        Move-VApp -Server $viConnection $VAppName -Destination (Get-Folder -Server $viConnection $VMFolder) | Out-File -Append -LiteralPath $verboseLogFile
    } else {
        My-Logger "vApp $VAppName will NOT be created as DRS is NOT enabled on vSphere Cluster ${cluster} ..."
    }
}

if( $deployNestedESXiVMs -eq 1) {
    My-Logger "Disconnecting from $VIServer ..."
    Disconnect-VIServer -Server $viConnection -Confirm:$false
}

if($bootStrapFirstNestedESXiVM -eq 1) {
    do {
        My-Logger "Waiting for $bootStrapNode to be ready on network ..."
        $ping = test-connection $bootStrapNode -Quiet
        sleep 60
    } until ($ping -contains "True")

    My-Logger "Connecting to ESXi bootstrap node ..."
    $vEsxi = Connect-VIServer -Server $bootStrapNode -User root -Password $VMPassword -WarningAction SilentlyContinue

    My-Logger "Updating the ESXi host VSAN Policy to allow Force Provisioning ..."
    $esxcli = Get-EsxCli -Server $vEsxi -V2
    $VSANPolicy = '(("hostFailuresToTolerate" i0) ("forceProvisioning" i1))'
    $VSANPolicyDefaults = $esxcli.vsan.policy.setdefault.CreateArgs()
    $VSANPolicyDefaults.policy = $VSANPolicy
    $VSANPolicyDefaults.policyclass = "vdisk"
    $esxcli.vsan.policy.setdefault.Invoke($VSANPolicyDefaults) | Out-File -Append -LiteralPath $verboseLogFile
    $VSANPolicyDefaults.policyclass = "vmnamespace"
    $esxcli.vsan.policy.setdefault.Invoke($VSANPolicyDefaults) | Out-File -Append -LiteralPath $verboseLogFile

    My-Logger "Creating a single node VSAN Cluster"
    $esxcli.vsan.cluster.new.Invoke() | Out-File -Append -LiteralPath $verboseLogFile

    $luns = Get-ScsiLun -Server $vEsxi | select CanonicalName, CapacityGB

    My-Logger "Querying ESXi host disks to create VSAN Diskgroups ..."
    foreach ($lun in $luns) {
        if(([int]($lun.CapacityGB)).toString() -eq "$NestedESXiCachingvDisk") {
            $vsanCacheDisk = $lun.CanonicalName
        }
        if(([int]($lun.CapacityGB)).toString() -eq "$NestedESXiCapacityvDisk") {
            $vsanCapacityDisk = $lun.CanonicalName
        }
    }

    My-Logger "Tagging Capacity Disk ..."
    $capacitytag = $esxcli.vsan.storage.tag.add.CreateArgs()
    $capacitytag.disk = $vsanCapacityDisk
    $capacitytag.tag = "capacityFlash"
    $esxcli.vsan.storage.tag.add.Invoke($capacitytag) | Out-File -Append -LiteralPath $verboseLogFile

    My-Logger "Creating VSAN Diskgroup ..."
    $addvsanstorage = $esxcli.vsan.storage.add.CreateArgs()
    $addvsanstorage.ssd = $vsanCacheDisk
    $addvsanstorage.disks = $vsanCapacityDisk
    $esxcli.vsan.storage.add.Invoke($addvsanstorage) | Out-File -Append -LiteralPath $verboseLogFile

    My-Logger "Disconnecting from $esxi ..."
    Disconnect-VIServer $vEsxi -Confirm:$false
}

if($deployVCSA -eq 1) {
    if($IsWindows) {
        $config = (Get-Content -Raw "$($VCSAInstallerPath)\vcsa-cli-installer\templates\install\embedded_vCSA_on_ESXi.json") | convertfrom-json
    } else {
        $config = (Get-Content -Raw "$($VCSAInstallerPath)/vcsa-cli-installer/templates/install/embedded_vCSA_on_ESXi.json") | convertfrom-json
    }

    $vcsaFQDN = $VCSAHostname + "." + $VMDomain

    $config.'new_vcsa'.esxi.hostname = $bootStrapNode
    $config.'new_vcsa'.esxi.username = "root"
    $config.'new_vcsa'.esxi.password = $VMPassword
    $config.'new_vcsa'.esxi.deployment_network = "VM Network"
    $config.'new_vcsa'.esxi.datastore = "vsanDatastore"
    $config.'new_vcsa'.appliance.thin_disk_mode = $true
    $config.'new_vcsa'.appliance.deployment_option = $VCSADeploymentSize
    $config.'new_vcsa'.appliance.name = $VCSADisplayName
    $config.'new_vcsa'.network.ip_family = "ipv4"
    $config.'new_vcsa'.network.mode = "static"
    $config.'new_vcsa'.network.ip = $VCSAIPAddress
    $config.'new_vcsa'.network.dns_servers[0] = $VMDNS
    $config.'new_vcsa'.network.prefix = $VCSAPrefix
    $config.'new_vcsa'.network.gateway = $VMGateway
    $config.'new_vcsa'.os.ntp_servers = $VMNTP
    $config.'new_vcsa'.network.system_name = $vcsaFQDN
    $config.'new_vcsa'.os.password = $VCSARootPassword
    if($VCSASSHEnable -eq "true") {
        $VCSASSHEnableVar = $true
    } else {
        $VCSASSHEnableVar = $false
    }
    $config.'new_vcsa'.os.ssh_enable = $VCSASSHEnableVar
    $config.'new_vcsa'.sso.password = $VCSASSOPassword
    $config.'new_vcsa'.sso.domain_name = $VCSASSODomainName

    if($IsWindows) {
        My-Logger "Creating VCSA JSON Configuration file for deployment ..."
        $config | ConvertTo-Json -WarningAction Ignore | Set-Content -Path "$($ENV:Temp)\jsontemplate.json"

        My-Logger "Deploying VCSA to Nested ESXi VM ..."
        My-Logger "... this will take a while, go grab a drink 🍵🍺🍷"
        Invoke-Expression "$($VCSAInstallerPath)\vcsa-cli-installer\win32\vcsa-deploy.exe install --no-esx-ssl-verify --accept-eula --acknowledge-ceip $($ENV:Temp)\jsontemplate.json"| Out-File -Append -LiteralPath $verboseLogFile
    } elseif($IsMacOS) {
        My-Logger "Creating VCSA JSON Configuration file for deployment ..."
        $config | ConvertTo-Json -WarningAction Ignore | Set-Content -Path "$($ENV:TMPDIR)jsontemplate.json"

        My-Logger "Deploying VCSA to Nested ESXi VM ..."
        My-Logger "... this will take a while, go grab a drink 🍵🍺🍷"
        Invoke-Expression "$($VCSAInstallerPath)/vcsa-cli-installer/mac/vcsa-deploy install --no-esx-ssl-verify --accept-eula --acknowledge-ceip $($ENV:TMPDIR)jsontemplate.json"| Out-File -Append -LiteralPath $verboseLogFile
    } elseif ($IsLinux) {
        My-Logger "Creating VCSA JSON Configuration file for deployment ..."
        $config | ConvertTo-Json -WarningAction Ignore| Set-Content -Path "/tmp/jsontemplate.json"

        My-Logger "Deploying VCSA to Nested ESXi VM ..."
        My-Logger "... this will take a while, go grab a drink 🍵🍺🍷"
        Invoke-Expression "$($VCSAInstallerPath)/vcsa-cli-installer/lin64/vcsa-deploy install --no-esx-ssl-verify --accept-eula --acknowledge-ceip /tmp/jsontemplate.json"| Out-File -Append -LiteralPath $verboseLogFile
    }
}

if($setupNewVC -eq 1) {
    My-Logger "Connecting to the new VCSA ..."
    $vc = Connect-VIServer $VCSAIPAddress -User "administrator@$VCSASSODomainName" -Password $VCSASSOPassword -WarningAction SilentlyContinue

    $d = Get-Datacenter -Server $vc $NewVCDatacenterName -ErrorAction Ignore
    if( -Not $d) {
        My-Logger "Creating Datacenter $NewVCDatacenterName ..."
        New-Datacenter -Server $vc -Name $NewVCDatacenterName -Location (Get-Folder -Type Datacenter -Server $vc) | Out-File -Append -LiteralPath $verboseLogFile
    }

    $c = Get-Cluster -Server $vc $NewVCVSANClusterName -ErrorAction Ignore
    if( -Not $c) {
        My-Logger "Creating VSAN Cluster $NewVCVSANClusterName ..."
        New-Cluster -Server $vc -Name $NewVCVSANClusterName -Location (Get-Datacenter -Name $NewVCDatacenterName -Server $vc) -DrsEnabled -DrsAutomationLevel Manual -HAEnabled -VsanEnabled | Out-File -Append -LiteralPath $verboseLogFile

        (Get-Cluster $NewVCVSANClusterName) | New-AdvancedSetting -Name "das.ignoreRedundantNetWarning" -Type ClusterHA -Value $true -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
    }

    if($addESXiHostsToVC -eq 1) {
        $NestedESXiHostnameToIPs.GetEnumerator() | Sort-Object -Property Key | Foreach-Object {
            $VMName = $_.Key
            $VMIPAddress = $_.Value

            $targetVMHost = $VMIPAddress
            if($addHostByDnsName -eq 1) {
                $targetVMHost = $VMName + "." + $VMDomain
            }
            My-Logger "Adding ESXi host $targetVMHost to Cluster ..."
            Add-VMHost -Server $vc -Location (Get-Cluster -Name $NewVCVSANClusterName) -User "root" -Password $VMPassword -Name $targetVMHost -Force | Out-File -Append -LiteralPath $verboseLogFile
        }

        $haRuntime = (Get-Cluster $NewVCVSANClusterName).ExtensionData.RetrieveDasAdvancedRuntimeInfo
        $totalHaHosts = $haRuntime.TotalHosts
        $totalHaGoodHosts = $haRuntime.TotalGoodHosts
        while($totalHaGoodHosts -ne $totalHaHosts) {
            My-Logger "Waiting for vSphere HA configuration to complete ..."
            Start-Sleep -Seconds 60
            $haRuntime = (Get-Cluster $NewVCVSANClusterName).ExtensionData.RetrieveDasAdvancedRuntimeInfo
            $totalHaHosts = $haRuntime.TotalHosts
            $totalHaGoodHosts = $haRuntime.TotalGoodHosts
        }
    }

    if($configureVSANDiskGroup -eq 1) {
        My-Logger "Enabling VSAN & disabling VSAN Health Check ..."
        Get-VsanClusterConfiguration -Server $vc -Cluster $NewVCVSANClusterName | Set-VsanClusterConfiguration -HealthCheckIntervalMinutes 0 | Out-File -Append -LiteralPath $verboseLogFile

        foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
            if($vmhost.name -notmatch $bootStrapNode) {
                $luns = $vmhost | Get-ScsiLun | select CanonicalName, CapacityGB

                My-Logger "Querying ESXi host disks to create VSAN Diskgroups ..."
                foreach ($lun in $luns) {
                    if(([int]($lun.CapacityGB)).toString() -eq "$NestedESXiCachingvDisk") {
                        $vsanCacheDisk = $lun.CanonicalName
                    }
                    if(([int]($lun.CapacityGB)).toString() -eq "$NestedESXiCapacityvDisk") {
                        $vsanCapacityDisk = $lun.CanonicalName
                    }
                }
                My-Logger "Creating VSAN DiskGroup for $vmhost ..."
                New-VsanDiskGroup -Server $vc -VMHost $vmhost -SsdCanonicalName $vsanCacheDisk -DataDiskCanonicalName $vsanCapacityDisk | Out-File -Append -LiteralPath $verboseLogFile
            }
        }
    }
    
    if($setupVsanStoragePolicy -eq 1) {
        $datastore = Get-Datastore -Server $vc -Name "vsanDatastore" | Select -First 1
        My-Logger "Creating VSAN Storage Policies $StoragePolicyName and attaching to $datastore ..."        
        $ftt = Get-SpbmCapability -Name 'VSAN.hostFailuresToTolerate'
        $fttRule = New-SpbmRule -Capability $ftt -value $hostFailuresToTolerate
        $fttRuleSet = New-SpbmRuleSet -AllOfRules $fttRule
        $fttVsanPolicy = New-SpbmStoragePolicy -Name $StoragePolicyName -Description 'This policy is created by using hostFailuresToTolerate capability' -AnyOfRuleSets $fttRuleSet
        Set-SpbmEntityConfiguration -Configuration (Get-SpbmEntityConfiguration $datastore) -StoragePolicy $fttVsanPolicy | Out-File -Append -LiteralPath $verboseLogFile
        
        My-Logger "Associate $StoragePolicyName with $VCSADisplayName ..."
        $vm = Get-VM -Name $VCSADisplayName
        Set-SpbmEntityConfiguration -Configuration (Get-SpbmEntityConfiguration -VM $vm) -StoragePolicy $fttVsanPolicy | Out-File -Append -LiteralPath $verboseLogFile
    }
    Start-Sleep -Seconds 120

    My-Logger "Disconnecting from new VCSA ..."
    Disconnect-VIServer $vc -Confirm:$false
}


if($configureVDS -eq 1) {
    My-Logger "Connecting to the new VCSA ..."
    $vc = Connect-VIServer $VCSAIPAddress -User "administrator@$VCSASSODomainName" -Password $VCSASSOPassword -WarningAction SilentlyContinue

    # vmnic0 = Management on VSS
    # vmnic1 = unused
    # vmnic2 = Management on VDS (uplink1)
    # vmnic3 = unused

    $vds = Get-VDSwitch -Server $vc $NewVCVDSName -ErrorAction Ignore
    if( -not $vds) {
        My-Logger "Creating VDS $NewVCVDSName ..."
        $vds = New-VDSwitch -Server $vc -Name $NewVCVDSName -Location (Get-Datacenter -Name $NewVCDatacenterName) -Mtu $NewVCVDSMTU -NumUplinkPorts 2
    }

    My-Logger "Creating VDS Management Network Portgroup"
    New-VDPortgroup -Server $vc -Name $NewVCMgmtPortgroupName -Vds $vds | Out-File -Append -LiteralPath $verboseLogFile
    Get-VDPortgroup -Server $vc $NewVCMgmtPortgroupName | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort @("dvUplink1") -UnusedUplinkPort @("dvUplink2") | Out-File -Append -LiteralPath $verboseLogFile

    foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
        My-Logger "Adding $vmhost to $NewVCVDSName ..."
        $vds | Add-VDSwitchVMHost -VMHost $vmhost | Out-Null

        $vmhostNetworkAdapter = Get-VMHost $vmhost | Get-VMHostNetworkAdapter -Physical -Name vmnic2,vmnic3
        $vds | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter -Confirm:$false
    }

    if($migrateVMstoVDS -eq 1) {
        $dvPortGroup = Get-VDPortgroup -Server $vc -Name $NewVCMgmtPortgroupName

        My-Logger "Reconfiguring VMs to Distributed Portgroup ..."
        Get-VM -Server $vc -Name $VCSADisplayName | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $dvPortGroup -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
    }

    if($migrateVmkernelToVDS -eq 1) {
        $dvportgroup = Get-VDPortgroup -Server $vc -name $NewVCMgmtPortgroupName

        My-Logger "Migrating VMkernel network to VDS ..."
        foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
            $vmk = Get-VMHostNetworkAdapter -Server $vc -Name vmk0 -VMHost $vmhost
            Set-VMHostNetworkAdapter -PortGroup $dvportgroup -VirtualNic $vmk -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            Get-VMHostNetworkAdapter -Server $vc -Name vmk0 -VMHost $vmhost | Set-VMHostNetworkAdapter -Mtu $NewVCVDSMTU -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }
    }

    if($removeVSS -eq 1) {
        My-Logger "Removing VSS from ESXi hosts ..."
        foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
            $vswitch = Get-VirtualSwitch -Server $vc -VMHost $vmhost -Name vSwitch0

            Remove-VirtualSwitch -Server $vc -VirtualSwitch $vswitch -confirm:$false
        }
    }

    My-Logger "Disconnecting from new VCSA ..."
    Disconnect-VIServer $vc -Confirm:$false
}

if($finalCleanUp -eq 1) {
    My-Logger "Connecting to the new VCSA ..."
    $vc = Connect-VIServer $VCSAIPAddress -User "administrator@$VCSASSODomainName" -Password $VCSASSOPassword -WarningAction SilentlyContinue

    My-Logger "Clearing default VSAN Health Check Alarms, not applicable in Nested ESXi env ..."
    $alarmMgr = Get-View AlarmManager -Server $vc
    Get-Cluster -Server $vc | where {$_.ExtensionData.TriggeredAlarmState} | %{
        $cluster = $_
        $Cluster.ExtensionData.TriggeredAlarmState | %{
            $alarmMgr.AcknowledgeAlarm($_.Alarm,$cluster.ExtensionData.MoRef)
        }
    }
    $alarmSpec = New-Object VMware.Vim.AlarmFilterSpec
    $alarmMgr.ClearTriggeredAlarms($alarmSpec)

    # Final configure and then exit maintanence mode in case patching was done earlier
    foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
        # Disable Core Dump Warning
        Get-AdvancedSetting -Entity $vmhost -Name UserVars.SuppressCoredumpWarning | Set-AdvancedSetting -Value 1 -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        # Enable vMotion traffic
        $vmhost | Get-VMHostNetworkAdapter -VMKernel | Set-VMHostNetworkAdapter -VMotionEnabled $true -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        
        # Set VMKernel default gateway, that is a requirement of VCF 5.2.1 "Checks if Per-NIC Default Gateway is disabled in the vSAN cluster" KB https://knowledge.broadcom.com/external/article/371494 or https://knowledge.broadcom.com/external/article/308257 This code tick Override Default Gateway in VMkernel Edit vCenter UI (Credit LucD for the borrowed code below)
        $vmhostIPAddress = ($vmhost.ExtensionData.Config.Network.Vnic | ? {$_.Device -eq "vmk0"}).Spec.Ip.IpAddress
        $vEsxi = Connect-VIServer -Server $vmhostIPAddress -User root -Password $VMPassword -WarningAction SilentlyContinue
        My-Logger "Updating for VCF 5.2.1 $vmhost VSAN Per-NIC VMKernel Default Gateway (tick Override default gateway for this adapter in vCenter UI) ..."
        $esxcli = Get-EsxCli -Server $vEsxi -V2
        $if = $esxcli.network.ip.interface.ipv4.get.Invoke(@{interfacename="vmk0"})
        $iArg = @{
            netmask = $if[0].IPv4Netmask
            type    = $if[0].AddressType.ToLower()
            ipv4    = $if[0].IPv4Address
            interfacename = $if[0].Name
            gateway = $VMGateway
        }
        $esxcli.network.ip.interface.ipv4.set.Invoke($iArg) | Out-File -Append -LiteralPath $verboseLogFile

        if($vmhost.ConnectionState -eq "Maintenance") {
            Set-VMHost -VMhost $vmhost -State Connected -RunAsync -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }
    }

    Get-Cluster -Server $vc $NewVCVSANClusterName -ErrorAction Ignore | Set-Cluster -DrsAutomationLevel FullyAutomated -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

    My-Logger "Disconnecting from new VCSA ..."
    Disconnect-VIServer $vc -Confirm:$false
}

if($deploySDDCManager -eq 1) {
    My-Logger "Connecting to the new VCSA ..."
    $vc = Connect-VIServer $VCSAIPAddress -User "administrator@$VCSASSODomainName" -Password $VCSASSOPassword -WarningAction SilentlyContinue

    $datastore = Get-Datastore -Server $vc -Name "vsanDatastore" | Select -First 1
    $cluster = Get-Cluster -Server $vc -Name $NewVCVSANClusterName

    $vmhost = $cluster | Get-VMHost | where {$_.Name -ne $((Get-VM -Server $vc -Name $VCSADisplayName | Get-VMHost).Name)} | Select -Last 1

    $ovfconfig = Get-OvfConfiguration -Server $vc $SDDCManagerOVA
    $networkMapLabel = ($ovfconfig.ToHashTable().keys | where {$_ -Match "NetworkMapping"}).replace("NetworkMapping.","").replace("-","_").replace(" ","_")
    $ovfconfig.NetworkMapping.$networkMapLabel.value = $NewVCMgmtPortgroupName

    $sddcmFQDN = $SddcManagerHostname + "." + $VMDomain

    $ovfconfig.common.ROOT_PASSWORD.value = $SddcManagerRootPassword
    $ovfconfig.common.VCF_PASSWORD.value = $SddcManagerVcfPassword
    $ovfconfig.common.BASIC_AUTH_PASSWORD.value = $SddcManagerAdminPassword
    $ovfconfig.common.BACKUP_PASSWORD.value = $SddcManagerBackupPassword
    $ovfconfig.common.LOCAL_USER_PASSWORD.value = $SddcManagerLocalPassword
    $ovfconfig.common.vami.hostname.value = $sddcmFQDN
    $ovfconfig.Common.guestinfo.ntp.value = $VMNTP
    $ovfconfig.Common.FIPS_ENABLE.value = $SddcManagerFIPSEnable
    $ovfconfig.vami.SDDC_Manager.ip0.value = $SddcManagerIP
    $ovfconfig.vami.SDDC_Manager.netmask0.value = $VMNetmask
    $ovfconfig.vami.SDDC_Manager.gateway.value = $VMGateway
    $ovfconfig.vami.SDDC_Manager.domain.value = $VMDomain
    $ovfconfig.vami.SDDC_Manager.searchpath.value = $VMDomain
    $ovfconfig.vami.SDDC_Manager.DNS.value = $VMDNS

    My-Logger "Deploying SDDC Manager VM $SddcManagerDisplayName ..."
    $vm = Import-VApp -Server $vc -Source $SDDCManagerOVA -OvfConfiguration $ovfconfig -Name $SddcManagerDisplayName -Location $cluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

    My-Logger "Powering On VM ..."
    $vm | Start-Vm -RunAsync | Out-Null

    My-Logger "Waiting 7 minutes for SDDC Manager VM to be up, meanwhile double-check no $SddcManagerHostname entry in ~\.ssh\known_hosts ..."
    Start-Sleep -Seconds 420

    My-Logger "Disconnecting from new VCSA ..."
    Disconnect-VIServer $vc -Confirm:$false
}

if($uploadVCFImportTool -eq 1) {
    My-Logger "Connecting to new vCenter Server $VCSADisplayName ..."
    $viConnection = Connect-VIServer $VCSAIPAddress -User "administrator@$VCSASSODomainName" -Password $VCSASSOPassword -WarningAction SilentlyContinue

    $VCFImportToolFile = Split-Path $VCFImportToolpath -Leaf

    # VCSA
    $vcsaVM = Get-VM -Server $viConnection $VCSADisplayName

    My-Logger "Copying $VCFImportToolpath to vCenter Server $VCSADisplayName under /root ..."
    Copy-VMGuestFile -VM $vcsaVM -Source $VCFImportToolpath -Destination "/root/" -LocalToGuest -GuestUser "root" -GuestPassword $VCSARootPassword

    $extractCommand = "gunzip < `"/root/${VCFImportToolFile}`" | tar -xf - -C '/tmp/'"
    Invoke-VMScript -ScriptText $extractCommand -VM $vcsaVM -GuestUser "root" -GuestPassword $VCSARootPassword  | Out-Null

    # SDDCm
    $sddcmVM = Get-VM -Server $viConnection $SddcManagerDisplayName

    My-Logger "Copying $VCFImportToolpath to SDDC Manager $SddcManagerDisplayName under /home/vcf ..."
    Copy-VMGuestFile -VM $sddcmVM -Source $VCFImportToolpath -Destination "/home/vcf" -LocalToGuest -GuestUser "vcf" -GuestPassword $SddcManagerVcfPassword

    $extractCommand = "gunzip < `"/home/vcf/${VCFImportToolFile}`" | tar -xf - -C '/home/vcf/'"
    Invoke-VMScript -ScriptText $extractCommand -VM $sddcmVM -GuestUser "vcf" -GuestPassword $SddcManagerVcfPassword | Out-Null

    My-Logger "Disconnecting from $VIServer ..."
    Disconnect-VIServer -Server $viConnection -Confirm:$false
}

if($generateNsxSpecJson -eq 1) {
    $NsxBundleFile = Split-Path $NSXBundlePath -Leaf
    $vcfConfig = [ordered]@{
	  "deploy_without_license_keys" = $true
	  "form_factor" = $NsxFormFactor
	  "admin_password" = "$SddcManagerAdminPassword"
	  "install_bundle_path" = "/nfs/vmware/vcf/nfs-mount/bundle/$NsxBundleFile"
	  "cluster_ip" = "$NSXClusterVip"
	  "cluster_fqdn" = "$NSXClusterVipHostname.$VMDomain"
	  "manager_specs" = @([ordered]@{
			  "fqdn" = "$NSXManagerNode1Hostname.$VMDomain";
			  "name" = "$NSXManagerNode1Hostname";
			  "ip_address" = "$NSXManagerNode1IP";
			  "gateway" = "$VMGateway";
			  "subnet_mask" = "$VMNetmask";
		  }, [ordered]@{
			  "fqdn" = "$NSXManagerNode2Hostname.$VMDomain";
			  "name" = "$NSXManagerNode2Hostname";
			  "ip_address" = "$NSXManagerNode2IP";
			  "gateway" = "$VMGateway";
			  "subnet_mask" = "$VMNetmask";
		  }, [ordered]@{
			  "fqdn" = "$NSXManagerNode3Hostname.$VMDomain";
			  "name" = "$NSXManagerNode3Hostname";
			  "ip_address" = "$NSXManagerNode3IP";
			  "gateway" = "$VMGateway";
			  "subnet_mask" = "$VMNetmask";
		  })
	}
    My-Logger "Generating NSX Spec deployment file $NsxSpecJsonPath"
    $vcfConfig | ConvertTo-Json -Depth 20 -WarningAction Ignore | Set-Content -Path $NsxSpecJsonPath
}

if($uploadNSXBundlePath -eq 1) {
    My-Logger "Connecting to new vCenter Server $VCSADisplayName ..."
    $viConnection = Connect-VIServer $VCSAIPAddress -User "administrator@vsphere.local" -Password $VCSASSOPassword -WarningAction SilentlyContinue

	$NsxSpecJsonFile = Split-Path $NsxSpecJsonPath -Leaf

    # SDDCm
    $sddcmVM = Get-VM -Server $viConnection $SddcManagerDisplayName

    My-Logger "Copying $NsxSpecJsonPath to SDDC Manager $SddcManagerDisplayName under /home/vcf ..."
    Copy-VMGuestFile -VM $sddcmVM -Source $NsxSpecJsonPath -Destination "/home/vcf/$NsxSpecJsonFile" -LocalToGuest -GuestUser "vcf" -GuestPassword $SddcManagerVcfPassword -Force -Confirm:$false
	
    My-Logger "Input SDDC Manager password $SddcManagerVcfPassword to start Copying $NSXBundlePath to SDDC Manager $SddcManagerHostname under /nfs/vmware/vcf/nfs-mount/bundle ..."
	scp -po StrictHostKeyChecking=no $NSXBundlePath "vcf@$($SddcManagerHostname):/nfs/vmware/vcf/nfs-mount/bundle"

    My-Logger "Disconnecting from $VIServer ..."
    Disconnect-VIServer -Server $viConnection -Confirm:$false
}


if($generateVCFImportConvertCommand -eq 1) {
    My-Logger "SSH to SDDC Manager $($SddcManagerHostname) using ``vcf`` account and run the following command in VCF Import Tool Directory:"
    My-Logger " "
    My-Logger "python3 vcf_brownfield.py convert --vcenter `'$($VCSAHostname + "." + $VMDomain)`' --sso-user `'administrator@$($VCSASSODomainName)`' --domain-name `'$($VCFManagementDomainName)`' --nsx-deployment-spec-path `'$('/home/vcf/' + $NsxSpecJsonFile)`' --auto-proceed --sso-password 'VMware1!' --vcenter-root-password `'$($VCSARootPassword)`' --local-admin-password `'$($SddcManagerLocalPassword)`' --backup-password `'$($SddcManagerBackupPassword)`' --accept-trust --suppress-warnings"
}


$EndTime = Get-Date
$duration = [math]::Round((New-TimeSpan -Start $StartTime -End $EndTime).TotalMinutes,2)
My-Logger " "
My-Logger "VMware Cloud Foundation (VCF) Import Lab Deployment Complete!"
My-Logger "StartTime: $StartTime"
My-Logger "  EndTime: $EndTime"
My-Logger " Duration: $duration minutes"
