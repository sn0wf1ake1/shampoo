Clear-Host

<#
Shampoo: Generates a SHA512 password every time the data exceeds the limit of the password based on the
         previous password for use as a one-time pad

1) Comments. Lots and lots of comments so anyone can easily understand what is going on
2) No divisions, floats or decimals
3) Strongly defined data types, i.e. no casting from byte to integer mid-program. Casting to string is unavoidable though in some cases because PowerShell can be quirky
4) Compartualize as much as possible using functions no matter how irrelavent it may seem (kudos to Java and Linux)
5) No external modules allowed and must work on all platforms supported by PowerShell out of the box
#>

[string]$password = 'sn0wf1ake1'
[array]$password = $password.ToCharArray() # Input will be [string] so do the conversion to [array] swiftly
[byte]$i = $null

function password_seed {
    param(
        [Parameter(Mandatory = 1, Position = 0)] [array]$password
    )

    while($password.Count -le 768) { # 768 bytes was chosen for test purposes but actually seems fine
        [object]$password_SHA512 = [System.IO.MemoryStream]::new([byte[]][char[]]$password) # SHA512 initiation
        [string]$password_SHA512 = [System.Convert]::ToString((Get-FileHash -InputStream $password_SHA512 -Algorithm SHA512).Hash) # SHA512 encoding

        for($i = 0; $i -le 127; $i++) {
            $password += [byte][char]$password_SHA512[$i] % 11 # Mod 11 is very important, otherwise it will spew out a lot of 5's and 6's because of the ASCII table
        }
    }

    return $password
}

$password = password_seed $password # Temporary step for generating the password. NOT the final password!

function password_SHA512_cycle { # Generates a new password based on the old password
    param(
        [Parameter(Mandatory = 1, Position = 0)] [array]$password # [string] will work but throws a soft error in Visual Studio Code. Changing to [array] fixes it
    )

    [object]$password_SHA512 = [System.IO.MemoryStream]::new([byte[]][char[]]($password -join $null)) # SHA512 initiation
    [string]$password_SHA512 = [System.Convert]::ToString((Get-FileHash -InputStream $password_SHA512 -Algorithm SHA512).Hash) # SHA512 encoding
    [string]$password_SHA512_extended = $null

    for($i = 0; $i -le 127; $i++) {
        $password_SHA512_extended += [byte][char]$password_SHA512[$i] % 10 # Mod 10 is very important, otherwise it will spew out a lot of 5's and 6's because of the ASCII table
    }

    $password = $password[128..$password.Count] # Crop out the old first 128 bytes first to save memory
    $password += $password_SHA512_extended.ToCharArray() # Append the newly generated 128 bytes
    return $password
}
