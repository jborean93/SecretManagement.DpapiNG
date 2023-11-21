# Changelog for SecretManagement.DpapiNG

## v0.2.0 - TBD

+ Use a default vault path when registering a vault without a path
  + The path will be `$env:LOCALAPPDATA\SecretManagement.DpapiNG\default.vault`
+ Add support for `-Certificate` and `-CertificateThumbprint` when specifying a DPAPI-NG protection descriptor

## v0.1.0 - 2023-11-21

+ Initial version of the `SecretManagement.DpapiNG` module
