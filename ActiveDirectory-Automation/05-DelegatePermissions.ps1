# 05-DelegatePermissions.ps1 (V2)
# Purpose: Create a Domain Local group for Helpdesk and automate Password Reset / Account Unlock delegation over the Automation OU.

Import-Module ActiveDirectory

# 1. Define Infrastructure Parameters
$TargetOUDN = "OU=ActiveDirectory-Automation,DC=lab,DC=local"
$GroupName ="DL_Helpdesk_Modify-Users"
$GroupOUDN = "OU=Security Groups,OU=ActiveDirectory-Automation,DC=lab,DC=local"

Write-Host "Starting RBAC Permission Delegation..." -ForegroundColor Cyan

# 2. Ensure the Domain Local Permission Group Exists
$GroupExists = Get-ADGroup -Filter "Name -eq '$GroupName'"

if(-not $GroupExists){
    New-ADGroup -Name $GroupName `
                -GroupScope DomainLocal `
                -GroupCategory Security `
                -Path $GroupOUDN `
                -Description "Role Group: Members can reset passwords and unlock user accounts inside the Automation OU."
    Write-Host "[+] Successfully created permission role group: $GroupName" -ForegroundColor Green
}else{
    Write-Host "[*] Permission role group $GroupName already exists. Skipping creation." -ForegroundColor Gray
}

# 3. Establish the Active Directory Drive Context
if(-not (Get-PSDrive -Name AD -ErrorAction SilentlyContinue)){
    New-PSDrive -Name AD -PSProvider ActiveDirectory -Root "" | Out-Null
}

# 4. Retrieve Current Access Control List (ACL) of the Target OU
$OUPath = "AD:\$TargetOUDN"
$ACL = Get-Acl -Path $OUPath

# 5. Define the Security Principal (The Role Group)
$GroupSID = (Get-ADGroup -Identity $GroupName).SID
$IdentityReference = New-Object System.Security.Principal.SecurityIdentifier($GroupSID)

# 6. Define Active Directory Schema GUIDs
$UserClassGuid    = New-Object System.Guid "bf967aba-0de6-11d0-a285-00aa003049e2" # Schema GUID for User Objects
$ResetPasswordGuid = New-Object System.Guid "00299570-246d-11d0-a768-00aa006e0529" # Extended Right GUID for Reset Password
$LockoutTimeGuid   = New-Object System.Guid "28630ebf-41d5-11d1-a9c1-0000f8757930" # Property GUID for lockoutTime

# 7. Create the Access Rule Objects
# Rule A: Allow Password Reset on descendant User objects
$ResetPasswordRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
    $IdentityReference,
    [System.DirectoryServices.ActiveDirectoryRights]::ExtendedRight,
    [System.Security.AccessControl.AccessControlType]::Allow,
    $ResetPasswordGuid,
    [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Descendents,
    $UserClassGuid
)

# Rule B: Allow Account Unlocks (Read/Write lockoutTime property) on descendant User objects
$UnlockAccountRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
    $IdentityReference,
    ([System.DirectoryServices.ActiveDirectoryRights]::ReadProperty -bor [System.DirectoryServices.ActiveDirectoryRights]::WriteProperty),
    [System.Security.AccessControl.AccessControlType]::Allow,
    $LockoutTimeGuid,
    [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Descendents,
    $UserClassGuid
)

# 8. Apply the Rules to the ACL and save it back to Active Directory
$ACL.AddAccessRule($ResetPasswordRule)
$ACL.AddAccessRule($UnlockAccountRule)
Set-Acl -Path $OUPath -AclObject $ACL

Write-Host "[+] Successfully delegated 'Reset Password' and 'Unlock Account' permissions to $GroupName over descendant User objects." -ForegroundColor Green
Write-Host "RBAC script execution completed successfully." -ForegroundColor Cyan