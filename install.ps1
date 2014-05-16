[CmdletBinding()]
param(
    $RootDataPath
)

#
# Assumes:
#  Ruby Installed
#  Ruby DevKit Installed
#  Go Installed
#  Git installed
# 
# In Path:
#   gem
#   bundle
#   Git
#
# In Package:
#  dea_ng source
#  eventmachine source
#



#
# Functions
#
function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

function AddFirewallRules($exePath, $ruleName) {
    . netsh.exe advfirewall firewall add rule name="$ruleName"-allow dir=in action=allow program="$exePath"
    . netsh.exe advfirewall firewall add rule name="$ruleName"-out-allow dir=out action=allow program="$exePath"
}

function DEAServiceRemove {
    Write-Host "Removing existing DEA Service"
    . sc.exe stop $DeaServiceName
    . sc.exe delete $DeaServiceName
}

function DEAServiceInstall {
    Write-Host 'Installing dea_ng Service'
    #
    # Install dea_ng Service
    #
    RemoveFirewallRules 'ruby-193'

    $rubywBinPath = Join-Path $RubyBinPath 'ruby.exe'
    $deaServiceBinPath = "$rubywBinPath -C $DeaAppPath dea_winsvc.rb $DeaConfigFilePath"

    . sc.exe create $DeaServiceName start= delayed-auto binPath= $deaServiceBinPath displayName= "$DeaServiceDescription" depend= "$DirectoryServiceServiceName/$WardenServiceName"
    . sc.exe failure $DeaServiceName reset= 86400 actions= 'restart/60000/restart/60000/restart/60000'

    AddFirewallRules $rubywBinPath 'ruby-193'

    Write-Host 'Finished Installing dea_ng Service'
}

function DEAServicePrepare {
    Write-Host 'Installing DEA dependent GEMs (this may take a while)'

    Write-Host 'Updating GEM packages for dea_ng'
    . gem update --system --quiet
    . gem install bundle --no-document --quiet

    Set-Location $DeaAppPath
    . bundle install --quiet

    $curlRoot = Resolve-Path (Join-Path $StartDirectory '\tools\curl')
    Write-Host "Retrieving and installing patron gem"
    . gem install patron -v '0.4.18' --no-document --platform=x86-mingw32 -- -- --with-curl-lib="$curlRoot\bin" --with-curl-include="$curlRoot\include"

    Write-Host 'Finished Installing DEA dependent GEMs'
}

function DirectoryServiceInstall {
    Write-Host 'Installing Directory Service'
    #
    # Install Directory Service
    #
    RemoveFirewallRules "IF_winrunner"

    $directoryService = Join-Path $InstallPath "go\winrunner.exe"

    Write-Host "WinRunner Exe: $directoryService"
    Write-Host "Dea Path: $DeaConfigFilePath"

    . $directoryService stop
    . $directoryService remove 

    . $directoryService install "$DeaConfigFilePath"

    AddFirewallRules $directoryService "IF_winrunner"
    
    Write-Host 'Finished Installing Directory Service'
}

function EventMachinePrepare {
    Write-Host 'Build and install custom event machine'

    Set-Location $InstallPath
    git clone https://github.com/IronFoundry/eventmachine.git eventmachine

    Set-Location "$InstallPath\eventmachine"
    . gem uninstall eventmachine --force --version 1.0.3 --quiet
    . gem build eventmachine.gemspec --quiet
    . gem install eventmachine-1.0.3.gem  --quiet
}

function FindApp($appName) {
    # Search path for app
    foreach ($path  in $env:PATH.Split(";") ) {
        $name = "${path}\${appName}"
        $name = $name.Replace("`"", "")      
        if (Test-Path $name) {
            return $name
        }
    }    

    return $null
}

function IsAdmin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    return $principal.IsInRole($adminRole)
}

function RemoveFirewallRules($ruleName) {
     . netsh.exe advfirewall firewall delete rule name="$ruleName"-allow
     . netsh.exe advfirewall firewall delete rule name="$ruleName"-allow-out
}

function VerifyDependencies {
    Write-Host 'Verifying dependencies'
    $success = $true

    $rubyApp = (FindApp 'ruby.exe')
    if (!$rubyApp) {
        Write-Error 'Unable to find Ruby'
        $success = $false
    } else {
        Write-Verbose "Found ruby.exe at $rubyApp"
    }

    $Script:RubyBinPath = Split-Path $rubyApp -Parent
    if (!$RubyBinPath) {
        Write-Error 'Unable to determine Ruby bin path'
        $success = $false
    } else {
        Write-Verbose "Found Ruby bin path at $RubyBinPath"
    }

    $goApp = (FindApp 'go.exe')
    if (!$goApp) {
        Write-Error 'Unable to find Go'
        $success = $false
    } else {
        Write-Verbose "Found Go at $goApp"
    }

    $gitApp = (FindApp 'git.exe')
    if (!$gitApp) {
        Write-Error 'Unable to find git.exe'
        $success = $false
    } else {
        Write-Verbose "Found Git at $gitApp"
    }

    return $success
}


#
# Global Settings
#
$DeaServiceName = 'IFDeaSvc'
$DeaServiceDescription = 'IronFoundry DEA'
$WardenServiceName = 'IronFoundry.Warden'
$DirectoryServiceServiceName = 'IFDeaDirSvc'
$DeaConfigFilePath = Join-Path $RootDataPath 'dea_ng\config\dea.yml'

$StartDirectory = (Get-ScriptDirectory)
$InstallPath = $StartDirectory
$RubyBinPath = $null
$DeaAppPath = Join-Path $InstallPath 'bin'

#
# Main
#
if (!(IsAdmin)) {
    Write-Error 'This install script requires admin privileges. Please re-run the script as an Administrator.'
    exit 1
}

if (!(VerifyDependencies)) {
    Write-Error 'Unable to find one or more dependencies.'
    exit 1
}

DEAServiceRemove
DEAServicePrepare
EventMachinePrepare
DirectoryServiceInstall
DEAServiceInstall

Set-Location $StartDirectory
