function Get-GitHubApiHeader {
    <#
    .SYNOPSIS
        Builds the request headers for a GitHub API call.
    .DESCRIPTION
        Returns a User-Agent header, plus an Authorization header when an access token is
        available. Authenticated requests get 5000 requests/hour instead of 60.

        API_GITHUB_ACCESS_TOKEN is preferred; GITHUB_TOKEN is the fallback, since it is
        provided automatically inside GitHub Actions.
    .EXAMPLE
        Invoke-RestMethod -Uri $apiUrl -Headers (Get-GitHubApiHeader)
    .OUTPUTS
        Hashtable of request headers.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $headers = @{ 'User-Agent' = 'PSFirebird' }

    [string]$githubAccessToken = $env:API_GITHUB_ACCESS_TOKEN
    if (-not $githubAccessToken) {
        $githubAccessToken = $env:GITHUB_TOKEN
    }

    if ($githubAccessToken) {
        Write-VerboseMark -Message '- Using authenticated GitHub API requests'
        $headers['Authorization'] = "Bearer $githubAccessToken"
    } else {
        Write-VerboseMark -Message '- Using unauthenticated GitHub API requests (60 req/hour limit)'
    }

    return $headers
}
