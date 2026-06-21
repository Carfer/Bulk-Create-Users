# 04-AssignUsersToGroups.ps1
# Purpose: Automatically assign users to their respective departmental security groups based on their Department attribute.

Import-Module ActiveDirectory

# Define target infrastructure parameters
$SearchBaseOU = "OU=ActiveDirectory-Automation, DC=lab, DC=local"


Write-Host "Starting automated group assignment process..." -ForegroundColor Cyan

# 1. Get all AD users within our specific automation OU (loading the Department property explicitly)

$Users = Get-ADUser -Filter * -SearchBase $SearchBaseOU -Propieties Department

foreach ($User in $Users) {
   # Check if the user has a department assigned
   if ($User.Department) {
        $Dept = $User.Department
        $TargetGroupName = "GG_$Dept`_-Users"  # Standard corporate naming convention

        Write-Host "Processing user: $($User.SamAccountName) [Deparment: $Dept]" -ForegroundColor White

        # 2. Check if the target security group exists in the domain
        $GroupExists = Get-ADGroup -Filter "Name -eq '$TargetGroupName'"

        if ($GroupExists) {
            # 3. Check if the user is ALREADY a member of that group
            $IsMember = Get-ADGroupMember -Identity $TargetGroupName | Where-Object { $_.SamAccountName -eq $User.SamAccountName }

            if (-not $IsMember) {
                # 4. Add user to the group safely
                Add-ADGroupMember -Identity $TargetGroupName -Members $User.SamAccountName
                Write-Host "-> Successfully added to group: $TargetGroupName" -ForegroundColor Green
            }else {
                Write-Host "-> User is already a member of $TargetGroupName" -ForegroundColor Grey
            }else {
                Write-Host "-> Target group '$TargetGroupName' does not exist in AD. Please run the creation script first."
            }else {
                Write-Host "-> User $($User.SamAccountName) has no Department defined. Skipping mapping." -ForegroundColor Yellow
            }

        }

   }
}

Write-Host "Group assigment process completed." -ForegroundColor Cyan