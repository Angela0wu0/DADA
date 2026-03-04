#ensures that only Administrators are allowed to run this script
#Requires -RunAsAdministrator

Import-Module ActiveDirectory

# extracting file and the contents
$source = "192.168.250.101:31337/user_list.txt"
$destination = "user_list.txt"
Invoke-WebRequest -Uri $source -OutFile $destination

$adminFilePath = 'admin_list.txt'
$filePath = "user_list.txt"

$fileContent = Get-Content -Path $filePath -Raw

# The password we have to give to all the users
$password = ConvertTo-SecureString "Secure!23" -AsPlainText -Force

# list of groups Administrators are in
$adminGroups = @("Administrators", "Domain Admins", "Domain Users", "Enterprise Admins", "Group Policy Creator Owners", "Schema Admins")

if(!($fileContent)){
    echo "failed to open file"
}

# parse file content and returns the strucuted user data
function parseUser{
    $users = $fileContent -split "`n" | Where-Object {$_ -match ','} | ForEach-Object {
        $userSection = $_ -split ','
        $fullName = $userSection[0].Trim()
        $userName = $userSection[1].Trim() 
        $description = $userSection[2].Trim()
    
        $nameSection = $fullName -split ' '
        
        # structure the user data into Fullname, Firstname, Lastname, username, and description  
        [PSCustomObject] @{
            FullName    = $fullName
            FirstName   = $nameSection[0]
            LastName    = $nameSection[1]
            Username    = $userName
            Description = $description
        }
    }

    return $users
}

# add the users into the list and added into Domain Users Group
function addUser{
    param(
        [PSCustomObject]$userList
    )

    foreach ($user in $userList){
        # create user
        New-ADUser -name $user.FullName -UserPrincipalName $user.Username -sAMAccountName $user.Username -DisplayName $user.FullName -Description $user.Description -AccountPassword $password -ChangePasswordAtLogon $false -CannotChangePassword $true
        
        # add to User & Domain group
        Add-AdGroupMember -Identity Users -Members $user.Username
        Add-AdGroupMember -Identity Domain Users -Members $user.Username
    }
}

# give admins on list the same group as Administrator
function elevatePrivialge{
    $parseAdminContent = switch -regex -File $adminFilePath{
        "Admin List"{
            $start = $true
            continue
        }
        {$start}
        {foreach ($admin in $_){
            foreach ($group in $adminGroups){
                Add-AdGroupMember -Identity $group -Members $admin
            }
        }}
    }
}


# start 
function main{
    $parsedUserList = parseUser
    addUser $parsedUserList
    elevatePrivialge
}

#initializer
main


