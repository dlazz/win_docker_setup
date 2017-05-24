
#!powershell
# This file is part of Ansible
#
# Copyright 2016, Daniele Lazzari <lazzari@mailup.com>
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON

# win_docker_setup (Install, uninstall, update docker)

$params = Parse-Args $args -supports_check_mode $false

$state = Get-AnsibleParam -obj $params "state" -type "str" -default "present" -validateset "present", "absent", "update"
$version = Get-AnsibleParam -obj $params "version" -type "str"
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -default $false
$result = @{"changed" = $false
            "output" = ""
            "restart_needed" = $false}

$docker_service = Get-WmiObject win32_Service -Filter "Name = 'docker'"
$docker_dir = Join-Path $env:ProgramFiles -ChildPath "Docker"
$provider_file_url = "https://go.microsoft.com/fwlink/?LinkID=825636&clcid=0x409"
$docker_index_path = Join-Path -Path $env:TEMP -ChildPath "DockerMsftIndex.json"
$docker_archive = Join-Path -Path $env:TEMP -ChildPath "docker.zip"

Function Invoke-DockerSetup {
    Param (
        $docker_version
    )
    if (!($check_mode)) {
        # Download Docker 
        Invoke-WebRequest -UseBasicParsing -uri $docker_version.url -OutFile $docker_archive -ErrorAction Stop
        # Unarchive docker zip
        Expand-Archive -Path $docker_archive -DestinationPath $env:ProgramFiles -ErrorAction Stop
        # For persistent use after a reboot add docker path to enviroement var
        $existing_machine_path = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
        [Environment]::SetEnvironmentVariable("Path", $existing_machine_path + ";$docker_dir", [EnvironmentVariableTarget]::Machine)
        # Create docker service
        & $docker_dir/dockerd --register-service   
    }
}

Function Install-Docker {
    param(
        [string]$version
    )
    if (!($docker_service)) {
        try {
            # Install container windows feature if not installed
            $container_feature = Get-WindowsFeature -Name Containers
            if (!($container_feature.Installed)) {
                try {
                    Install-WindowsFeature Containers -WhatIf:$check_mode
                    $result.changed = $true
                    $result["container_feature"] = "installed"
                    $result.restart_needed = $true
                }
                catch {
                    $message = $_.Exception.Message
                    Fail-Json $result $message
                }
            }
            
            # Download MSFT file
            if (!($check_mode)) {
                Invoke-WebRequest -UseBasicParsing -Uri $provider_file_url -OutFile $docker_index_path  -ErrorAction Stop
            }

            if (Test-Path $docker_index_path) {
                # Parse DockerMsftFile to determine docker version
                $file = Get-Content $docker_index_path|ConvertFrom-Json -ErrorAction Stop
                if (!($version)) {
                    # Get Latest version info from file if $version is not provided
                    $latest = $file.channels.cs.alias
                    $to_install = $file.channels.$latest.version
                }
                else {
                    if ($file.versions -match $version) {
                        $to_install = $version
                    }
                    else {
                        $to_install = $file.channels.$version.version
                    }
                }

                $docker_version = $file.versions.$to_install
            }
            
            Invoke-DockerSetup -docker_version $docker_version
            
            $result.changed = $true
            $result.output = "Docker installed."
            $result["docker_version"] = $to_install
            $result.restart_needed = $true
            
        }
        catch {
            $message = $_.Exception.Message
            Fail-Json $result $message
        }
    }
    else {
        $result.output = "Docker is already present."
    }
}

Function Remove-Docker {
    if ($docker_service) {
        try {
            if (!($check_mode)) {
                if ($docker_service.State -eq "Running") {
                    $docker_service.Stop()
                }
                #Delete docker service
                $docker_service.Delete()

                # Remove all docker folders
                Remove-Item -Path $docker_dir -Recurse -Force
                if (Test-Path (Join-Path -Path $env:ProgramData -ChildPath 'Docker')) {
                    Remove-Item -Path $(Join-Path -Path $env:ProgramData -ChildPath 'Docker') -Recurse -Force
                }
            
                # Remove docker path from evn var path 
                $existing_machine_path = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
                $existing_machine_path.split(';')|ForEach-Object {if (($_ -notmatch "c:\\Program Files\\Docker")) {$new_machine_path += "$_;"}}
                [Environment]::SetEnvironmentVariable("Path", $new_machine_path, [EnvironmentVariableTarget]::Machine)
            }
            $result.changed = $true
            $result.output = "Docker removed."
        }
        catch {
            $message = $_.Exception.Message
            Fail-Json $result $message
        }
    }
}

Function Update-Docker {
    if ($docker_service) {
        # check installed version
        $installed_version = $(docker --version).split(',')[0].Trim().split(" ")[2]

        Invoke-WebRequest -UseBasicParsing -Uri $provider_file_url -OutFile $docker_index_path  
        $file = Get-Content $docker_index_path|ConvertFrom-Json
        $cs = $file.channels.cs.alias
        $latest_available = $file.channels.$cs.version

        if ($installed_version -match $latest_available) {
            $result.output = "Docker doesn't need to be updated."
        }
        else {
            $docker_version = $file.versions.$latest_available
            try {
                Remove-Docker
                Invoke-DockerSetup -docker_version $docker_version
                $result.changed = $true
                $result["docker_version"] = $latest_available
                $result.output = "Docker updated to $($latest_available) version."
            }
            catch {
                $message = $_.Exception.Message
                Fail-Json $reslut $message
            } 
        }
    }
    else {
        $result.output = "Docker is not installed, can't update."
    }
}

$win_version = [System.Environment]::OSVersion.Version

if (($PSVersionTable.PSVersion.Major -ge 5) -and ($win_version.Major -ge 10)) {
    if ($state -eq 'present') {
        Install-Docker -version $version
    }
    elseif ($state -eq 'update') {
        Update-Docker
    }
    else {
        Remove-Docker
    }
}
else {
    Fail-Json $result "Powershell 5.0 and Windows Server 2012 are needed"
}

# Cleanup
if (Test-Path $docker_archive) {
    Remove-Item -Path $docker_archive -Force
}
if (Test-Path $docker_index_path) {
    Remove-Item -Path $docker_index_path -Force
}

Exit-Json $result