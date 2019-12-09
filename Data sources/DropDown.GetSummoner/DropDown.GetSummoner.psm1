function Search($config, $search, $category)
{   
    switch($category) {
        'Europe West'{ $region = 'euw1' }
        'North America' { $region = 'na1' }
        'Japan' { $region = 'jp1' }
        default { $region = 'euw1' }
    }

    $res = Invoke-RestMethod -Method Get -Uri "https://$region.api.riotgames.com/lol/summoner/v4/summoners/by-name/$search" -Headers @{"X-Riot-Token"=$config.APIKey}
    
    $res | Select-Object @{
       Name="Id";
       Expression = {
           $_.accountId
       }
    },
    @{
        Name="Name";
        Expression = {
            $_.name
        }
    }
}

function Validate($config, $search) 
{
    return @()
}

function GetCategories($config) 
{
    return @('Europe West','North America')
}

function GetDefault($config)
{    
    
}
