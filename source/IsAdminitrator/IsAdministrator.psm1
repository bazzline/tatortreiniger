# @see:
#   https://devblogs.microsoft.com/powershell-community/is-a-user-a-local-administrator/

Function Is-Administrator-Windows ()
{
    $currentUser = whoami.exe
    $membersOfGroupAdministrators = Get-LocalGroupMember -Name Administrators | 
       Select-Object -ExpandProperty name
    
    $isAdministrator = ($membersOfGroupAdministrators -Contains $currentUser)

    return $isAdministrator
}
