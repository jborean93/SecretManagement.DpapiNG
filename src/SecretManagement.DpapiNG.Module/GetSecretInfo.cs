using System.Collections;
using System.Management.Automation;

namespace SecretManagement.DpapiNG.Module;

[Cmdlet(VerbsCommon.Get, "SecretInfo")]
public sealed class GetSecretInfoCommand : PSCmdlet
{
    [Parameter]
    public string Filter { get; set; } = "";

    [Parameter]
    public string VaultName { get; set; } = "";

    [Parameter]
    public Hashtable AdditionalParameters { get; set; } = new();

    protected override void ProcessRecord()
    {
    }
}
