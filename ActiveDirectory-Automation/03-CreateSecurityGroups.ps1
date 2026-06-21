# 03-CreateSecurityGroups.ps1
# Purpose: Automate the creation of departmental Security Groups in Active Directory

Import-Module ActiveDirectory

# Define target infrastructure parameters
$TargetOU = "OU=Security Groups, OU=ActiveDirectory-Automation, DC=lab, DC=local"
$Departments = @("IT", "HR", "Finance", "Operations")

Write-Host "Starting Security Group deployment process..." -ForegroundColor Cyan


foreach($Dept in $Departments){
    $GroupName = "GG_$Dept`_-Users" # Using Global Group naming convention (e.g., GG_IT-Users)
    $Descriptions = "Global Security Group for all $Dept department personnel."

    # Check if the group already exists in the domain
    $GroupExist = Get-ADGroup -Filter "Name -eq '$GroupName'"

    if(-not $GroupExist){
        Write-Host "Group '$GroupName'" -ForegroundColor Yellow

        # Create the group with standard corporate specifications
        New-ADGroup -Name $GroupName `
                    -GroupScope Global `
                    -GroupCategory Security `
                    -Path $TargetOU `
                    -Description $Descriptions `
                    -PassThru
        
        Write-Host "Succcessfully created group: $GroupName" -ForegroundColor Green
        
    }else {
        Write-Host "Group '$GroupName' already exist. Skipping creation." -ForegroundColor Grey
    }
}

Write-Host "Security Group deployment process completed." -ForegroundColor Cyan