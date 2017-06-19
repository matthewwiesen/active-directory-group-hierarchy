$D = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$Domain = [ADSI]"LDAP://$D"

$ADGroupName = $args[0]
$ADGroupDN = ""

$corpView = @{}
$corpView.Add("root", @{})


Function getUsersFromGroup($groupDN){
    $Searcher = New-Object System.DirectoryServices.DirectorySearcher
    $Searcher.PageSize = 200
    $Searcher.SearchScope = "subtree"
    $Searcher.PropertiesToLoad.Add("distinguishedName") > $Null
    $Searcher.PropertiesToLoad.Add("sAMAccountName") > $Null
    $Searcher.PropertiesToLoad.Add("name") > $Null
    $Searcher.PropertiesToLoad.Add("department") > $Null
    $Searcher.PropertiesToLoad.Add("manager") > $Null
    $Searcher.PropertiesToLoad.Add("directReports") > $Null
    $Searcher.Filter = "(memberOf=$groupDN)"

    return $Searcher.FindAll()
}

Function getUser($userDN){
    $Searcher = New-Object System.DirectoryServices.DirectorySearcher
    $Searcher.PageSize = 200
    $Searcher.SearchScope = "subtree"
    $Searcher.PropertiesToLoad.Add("distinguishedName") > $Null
    $Searcher.PropertiesToLoad.Add("sAMAccountName") > $Null
    $Searcher.PropertiesToLoad.Add("name") > $Null
    $Searcher.PropertiesToLoad.Add("department") > $Null
    $Searcher.PropertiesToLoad.Add("manager") > $Null
    $Searcher.PropertiesToLoad.Add("directReports") > $Null
    $Searcher.Filter = "(sAMAccountName=*)"
    $Searcher.SearchRoot = "LDAP://$userDN"

    return $Searcher.FindAll()
}

Function searchGroup($groupName){
    $Searcher = New-Object System.DirectoryServices.DirectorySearcher
    $Searcher.PageSize = 200
    $Searcher.SearchScope = "subtree"
    $Searcher.PropertiesToLoad.Add("distinguishedName") > $Null
    $Searcher.Filter = "(cn=$groupName)"

    $Result = $Searcher.FindAll()

    Set-Variable -scope 1 -Name "ADGroupDN" -Value $Result.Properties["distinguishedname"]
}

Function printUserObject($user){
    Write-Host "distinguishedName = $($user.Properties["distinguishedName"])"
    Write-Host "sAMAccountName = $($user.Properties["sAMAccountName"])"
    Write-Host "name = $($user.Properties["name"])"
    Write-Host "department = $($user.Properties["department"])"
    Write-Host "manager = $($user.Properties["manager"])"
}

Function printUserString($user, $isADGroupUser, $offset){
    $name = $user.Properties["name"]
    $userId = $user.Properties["sAMAccountName"]
    $department = $user.Properties["department"]


    if($isADGroupUser -eq "true"){
        Write-Host "$offset$name ($userID) | $department ($($ADGroupName) User)"
    } else {
        Write-Host "$offset$name ($userID) | $department"
    }


}


Function addUserToCorpView($user, $isADGroupUser){
    if($corpView.ContainsKey("$($user.Properties['distinguishedName'])")){
        if($isADGroupUser -eq "true"){
            $corpView.Set_Item("$($user.Properties["distinguishedName"])", @{"user" = $user; "ADGroupUser" = $isADGroupUser})
        }
    } else {
        $corpView.Add("$($user.Properties["distinguishedName"])", @{"user" = $user; "ADGroupUser" = $isADGroupUser})
    }
}

Function buildCorpView($users){
    foreach ($user in $users){
        addUserToCorpView $user "true"

        $tmpUser = $user

        if($tmpUser.Properties["manager"] -ne $null){

            While($tmpUser.Properties["manager"] -ne $null){
                $offset += "    "
                $manager = getUser $($tmpUser.Properties["manager"])

                addUserToCorpView $manager "false"

                $tmpUser = $manager
            }

            $rootObj = $corpView.Get_Item("root")

            if($rootObj.ContainsKey("$($manager.Properties["distinguishedName"])")){
                # If the root object already contains the manager, then we don't have to do anything
            } else {
                $rootObj.Add("$($manager.Properties["distinguishedName"])", $manager)
                $corpView.Set_Item("root", $rootObj)
            }
        } else {
            Write-Host "This user does not have a manager"
            printUserObject $user
        }
    }
}

Function printCorpView(){
    $rootObj = $corpView.Get_Item("root")

    foreach($topLevelUser in $rootObj.Keys){
        recurseDown $topLevelUser ""
    }

}


Function recurseDown($userDN, $offset){
    if($corpView.ContainsKey($userDN)){
        $userObj = $corpView.Get_Item($userDN)

        printUserString $userObj.user $userObj.ADGroupUser $offset
        $offset += "    "

        foreach($directReport in $userObj.user.Properties["directReports"]){
            recurseDown $directReport $offset
        }
    }
}

Function GetHelp()
{
    "The script will generate an organization hierarchy based on on LDAP group"
    ""
    "Usage:"
    "  .\ad-group-hierarchy.ps1 <Group Name>"
    ""
    "Example:"
    "  .\ad-group-hierarchy.ps1 APREQ-GitLab-User"

}


$Abort = "false"

If ($args.Count -ne 1){
    "Error: Wrong number of parameters."
    GetHelp
    Break
} else {
    searchGroup $args[0]

    if($ADGroupDN -ne $null){
        $users = getUsersFromGroup $ADGroupDN

        buildCorpView $users

        printCorpView

        Write-Host "Total: $($users.count) users within group ($($ADGroupName))"
    } else {
        Write-Host "Could not find group within Active Directory"
    }
}
