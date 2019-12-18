function Get-LolMatchesBySummoner
{
    param (
        [parameter(mandatory=$true)]
        [string]$AccountId,

        [parameter(mandatory=$false)]
        [string]$Region="Europe West",

        [parameter(Mandatory = $false, ParameterSetName = "Hidden")]
        [hashtable]$Parameters,

        [parameter(Mandatory = $false, ParameterSetName = "Hidden")]
        [hashtable]$Config
    )
    
    switch($category) {
        'Europe West'{ $region = 'euw1' }
        'North America' { $region = 'na1' }
        'Japan' { $region = 'jp1' }
        default { $region = 'euw1' }
    }
    $header = @{"X-Riot-Token"=$config.APIKey}
    $matches = Invoke-RestMethod -Method Get -Uri ("https://$region.api.riotgames.com/lol/match/v4/matchlists/by-account/$AccountId" + "?endIndex=10&beginIndex=0") -Headers $header
    $champs = Invoke-RestMethod -Method Get -Uri "https://ddragon.leagueoflegends.com/cdn/9.23.1/data/en_US/champion.json"
    $champArray = $champs.data | gm -MemberType NoteProperty

    $matchDetails = @()
    foreach($match in $matches.matches) {
        $matchDetails += Invoke-RestMethod -Method Get -Uri ("https://$region.api.riotgames.com/lol/match/v4/matches/" + $match.gameId) -Headers $header   
    }

    $a = 0
    foreach($match in $matches.matches) {
        switch($match.queue) {
                "450" { $match.queue = "ARAM" }
                "440" { $match.queue = "RankedFlex" }
                "420" { $match.queue = "RankedSolo" }
                "400" { $match.queue = "UnrankedDraft" }
          }

        $epoch = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        $match.timestamp = $epoch.AddMilliseconds($match.timestamp)

        for($i = 0; $i -le $champArray.Count; $i++) {
                if ($champs.data.($champArray[$i].Name).key -eq $match.champion) {
                    $champName = $champs.data.($champArray[$i].Name).name
                    $match.champion = '<img src="https://ddragon.leagueoflegends.com/cdn/9.23.1/img/champion/' + $champs.data.($champArray[$i].Name).image.full + '" width="35px" title="' + $champName + '"/>'
                }
        }

        foreach ($part in $matchDetails[$a].participantIdentities) {
            if ($part.player.accountId -eq $AccountId) {
                $correctPartId = $part.participantId
            }
        }
        foreach($p in $matchDetails[$a].participants) {
            if ($p.participantId -eq $correctPartId) {
                $kills = $p.stats.kills
                $deaths = $p.stats.deaths
                $assists = $p.stats.assists
                $match | Add-Member -MemberType NoteProperty -Name "K/D/A" -Value "$($kills)/$($deaths)/$($assists)" -Force
                $correctTeam = $p.teamId
            }
        }
        foreach($team in $matchDetails[$a].teams) {
            if ($team.teamId -eq $correctTeam) {
                if ($team.win -eq "Win") {
                $winStatus = "<font color='green'>Win</font>"
                } else {
                $winStatus = "<font color='red'>Loss</font>"
                }
                $match | Add-Member -MemberType NoteProperty -Name "W/L" -Value $winStatus -Force
            }
        }
        $a++
    }

    New-PFHTMLTable -InputObject $matches.matches -Header @('Champion','Lane','K/D/A','W/L','Queue','Role','Season','TimeStamp')
}
