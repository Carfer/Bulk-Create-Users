# Define a secure initial password for the test users
$SecurePassword = ConvertTo-SecureString "Bootcamp2026!" -AsPlainText -Force

# Create a list of names to import
$UserList = @("John.Doe", "Jane.Smith", "Robert.Johnson", "Emily.Davis", "Michael.Brown")

# Loop through the list and create each user inside the IT OU
foreach ($User in $UserList) {
    New-ADUser -Name $User `
               -SamAccountName $User `
               -UserPrincipalName "$User@lab.local" `
               -Path "OU=IT,OU=TechCorp,DC=lab,DC=local" `
               -AccountPassword $SecurePassword `
               -ChangePasswordAtLogon $true `
               -Enabled $true
    
    Write-Host "Successfully created user: $User" -ForegroundColor Green
