# Changelog for SecretManagement.DpapiNG

## v0.4.0 - TBD

+ Bump `LiteDB` version to `5.0.21`
+ Support concurrent operations on the same vault file using LiteDB's shared concurrency model

## v0.3.0 - 2023-11-22

+ Add support for `-WebCredential` when specifying a DPAPI-NG protection descriptor

## v0.2.0 - 2023-11-21

+ Use a default vault path when registering a vault without a path
  + The path will be `$env:LOCALAPPDATA\SecretManagement.DpapiNG\default.vault`
+ Add support for `-Certificate` and `-CertificateThumbprint` when specifying a DPAPI-NG protection descriptor

## v0.1.0 - 2023-11-21

+ Initial version of the `SecretManagement.DpapiNG` module
