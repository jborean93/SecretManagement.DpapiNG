using System.Collections;
using System.Management.Automation;

namespace SecretManagement.DpapiNG.Module;

[Cmdlet(VerbsDiagnostic.Test, "SecretVault")]
public sealed class TestSecretVaultCommand : PSCmdlet
{
    [Parameter]
    public string VaultName { get; set; } = "";

    [Parameter]
    public Hashtable AdditionalParameters { get; set; } = new();

    protected override void ProcessRecord()
    {
    }
}
