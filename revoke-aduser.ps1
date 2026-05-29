<#
get a list of user from csv or pipeline inputs and do this: fetch account --> disable account --> modify account add time stamp --> move account to ou

CSV FORMAT
GivenName, Surname, Reason
#>

function Revoke-ADUser {
  [cmdletbinding(supportsshouldprocess)]
  param (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$GivenName,
        
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$SurName,
        
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
    [string]$Reason = "not specified",

    [string]$TargetOU = "ou=Terminated,dc=lab,dc=local",

    [pscredential]$Credential

  ) # param

  BEGIN {
    $Date = (Get-Date -format 'yyyy-MM-dd')

    # Dynamic parameters for AD commands
    $adParams = @{
      Credential = $cred # <-- Change this to $Credential if used by a domain account
      ErrorAction = 'Stop'
    }

  }

  PROCESS {

    # Normalizer
    $GivenName = $GivenName.Trim()
    $SurName = $SurName.Trim()

    # Safeguard for aposthrope
    $SafeSurname = $SurName -replace "'", "''"
    $SafeGivenname = $GivenName -replace "'", "''"

    # Filtering account using provided details: firstName and surName - push result into an array format using @(...)
    # -Credential $cred is intentional, not a mistake. Local Admin + separate domain = Kerberos doesn't work
    $found = @(Get-ADUser -Filter "GivenName -eq '$SafeGivenName' -and Surname -eq '$SafeSurname'" @adparams)

    # if no match - just log
    if ($found.count -eq 0) {
      write-warning "user not found in AD: $GivenName $SurName. Skipping..."
    }
    # if multiple match: log and do nothing
    elseif (@($found).Count -gt 1) {
      write-error "Critical: Multiple users found named: '$GivenName $SurName'! Manual intervention required. Affected samaccountnames: $($found.SamAccountName -join ',')"
    }
    # If exact match: run the script
    else {

      # Extract a single user from the array
      $TargetUser = $found[0]
      try {

        # Running critical cmdlet: Disable -> Stamp -> Move
        if ($PSCmdlet.ShouldProcess($TargetUser.SamAccountName, "Offboard AD user (disable, stamp, move)")) {


          Disable-ADAccount -Identity $TargetUser.DistinguishedName @adParams

          $StatusMessage = "Disabled via automation on $Date. Reason: $reason"
          Set-ADUser -Identity $TargetUser.DistinguishedName -Description $StatusMessage @adParams

          Move-ADObject -Identity $TargetUser.DistinguishedName -TargetPath $TargetOU @adParams

          write-host "Successfully offboarded: $GivenName $SurName ($($TargetUser.SamAccountName))" -foregroundcolor green
        }
        
      } 
      catch {
        write-error "Failed to process offboarding for $($TargetUser.SamAccountName) : $($_.Exception.message)"
      } # try/catch

    } # if/elseif/else

  } # PROCESS

  END {}
} # Function
