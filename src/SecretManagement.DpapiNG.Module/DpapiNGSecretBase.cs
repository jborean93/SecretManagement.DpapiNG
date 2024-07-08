using LiteDB;
using Microsoft.PowerShell.Commands;
using Microsoft.PowerShell.SecretManagement;
using System;
using System.Collections;
using System.IO;
using System.Management.Automation;

namespace SecretManagement.DpapiNG.Module;

public abstract class DpapiNGSecretBase : PSCmdlet
{
    protected virtual bool ReadOnly => false;

    [Parameter]
    public Hashtable AdditionalParameters { get; set; } = new();

    protected override void ProcessRecord()
    {
        string vaultPath;
        if (
            AdditionalParameters.ContainsKey("Path") &&
            AdditionalParameters["Path"] is string tempVaultPath &&
            !string.IsNullOrWhiteSpace(tempVaultPath)
        )
        {
            vaultPath = tempVaultPath;
        }
        else
        {
            string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string secretManagementDir = Path.Combine(localAppData, "SecretManagement.DpapiNG");
            if (!Directory.Exists(secretManagementDir))
            {
                Directory.CreateDirectory(secretManagementDir);
            }

            vaultPath = Path.Combine(secretManagementDir, "default.vault");
        }

        string providerPath = SessionState.Path.GetUnresolvedProviderPathFromPSPath(
            vaultPath,
            out var provider,
            out var _);
        if (provider.ImplementingType != typeof(FileSystemProvider))
        {
            string msg =
                $"Invalid SecretManagement.DpapiNG vault registration: Path '{vaultPath}' must be a local file path " +
                "to the local LiteDB database. If the DB does not exist at the path a new vault will be created.";
            ErrorRecord err = new(
                new ArgumentException(msg),
                "SecretManagement.DpapiNG.InvalidPath",
                ErrorCategory.InvalidArgument,
                vaultPath
            );
            WriteError(err);
            return;
        }

        FileAttributes dbAttr = new FileInfo(providerPath).Attributes;
        bool dbExists = (int)dbAttr != -1;
        if (!dbExists && !Directory.Exists(Path.GetDirectoryName(providerPath)))
        {
            string msg =
                $"Invalid SecretManagement.DpapiNG vault registration: Path '{vaultPath}' must exist or the parent " +
                "directory in the path must exist to create the new vault file.";
            ErrorRecord err = new(
                new ArgumentException(msg),
                "SecretManagement.DpapiNG.PathMissingNoParent",
                ErrorCategory.InvalidArgument,
                vaultPath
            );
            WriteError(err);
            return;
        }
        else if (dbExists && (dbAttr & FileAttributes.Directory) != 0)
        {
            string msg =
                $"Invalid SecretManagement.DpapiNG vault registration: Path '{vaultPath}' must be the path to a " +
                "file not a directory.";
            ErrorRecord err = new(
                new ArgumentException(msg),
                "SecretManagement.DpapiNG.PathIsDirectory",
                ErrorCategory.InvalidArgument,
                vaultPath
            );
            WriteError(err);
            return;
        }

        ConnectionString connString = new()
        {
            Filename = providerPath,
            // Allows concurrent connections
            Connection = ConnectionType.Shared,
            ReadOnly = ReadOnly && dbExists,
        };
        using LiteDatabase db = new(connString);
        ILiteCollection<Secret> secrets = db.GetCollection<Secret>("secrets");
        ProcessVault(secrets);
    }

    internal abstract void ProcessVault(ILiteCollection<Secret> secrets);
}

internal class Secret
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public byte[] Value { get; set; } = Array.Empty<byte>();
    public SecretType SecretType { get; set; } = SecretType.Unknown;
    public string Metadata { get; set; } = "";
}
