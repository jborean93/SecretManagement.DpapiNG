using LiteDB;
using System.Management.Automation;

namespace SecretManagement.DpapiNG.Module;

[Cmdlet(VerbsDiagnostic.Test, "SecretVault")]
public sealed class TestSecretVaultCommand : DpapiNGSecretBase
{
    protected override bool ReadOnly => true;

    [Parameter]
    public string VaultName { get; set; } = "";

    internal override void ProcessVault(ILiteCollection<Secret> secrets)
    {
        // Checks are done in the base cmdlet.
        WriteObject(true);
    }
}
