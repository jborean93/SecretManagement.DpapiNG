using System;
using System.Runtime.InteropServices;

namespace SecretManagement.DpapiNG.Native;

public static partial class NCrypt
{
    [DllImport("NCrypt.dll")]
    public static extern int NCryptCloseProtectionDescriptor(
        nint hDescriptor
    );
}

public sealed class SafeNCryptProtectionDescriptor : SafeHandle
{
    internal SafeNCryptProtectionDescriptor() : base(IntPtr.Zero, false)
    { }

    internal SafeNCryptProtectionDescriptor(nint handle) : base(handle, true)
    { }

    public override bool IsInvalid => handle == IntPtr.Zero;

    protected override bool ReleaseHandle()
    {
        return NCrypt.NCryptCloseProtectionDescriptor(handle) == 0;
    }
}
