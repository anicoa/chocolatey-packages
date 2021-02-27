import-module au

$ErrorActionPreference = 'STOP'

$domain   = 'https://github.com'
$releases = "${domain}/jruby/jruby/releases/latest"

$re32      = '(jruby_(?![^\s]+x64)[^\s]+\.exe)'
$re64      = '(jruby_(?=[^\s]+x64)[^\s]+\.exe)'
$reVersion = '(?<Version>([\d]+\.[\d]+\.[\d]+\.[\d]))'
function global:au_BeforeUpdate {
  Get-RemoteFiles -Purge -NoSuffix
}

function global:au_SearchReplace {
  @{
    "$($Latest.PackageName).nuspec" = @{
      "$($reVersion)" = "$($Latest.Version)"
    }

    ".\README.md" = @{
      "$($reVersion)" = "$($Latest.Version)"
    }

    ".\tools\chocolateyInstall.ps1" = @{
      "$($re32)" = "$($Latest.Filename32)"
      "$($re64)" = "$($Latest.Filename64)"
    }

    ".\tools\chocolateyUninstall.ps1" = @{
      "$($reVersion)" = "$($Latest.Version)"
    }

    ".\legal\VERIFICATION.txt" = @{
      "$($re32)"            = "$($Latest.Filename32)"
      "$($re64)"            = "$($Latest.Filename64)"
      "(Checksum32:\s)(.+)" = "`${1}$($Latest.Checksum32)"
      "(Checksum64:\s)(.+)" = "`${1}$($Latest.Checksum64)"
      "$($reVersion)"       = "$($Latest.Version)"
    }
  }
}

function global:au_GetLatest {
  $downloadPage = Invoke-WebRequest -Uri $releases -UseBasicParsing

  $url32      = $downloadPage.links | where-object href -match $re32 | select-object -expand  href | select-object -first 1 | foreach-object { $domain + $_ }
  $fileName32 = $url32 -split '/' | select-object -last 1
  $url64      = $downloadPage.links | where-object href -match $re64 | select-object -expand  href | select-object -first 1 | foreach-object { $domain + $_ }
  $fileName64 = $url64 -split '/' | select-object -last 1

  $version = $downloadPage.Content -match "JRuby\s$($reVersion)" | select-object -first 1 | foreach-object { $Matches.Version }

  return @{
    Url32      = $url32
    FileName32 = $fileName32
    Url64      = $url64
    FileName64 = $fileName64
    Version    = $version
  }
}

update -ChecksumFor none -NoReadme
