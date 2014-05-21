properties {
    $root =                          $psake.build_script_dir
    $nugetspec =                     "$root/Mindscape.Raygun4Net.nuspec"
    $signed_nugetspec =              "$root/Mindscape.Raygun4Net.signed.nuspec"
    $solution_file =                 "$root/Mindscape.Raygun4Net.sln"
    $solution_file2 =                "$root/Mindscape.Raygun4Net2.sln"
    $winrt_solution_file =           "$root/Mindscape.Raygun4Net.WinRT.sln"
    $configuration =                 "Sign"
    $build_dir =                     "$root\build\"
    $signed_build_dir =              "$build_dir\signed"
    $release_dir =                   "$root\release\"
    $nuget_dir =                     "$root\.nuget"
    $env:Path +=                     ";$nuget_dir"
}

task default -depends Zip

task Clean {
    remove-item -force -recurse $release_dir -ErrorAction SilentlyContinue | Out-Null
    remove-item -force -recurse $signed_build_dir -ErrorAction SilentlyContinue | Out-Null
}

task Init -depends Clean {
    new-item $release_dir -itemType directory | Out-Null
    new-item $signed_build_dir -itemType directory | Out-Null
}

task Compile -depends Init {
    exec { msbuild "$solution_file" /m /p:OutDir=$signed_build_dir /p:Configuration=$configuration }
    exec { msbuild "$solution_file2" /m /p:OutDir=$signed_build_dir /p:Configuration=$configuration }
}

task CompileWinRT -depends Init {
    exec { msbuild "$winrt_solution_file" /m /p:OutDir=$signed_build_dir /p:Configuration=$configuration }
    move-item $signed_build_dir/Mindscape.Raygun4Net.WinRT/Mindscape.Raygun4Net.WinRT.dll $signed_build_dir
    move-item $signed_build_dir/Mindscape.Raygun4Net.WinRT/Mindscape.Raygun4Net.WinRT.pdb $signed_build_dir
    move-item $signed_build_dir/Mindscape.Raygun4Net.WinRT.Tests/Mindscape.Raygun4Net.WinRT.Tests.dll $signed_build_dir
    move-item $signed_build_dir/Mindscape.Raygun4Net.WinRT.Tests/Mindscape.Raygun4Net.WinRT.Tests.pdb $signed_build_dir
    remove-item -force -recurse $signed_build_dir/Mindscape.Raygun4Net.WinRT -ErrorAction SilentlyContinue | Out-Null
    remove-item -force -recurse $signed_build_dir/Mindscape.Raygun4Net.WinRT.Tests -ErrorAction SilentlyContinue | Out-Null
}

task Package -depends Compile, CompileWinRT {
    exec { nuget pack $nugetspec -OutputDirectory $release_dir }
    exec { nuget pack $signed_nugetspec -OutputDirectory $release_dir }
}

task PushNugetPackage -depends Package {
    Push-Location -Path $release_dir

    exec { nuget push "$release_dir*.nupkg" }

    Pop-Location
}

task Zip -depends Package {
    $release = Get-ChildItem $release_dir | Select-Object -f 1
    $nupkg_name = $release.Name
    $nupkg_name = $nupkg_name -replace "Mindscape.Raygun4Net.", "v"
    $version = $nupkg_name -replace ".nupkg", ""
    
    $outerfolder = $release_dir + $version
    $versionfolder = $release_dir + $version + "\" + $version
    $signedfolder = $versionfolder + "\signed"
    new-item $versionfolder -itemType directory | Out-Null
    new-item $signedfolder -itemType directory | Out-Null
  
    copy-item $build_dir/Mindscape.Raygun4Net.dll $versionfolder
    copy-item $build_dir/Mindscape.Raygun4Net.pdb $versionfolder
    copy-item $build_dir/Mindscape.Raygun4Net.WindowsPhone.dll $versionfolder
    copy-item $build_dir/Mindscape.Raygun4Net.WindowsPhone.pdb $versionfolder
    copy-item $build_dir/Mindscape.Raygun4Net.WinRT.dll $versionfolder
    copy-item $build_dir/Mindscape.Raygun4Net.WinRT.pdb $versionfolder
    copy-item $build_dir/Mindscape.Raygun4Net.Xamarin.Android.dll $versionfolder
    copy-item $build_dir/Mindscape.Raygun4Net.Xamarin.Android.pdb $versionfolder
    copy-item $build_dir/Mindscape.Raygun4Net.Xamarin.iOS.dll $versionfolder
    copy-item $build_dir/Mindscape.Raygun4Net2.dll $versionfolder
    copy-item $build_dir/Mindscape.Raygun4Net2.pdb $versionfolder
    copy-item $signed_build_dir/Mindscape.Raygun4Net.dll $signedfolder
    copy-item $signed_build_dir/Mindscape.Raygun4Net.WinRT.dll $signedfolder
    copy-item $signed_build_dir/Mindscape.Raygun4Net2.dll $signedfolder
	
    $zipFullName = $release_dir + $version + ".zip"
    Get-ChildItem $outerfolder | Add-Zip $zipFullName
}

function Add-Zip # usage: Get-ChildItem $folder | Add-Zip $zipFullName
{
    param([string]$zipfilename)

    if(!(test-path($zipfilename)))
    {
        set-content $zipfilename ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
        (dir $zipfilename).IsReadOnly = $false
    }
    $shellApplication = new-object -com shell.application
    $zipPackage = $shellApplication.NameSpace($zipfilename)
    foreach($file in $input)
    { 
        $zipPackage.CopyHere($file.FullName)
        do {
            Start-sleep 2
        } until ( $zipPackage.Items() | select {$_.Name -eq $file.Name} )
    }
}