$ErrorActionPreference = 'Stop'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter SDK is not installed or not on PATH.'
}
flutter create --platforms=android,ios,web,windows,macos,linux --org com.gensolar --project-name gensolar_pro_engineering .
if ($LASTEXITCODE -ne 0) { throw 'flutter create failed.' }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }
Write-Host 'GenSolar platform runner folders generated. Review flutter doctor before building native targets.'
