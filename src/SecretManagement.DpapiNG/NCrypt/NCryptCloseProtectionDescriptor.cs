using System.Runtime.InteropServices;

namespace SecretManagement.DpapiNG.NCrypt;

public static partial class Methods
{
    [DllImport("NCrypt.dll")]
    public static extern int NCryptCloseProtectionDescriptor(
        nint hDescriptor
    );
}
