Param (
    [CmdletBinding()]
    [Parameter( Mandatory = $true )]
    [string]$Softwarename,
    [switch]$FindSilentArgs,
    [ValidateRange( 1,50 )]
    [uint16]$LimitResults = 10
)

function Get-FilesInRepository {
    Param (
        [string]$URL,
        [string]$ChocoPackageName
    )

    switch -Regex ($URL) {
        '^(https:\/\/)?(www\.)?github' {
            # GITHUB LINK
            $APIURL          = $URL -replace '^(https:\/\/)?(www\.)?github\..+?(\/)'
            $APIURL          = [regex]::Match($APIURL, ".*?(\/).*?(\/|$)").Value -replace "\/$" # This will remove excess like "tree/master/blob/whatever" from the URL
            $APIURL          = "https://api.github.com/repos/$APIURL"
            $repositoryInfo  = Invoke-RestMethod $APIURL
            $masterBranchSha = (Invoke-RestMethod "$APIURL/git/trees/$($repositoryInfo.default_branch)").sha
            $masterTreeSha   = (Invoke-RestMethod "$APIURL/git/commits/$masterBranchSha").tree.sha
            $treeContents    = Invoke-RestMethod "$APIURL/git/trees/$masterTreeSha`?recursive=1"
            if ($treeContents.truncated -eq 'true') {
                Write-Verbose "GitHub API did not return all files and we're not handling this yet. Results are incomplete."
            }
            $files = @($treeContents.tree.Where{ $_.type -eq 'blob' }.path)
            if ($files.Count -gt 10) {
                Write-Verbose -Message "More than 10 items found in '$URL', this repository might be a collection of packages."
                # When we suspect that this could be an aggregation-repository with many softwares in it, we search to see if
                # there is a folder with the exact package-name. If there is, it probably was an aggregation-repository and we
                # will only consider the files within that folder-with-the-exact-packagename
                if ($files -match "(\/)?$ChocoPackageName\/") {
                    $files = $files.Where{ $_ -match "(\/)?$ChocoPackageName\/" }
                }
            }

            foreach ($file in $files) {
                $link = "https://raw.githubusercontent.com/{0}/{1}/{2}" -f $repositoryInfo.full_name, $repositoryInfo.default_branch, $file
                Write-Verbose "Getting GitHub file '$link' ..."
                ((Invoke-WebRequest -Uri $link).Content -split "`n").Trim()
            }
        }
        '^(https:\/\/)?(www\.)?gitlab' {
            # GITLAB LINK
            $APIURL         = 'gitlab.com/api/v4/projects/' + [System.Web.HttpUtility]::UrlEncode($URL -replace "^(https:\/\/)?(www\.)?gitlab\..+?(\/)")
            $repositoryInfo = Invoke-RestMethod -Uri $APIURL
            $projectID      = $repositoryInfo.id

            $files = (Invoke-RestMethod -Uri "https://gitlab.com/api/v4/projects/$projectID/repository/tree?per_page=100&recursive=true").Where{ $_.type -eq 'blob' }

            if ($files.Count -gt 10) {
                Write-Verbose -Message "More than 10 items found in '$URL', this repository might be a collection of packages."
                # When we suspect that this could be an aggregation-repository with many softwares in it, we search to see if
                # there is a folder with the exact package-name. If there is, it probably was an aggregation-repository and we
                # will only consider the files within that folder-with-the-exact-packagename
                if ($files.path -match "(\/)?$ChocoPackageName\/") {
                    $files = $files.Where{ $_.path -match "(\/)?$ChocoPackageName\/" }
                }
            }

            foreach ($item in $files) {
                $link = "gitlab.com/api/v4/projects/{0}/repository/blobs/{1}/raw" -f $projectID, $item.id
                Write-Verbose "Getting GitLab file '$($item.name)' ..."
                ((Invoke-WebRequest -Uri $link) -split "`n").Trim()
            }
        }
        default {
            Write-Warning -Message "The chocolatey package '$ChocoPackageName' is hosted on an unsupported provider:`n$URL`nCurrently, only GitLab and GitHub-hosted packaged are supported."
        }
    }
}

# Search chocolatey for software:
$uri = "chocolatey.org/api/v2/Search()?`$filter=IsLatestVersion&`$skip=0&`$top=$LimitResults&searchTerm='$softwarename'&targetFramework=''&includePrerelease=false"
$results = @(Invoke-RestMethod -Uri $uri -Method Get)

Write-Host "$($results.Count) results found for '$softwarename'."

foreach ($result in $results) {
    if ($findSilentArgs -and $result.properties.PackageSourceUrl) {
        Write-Verbose "Package Source URL: $($result.properties.PackageSourceUrl)"
        $fileContents = Get-FilesInRepository -URL $result.properties.PackageSourceUrl -ChocoPackageName $result.title.'#text'
        $silentArgs = $fileContents -match "silentArgs"
    } else {
        $silentArgs = @()
    }

    [PSCustomObject]@{
        Name    = $result.properties.Title
        Version = $result.properties.Version
        Author  = $result.author.name
        ChocolateyPackageName = $result.title.'#text'
        SilentArgs = $silentArgs
    }
}