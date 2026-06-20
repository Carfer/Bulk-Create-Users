# Active Directory Bulk User Provisioning Script

A lightweight PowerShell script designed to automate the onboarding and batch creation of user accounts inside a specific Active Directory Organizational Unit (OU).

## Features
* **Automation:** Uses a `foreach` loop to process a batch list of identities instantly.
* **Security:** Converts plain-text passwords into secure strings (`AsPlainText -Force`) during account creation.
* **Compliance:** Enforces the `ChangePasswordAtLogon` flag to ensure users reset their passwords on their first login.

## Prerequisites
* Active Directory Domain Services (AD DS) role installed.
* PowerShell ActiveDirectory module (`Import-Module ActiveDirectory`).
