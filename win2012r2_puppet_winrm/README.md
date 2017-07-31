# Windows 2012 R2 AWS AMI

This Vagrantfile creates an AWS instance and configures it with WinRM. This is useful as a base AMI to be used with (for example) Puppet.

## Notes:

| Foo | Bar |
|---|---|
| OS | Windows 2012 R2 (x64) |
| Base AMI | `ami-93acd5fc` |
| AWS Details | Look at [`Vagrantfile.setup`](Vagrantfile.setup)
| Provisioner Installed | Puppet 3.8.7 |
| Other Tools | Curl, .Net 4.0 |

## Prerequisites

The provisioner needs to be run from a Windows machine with Powershell.

### Environment Variables

For the AWS provisioning to work the following environment variables need to be set:

```
VAGRANT_AWS_KEYPAIR_NAME: AWS keypair to use for authentication e.g aws_keypair.pem
VAGRANT_AWS_KEY_PATH: Location of AWS keypair e.g /home/vish/.ssh/aws_keypair.pem
VAGRANT_AWS_ACCESS_KEY
VAGRANT_AWS_SECRET_KEY
VAGRANT_AWS_SECURITY_GROUP: AWS Security group name (see "Port Requirements" below)

```

### Port Requirements

The AWS Security group should have *at least* port 5985 open for WinRM to work.

### Windows Update

Windows Update is also run, using [this Powershell toolkit](https://social.technet.microsoft.com/wiki/contents/articles/32424.biztalk-server-installation-powershell-toolkit.aspx).

**Note:** If you are provisioning this AMI from scratch, this step usually takes time if there are many updates. The update does not auto-restart the VM.

### WinRM Configuration

| Item | Details |
|---|---|
| Connection Type | `WinRM` |
| Authentication | HTTP Basic Only |
| Port | 5985|

### Saving as an AMI (currently manual)

_The step to save the instance as an AMI is manual. TODO to be automated._

To save as AMI:

* Visit AWS Console where an instance `win2012r2_winrm_puppet` will be running.
* Right Click instance and choose option `Image` > `Create Image` and Save it as AMI.
