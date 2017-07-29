# Windows 2012 R2 AWS AMI

This Vagrantfile creates an AWS instance and configures it with WinRM for future provisioners like Puppet.

## Notes:

* OS: Windows 2012 R2 (x64)

Tools Installed
* Puppet 5.0
* Curl
* .Net Framework 4.0
* Windows Update is also run

WinRM Configuration
* Accepts HTTP connections (basic auth) on port 5985
