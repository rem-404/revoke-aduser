<#
get a list of user from csv or pipeline inputs and do this: fetch account --> disable account --> modify account add time stamp --> move account to ou


CSV FORMAT
GivenName, Surname, Reason

#>

function revoke-aduser {
  [cmdletbinding()]
  param (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$givenname,
        
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$surname,
        
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
    [string]$reason,

    [pscredential]$credential
  ) # param

  BEGIN {
    <#
       if (-not $credential) {
      $credential = get-credential
    } 
    #>
    $date = (get-date -format 'yyyy-MM-dd')
  }

  PROCESS {
    

    # filtering account using provided details: firstName and surName
    $found = Get-ADUser -Filter { GivenName -eq $givenname -and Surname -eq $surname } -Credential $cred

    # if no match - just log
    if (-not $found) {
      "`(If construct) $givenname $surname not found: log"
    }
    # if multiple match: log and do nothing
    elseif ($found.Count -gt 1) {
      "(elseif construct) Multiple users found — manual review needed: log"
      "$givenname $surname"
    }
    #if exact match: run the script
    else {
      try {
        "`(try inside else) run the revoking script (disable+move+stamp)"
        "$givenname $surname has been terminated. Reason: $reason on $date"
      }
      catch {

      } # try/catch

    } # if/elseif/else

  } # process

  END {}
} # function
