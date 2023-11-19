using System.Runtime.InteropServices;

namespace SecretManagement.DpapiNG.NCrypt;

public static partial class Methods
{
    public const int NCRYPT_NAMED_DESCRIPTOR_FLAG = 0x00000001;
    public const int NCRYPT_MACHINE_KEY_FLAG = 0x00000020;

    [DllImport("NCrypt.dll", CharSet = CharSet.Unicode)]
    public static extern int NCryptCreateProtectionDescriptor(
        [MarshalAs(UnmanagedType.LPWStr)] string pwszDescriptorString,
        int dwFlags,
        out nint phDescriptor
    );
}
