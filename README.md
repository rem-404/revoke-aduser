# Revoke-ADUser
*This script is for a lab environment and meant for learning purposes only*

## What does it do
Takes a list of users from a CSV or pipeline and runs a full offboarding sequence for each one:

- Looks up the account by first name and last name
- Disables the AD account
- Stamps the description field with the disable date and reason
- Moves the account to the Terminated OU
- Includes a `-WhatIf` flag to preview what would happen before running anything destructive.

## What does it solve
HR CSVs don't always have `SAMAccountNames` — they have names. This script works from `GivenName` and `Surname` directly, handles duplicates safely, skips missing accounts with a warning, and leaves an audit trail on every disabled account.
Who's it for
Sysadmins handling user offboarding in a Windows/Active Directory environment where HR provides a name-based CSV instead of `SAMAccountNames`.

## Requirements
- PowerShell with the ActiveDirectory module (RSAT)
- $cred loaded in your session (see note below) or a domain account where Kerberos handles authentication transparently
- The Terminated OU must already exist: ou=Terminated,dc=lab,dc=local — update to match your environment

```
Usage
# Preview — shows what would happen without making any changes
Import-Csv .\revoke.csv | Revoke-ADUser -WhatIf

# Bulk offboarding from CSV
Import-Csv .\revoke.csv | Revoke-ADUser

# Single user
Revoke-ADUser -GivenName "John" -SurName "O'Conor" -Reason "Resigned"

# Confirm each action individually
Import-Csv .\revoke.csv | Revoke-ADUser -Confirm

# CSV format:
GivenName,SurName,Reason
John,Doe,Resigned
Jane,Smith,End of Contract

Reason is optional — defaults to "not specified" if not provided.
```

## Warning

- `$cred` in `$adParams` is intentional — running as a local admin against a separate domain means Kerberos doesn't work. Change to `$Credential` if running from a domain joined machine with a domain account
- The script will not proceed if multiple accounts match the same first and last name — manual intervention required in that case
- `-WhatIf` is strongly recommended before the first run in any new environment
- `$TargetOU` is hardcoded as a default parameter — override at runtime if needed:

`Import-Csv .\revoke.csv | Revoke-ADUser -TargetOU "ou=Disabled,dc=company,dc=com"`

## Limitations

- Name matching only — no SAMAccountName fallback
- Apostrophes and trimming are handled but other special characters (accented letters, hyphens in names) are not explicitly sanitized yet
- No logging to file — audit trail is written to the AD Description field only
- END {} block is empty — placeholder for future use

## Notes
Work in progress — file logging and extended special character sanitization coming in a future iteration. The Description stamp is designed to be machine-readable for a future scavenger script that will clean up accounts disabled for 30+ days.

## Sample Output
```
# -WHATIF
PS C:\Logs> import-csv .\revoke.csv | revoke-aduser -WhatIf
What if: Performing the operation "Offboard AD user (disable, stamp, move)" on target "username01".
What if: Performing the operation "Offboard AD user (disable, stamp, move)" on target "username02".
What if: Performing the operation "Offboard AD user (disable, stamp, move)" on target "username03".
What if: Performing the operation "Offboard AD user (disable, stamp, move)" on target "username04".
PS C:\Logs>

# BULK USAGE
PS C:\Logs> import-csv .\revoke.csv | revoke-aduser
Successfully offboarded: name01 surname01 (username01)
Successfully offboarded: name02 surname02 (username02)
Successfully offboarded: name03 surname03 (username03)
Successfully offboarded: name04 surname04 (username04)
PS C:\Logs>

# SINGLE USAGE
PS C:\Logs> revoke-aduser -givenname "john" -surname "o'conor" -reason 'test revocation'
Successfully offboarded: john o'conor (jO'Conor)

PS C:\Logs> revoke-aduser -givenname name02 -surname surname02 -reason 'test revocation'
Successfully offboarded: name02 surname02 (username02)

PS C:\Logs> revoke-aduser -givenname name02 -surname surname03 -reason 'test revocation'
WARNING: user not found in AD: name02 surname03. Skipping...

PS C:\Logs> revoke-aduser -givenname name02 -reason 'test revocation'
cmdlet revoke-aduser at command pipeline position 1
Supply values for the following parameters:
SurName:

# WITH MULTIPLE HIT
PS C:\Logs> revoke-aduser -givenname ken -surname hadou -reason 'test revocation'
revoke-aduser: Critical: Multiple users found named: 'ken hadou'! Manual intervention required. Affected samaccountnames: hadouken,hKen

PS C:\Logs>
```
