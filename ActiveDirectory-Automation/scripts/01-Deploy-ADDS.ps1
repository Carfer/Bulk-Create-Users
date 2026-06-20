Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Import-Module ADDSDeployment
Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName "lab.local" `
    -DomainNetbiosName "LAB" `
    -ForestMode "WinThreshold" `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysVolPath "C:\Windows\SYSVOL" `
    -Force:$true

# Create Main Corporate OU
New-ADOrganizationalUnit -Name "TechCorp" -Path "DC=lab,DC=local"

# Create Departmental Sub-OUs
New-ADOrganizationalUnit -Name "IT" -Path "OU=TechCorp,DC=lab,DC=local"
New-ADOrganizationalUnit -Name "HR" -Path "OU=TechCorp,DC=lab,DC=local"
New-ADOrganizationalUnit -Name "Finance" -Path "OU=TechCorp,DC=lab,DC=local"

