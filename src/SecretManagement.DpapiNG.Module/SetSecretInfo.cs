using LiteDB;
using System;
using System.Collections;
using System.Management.Automation;

namespace SecretManagement.DpapiNG.Module;

[Cmdlet(VerbsCommon.Set, "SecretInfo")]
public sealed class SetSecretInfoCommand : DpapiNGSecretBase
{
    [Parameter]
    public string Name { get; set; } = "";

    [Parameter]
    public Hashtable Metadata { get; set; } = new();

    [Parameter]
    public string VaultName { get; set; } = "";

    internal override void ProcessVault(ILiteCollection<Secret> secrets)
    {
        Secret? existingSecret = secrets.FindOne(x => x.Name == Name);
        if (existingSecret == null)
        {
            string msg =
                $"Failed to find SecretManagement.DpapiNG vault secret '{Name}'. The secret must exist to set the " +
                "metadata on. Use Set-Secret to create a secret with metadata instead.";
            ErrorRecord err = new(
                new ArgumentException(msg),
                "SecretManagement.DpapiNG.SetSecretInfoNoSecret",
                ErrorCategory.InvalidArgument,
                Name
            );
            WriteError(err);
            return;
        }

        Hashtable existingMetadata = (Hashtable)PSSerializer.Deserialize(existingSecret.Metadata);
        bool changed = false;
        foreach (DictionaryEntry kvp in Metadata)
        {
            string key = kvp.Key.ToString() ?? "";
            object? value = kvp.Value;
            object? existingValue = null;
            if (existingMetadata.ContainsKey(key))
            {
                existingValue = existingMetadata[key];
            }

            if (key == "ProtectionDescriptor")
            {
                if (existingValue != value)
                {
                    string msg =
                        "It is not possible to change the ProtectionDescriptor for an existing set. Use " +
                        "Set-SecretInfo to create a new secret instead.";
                    ErrorRecord err = new(
                        new ArgumentException(msg),
                        "SecretManagement.DpapiNG.SetSecretInfoChangedDesc",
                        ErrorCategory.InvalidArgument,
                        value
                    );
                    WriteError(err);
                }
            }
            else if (existingValue == null || existingValue != value)
            {
                // The entry wasn't present or doesn't match the new value.
                existingMetadata[key] = value;
                changed = true;
            }
        }

        if (changed)
        {
            existingSecret.Metadata = PSSerializer.Serialize(existingMetadata);
            secrets.Update(existingSecret);
        }
    }
}
