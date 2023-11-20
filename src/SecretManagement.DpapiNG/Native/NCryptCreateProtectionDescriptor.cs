using System.ComponentModel;
using System.Runtime.InteropServices;

namespace SecretManagement.DpapiNG.Native;

public static partial class NCrypt
{
    public const int NCRYPT_NAMED_DESCRIPTOR_FLAG = 0x00000001;
    public const int NCRYPT_MACHINE_KEY_FLAG = 0x00000020;

    [DllImport("NCrypt.dll", CharSet = CharSet.Unicode)]
    private static extern int NCryptCreateProtectionDescriptor(
        [MarshalAs(UnmanagedType.LPWStr)] string pwszDescriptorString,
        int dwFlags,
        out SafeNCryptProtectionDescriptor phDescriptor
    );

    public static SafeNCryptProtectionDescriptor NCryptCreateProtectionDescriptor(
        string descriptorString,
        int flags
    )
    {
        int res = NCryptCreateProtectionDescriptor(descriptorString, flags, out var desc);
        if (res != 0)
        {
            throw new Win32Exception(res);
        }

        return desc;
    }
}
