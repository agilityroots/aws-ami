# https://docs.docker.com/engine/installation/windows/docker-ee/#install-docker-ee

invoke-webrequest -UseBasicparsing -Outfile docker.zip https://download.docker.com/components/engine/windows-server/17.03/docker-17.03.0-ee.zip
# Extract the archive.
Expand-Archive docker.zip -DestinationPath $Env:ProgramFiles

# Clean up the zip file.
Remove-Item -Force docker.zip

# Install Docker. This will require rebooting.
$null = Install-WindowsFeature containers

# Add Docker to the path for the current session.
$env:path += "$env:ProgramFiles\docker"

# Optionally, modify PATH to persist across sessions.
$newPath = "$env:ProgramFiles\docker;" +
[Environment]::GetEnvironmentVariable("PATH",
[EnvironmentVariableTarget]::Machine)

[Environment]::SetEnvironmentVariable("PATH", $newPath,
[EnvironmentVariableTarget]::Machine)

# Register the Docker daemon as a service.
dockerd --register-service

# Start the daemon.
Start-Service docker
