# 05-DelegatePermissions.ps1
# Purpose: Create a Domain Local group for Helpdesk and automate RBAC delegation over the Automation OU.


Import-Module ActiveDirectory


# 1. Define Infrastructure Parameters
$TargetOUDN = "OU=ActiveDirectory-Automation, DC=lab, DC=local"
$GroupName ="DL_Helpdesk_Modify-Users"
$GroupOUDN = "OU=Security Groups,OU=ActiveDirectory-Automation, DC=lab, DC=local"

Write-Host "Starting RBAC Permission Delegation..." -ForegroundColor Cyan

# 2. Ensure the Domain Local Permission Group Exists
$GroupExists = Get-ADGroup -Filter "Name -eq '$GroupName'"

if(-not $GroupExists){
    New-ADGroup -Name $GroupName `
                -GroupScope DomainLocal `
                -GroupCategory Security `
                -Path $GroupOUDN `
                -Description "Role Group: Members can create, delete, and manage user accounts inside the Automation OU."
    Write-Host "[+] Successfully created permission role group: $GroupName" -ForegroundColor Green
}else{
    Write-Host "[*] Permission role group $GroupName already exists. Skipping creation." -ForegroundColor Gray
}


# 3. Establish the Active Directory Drive Context
# This allows us to navigate AD object permissions like a local drive
if(-not (Get-PSDrive -Name AD -ErrorAction SilentlyContinue)){
    New-PSDrive -Name AD -PSProvider ActiveDirectory -Root "" | Out-Null
}

# 4. Retrieve Current Access Control List (ACL) of the Target OU
$OUPath = "AD:\$TargetOUDN"
$ACL = Get-Acl -Path $OUPath

# 5. Define the Security Principal (The Role Group)
$GroupSID = (Get-ADGroup -Identity $GroupName).SID
$IdentityReference = New-Object System.Security.Principal.SecurityIdentifier($GroupSID)


# 6. Define the Advanced Active Directory Rights
# ActiveDirectoryRights: GenericRead, CreateChild, DeleteChild (Allows managing child user objects)
# AccessControlType: Allow
# ActiveDirectorySecurityInheritance: All (Inherits down to all sub-containers/objects)
$AdRight = [System.DirectoryServices.ActiveDirectoryRights]::CreatedChild -bor [System.DirectoryServices.ActiveDirectoryRights]::DeleteChild
$AccessType = [System.Security.AccessControl::AccessControlType]::Allow
$Inheritance = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All

# 7. Create the Access Rule Object
$ValidationRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
    $IdentityReference,
    $AdRight,
    $AccessType,
    $Inheritance
)

# 8. Apply the Rule to the ACL and save it back to Active Directory
$ACL.AddAccessRule($ValidationRule)
Set-Acl -Path $OUPath -AclObject $ACL

Write-Host "[+] Successfully delegated 'Create/Delete Child Objects' permissions to $GroupName over the OU." -ForegroundColor Green
Write-Host "RBAC script execution completed successfully." -ForegroundColor Cyan


