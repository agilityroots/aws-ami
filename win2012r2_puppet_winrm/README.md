# Windows 2012 R2 AWS AMI

This Vagrantfile creates an AWS instance and configures it with WinRM. This is useful as a base AMI to be used with (for example) Puppet.

## Notes:

| Foo | Bar |
|---|---|
| OS | Windows 2012 R2 (x64) |
| Base AMI | `ami-93acd5fc` |
| AWS Details | Look at [`Vagrantfile.setup`](Vagrantfile.setup)
| Provisioner Installed | Puppet 5.0 |
| Other Tools | Curl, .Net 4.0 |

### Windows Update

Windows Update is also run, using [this Powershell toolkit](https://social.technet.microsoft.com/wiki/contents/articles/32424.biztalk-server-installation-powershell-toolkit.aspx).

**Note:** If you are provisioning this AMI from scratch, this step usually takes time if there are many updates. The update auto-restarts the VM.

### WinRM Configuration

| Item | Details |
|---|---|
| Connection Type | `WinRM` |
| Authentication | HTTP Basic Only |
| Port | 5985|
