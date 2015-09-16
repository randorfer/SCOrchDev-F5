#requires -Version 3 -Modules SCOrchDev-Exception, SCOrchDev-Networking, SCOrchDev-Utility
<#
.SYNOPSIS
    Sets the status and current connection count for a given F5 server node

.OUTPUTS
    Returns a custom object
    Properties
    AllNodesAvailable - boolean - True if all ServerNodes have a status of "Node address is available"
    ServerNodes       - arraylist
    Server      - string  - Server name
    IP          - string  - Server IP address
    Status      - string  - F5 server node "status" or error message
    Connections - integer - F5 server node "current connections"

.COMPONENT
    PSSnapin - iControlSnapIn (F5)

.PARAMETER Server
    Names of the servers to inquire about

.PARAMETER F5Name
    Name of the F5 to query

.PARAMETER F5Cred
    Cred with rights to administer the F5

#>
Function Set-F5ServerNode
{
    Param ( 
        [Parameter(Mandatory = $True)]
        [string[]]
        $Server,

        [Parameter(Mandatory = $True)]
        [ValidateSet(
                'Offline',
                'Disabled',
                'Enabled'
        )]
        [string]
        $State,
        
        [Parameter(Mandatory = $False)]
        [int]
        $TimeOut = 0,

        [Parameter(Mandatory = $False)]
        [int]
        $MaxDrainConnection = 0,

        [Parameter(Mandatory = $True)]
        [string]
        $F5Name,

        [Parameter(Mandatory = $True)]
        [pscredential]
        $F5Cred
    )

    Switch($State)
    {
        'Offline'
        {
            $MonitorState = 'STATE_DISABLED'
            $SessionEnabledState = 'STATE_DISABLED'
        }
        'Disabled'
        {
            $MonitorState = 'STATE_ENABLED'
            $SessionEnabledState = 'STATE_DISABLED'
        }
        'Enabled'
        {
            $MonitorState = 'STATE_ENABLED'
            $SessionEnabledState = 'STATE_ENABLED'
        }
        Default
        {
            Throw-Exception -Type 'InvalidServerState' `
                            -Message 'Invalid Server State Passed' `
                            -Property @{
                                'State' = $State
                                'ValidStates' = @('Offline', 'Disabled', 'Enabled')
                            }
        }
    }

    Write-Verbose -Message "`$MonitorState [$MonitorState]"
    Write-Verbose -Message "`$SessionEnabledState [$SessionEnabledState]"

    Write-Verbose -Message 'Adding F5 snapin and connecting.'
    if (-not (Get-PSSnapin -Name iControlSnapIn -ErrorAction SilentlyContinue)) 
    {
        Add-PSSnapin -Name iControlSnapIn
    }
    $UserName = $F5Cred.UserName.Split('\')[-1].ToLower()
    $Password = $F5Cred.GetNetworkCredential().SecurePassword
    $F5NormalizedCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($UserName, $Password)
    $Initialize = Initialize-F5.iControl -HostName $F5Name -Credentials $F5NormalizedCred
    $F5iControl = Get-F5.iControl

    $F5NodeControl = $F5iControl.LocalLBNodeAddress

    Foreach ($_Server in $Server)
    {
        $IPAddress = Get-IPAddressFromDNS -Target $_Server
        Write-Verbose -Message "Setting F5 server node to Monitor State [$MonitorState] Session Enabled State [$SessionEnabledState] for server [$_Server] IP [$IPAddress]"
        $F5NodeControl.Set_Monitor_State($IPAddress, $MonitorState)
        $F5NodeControl.Set_Session_Enabled_State($IPAddress, $SessionEnabledState)
    }

    If ($State -eq 'Offline')
    {
        $TimeoutTime = (Get-Date).AddSeconds($TimeOut)
        do
        {
            Write-Verbose -Message 'Querying F5 server node statistics'
            $StillConnected = $True
            ForEach ($_Server in $Server)
            {
                $IPAddress = Get-IPAddressFromDNS -Target $_Server
                $NodeStatistics = $F5NodeControl.Get_Statistics($IPAddress).Statistics
                $RawNodeConnections = $NodeStatistics.Statistics |
                Where-Object -Property Type -EQ -Value 'STATISTIC_SERVER_SIDE_CURRENT_CONNECTIONS' |
                Select-Object -First 1
                
                $StillConnected = $RawNodeConnections.Value.Low -gt $MaxDrainConnection
                if($StillConnected) 
                { 
                    Write-Verbose -Message "[$_Server] still has [$($RawNodeConnections.Value.Low)] Connection(s)"
                    break 
                }
            }
            Start-Sleep -Seconds 10
        }
        While ($StillConnected -and ((Get-Date) -lt $TimeoutTime))
    }
}


<#
.SYNOPSIS
    Get the status and current connection count for a given F5 server node

.OUTPUTS
    Returns a custom object
    Properties
    AllNodesAvailable - boolean - True if all ServerNodes have a status of "Node address is available"
    ServerNodes       - arraylist
    Server      - string  - Server name
    IP          - string  - Server IP address
    Status      - string  - F5 server node "status" or error message
    Connections - integer - F5 server node "current connections"

.COMPONENT
    PSSnapin - iControlSnapIn (F5)

.PARAMETER Server
    Names of the servers to inquire about

.PARAMETER F5Name
    Name of the F5 to query

.PARAMETER F5Cred
    Cred with rights to administer the F5

#>
Function Get-F5ServerNodeStatus
{
    Param ( 
        [Parameter(Mandatory=$True)]
        [string[]]
        $Server,
        
        [Parameter(Mandatory=$True)]
        [string]
        $F5Name,
        
        [Parameter(Mandatory=$True)]
        [pscredential]
        $F5Cred
    )

    #  Connect to F5
    Write-Verbose -Message 'Adding F5 snapin and connecting.'
    if (-not (Get-PSSnapin -Name iControlSnapIn -ErrorAction SilentlyContinue)) 
    {
        Add-PSSnapin -Name iControlSnapIn
    }
    $UserName = $F5Cred.UserName.Split('\')[-1].ToLower()
    $Password = $F5Cred.GetNetworkCredential().SecurePassword
    $F5NormalizedCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($UserName, $Password)
    $Initialize = Initialize-F5.iControl -HostName $F5Name -Credentials $F5NormalizedCred
    $F5iControl = Get-F5.iControl

    $ServerNodes = New-Object -TypeName System.Collections.ArrayList
    $AllNodesAvailable = $True
    Write-Verbose -Message "`$AllNodesAvailable (default value) [$AllNodesAvailable]"

    ForEach ($_Server in $Server)
    {
        $IPAddress = Get-IPAddressFromDNS -Target $_Server
        Write-Verbose -Message "`$Server [$Server] `$ServerIP [$IPAddress]"

        If(-not (Test-IsNullOrEmpty -String $IPAddress))
        {
            try
            {
                #  Get current node connection count
                Write-Verbose -Message 'Querying F5 node statistics'
                $NodeStatistics = $F5iControl.LocalLBNodeAddress.Get_Statistics($IPAddress).Statistics
                $RawCurrentConnections = $NodeStatistics.Statistics |
                    Where-Object -Property Type -EQ -Value 'STATISTIC_SERVER_SIDE_CURRENT_CONNECTIONS' |
                        Select-Object -First 1
                $Connections = $RawCurrentConnections.Value.Low
                Write-Verbose -Message "`$Connections [$Connections]"

                #  Get current node status
                $RawNodeStatus = $F5iControl.LocalLBNodeAddress.Get_Object_Status($IPAddress)

                $Status = $RawNodeStatus.Status_Description.ToString()
                Write-Verbose -Message "`$Status [$Status]"
            }
                
            #  If the F5 throws any errors
            #    Fail the install
            catch
            {
                $Status      = 'Unable to retrieve F5 node status'
                $Connections = 0
                Write-Verbose -Message "`$Status [$Status]"
                Write-Verbose -Message "`$Connections [$Connections]"
            }
        }
        Else
        {
            $Status      = 'Unable to resolve DNS address'
            $Connections = 0
            Write-Verbose -Message "`$Status [$Status]"
            Write-Verbose -Message "`$Connections [$Connections]"
        }

        #  Define server result object
        $ServerNode = @{ 
            'Server' = $Server ; 
            'IP' = $IPAddress ;
            'Status' = $Status ;
            'Connections' = $Connections
        }

        $ServerNodes += $ServerNode
        Write-Verbose -Message "`$ServerNodes.Count [$($ServerNodes.Count)]"

        If ( $ServerNode.Status -ne 'Node address is available' )
        {
            $AllNodesAvailable = $False
        }
        Write-Verbose -Message "`$AllNodesAvailable [$AllNodesAvailable]"
    }

    #  Define complete result object
    $F5Status = @{
        'AllNodesAvailable' = $AllNodesAvailable ;
        'ServerNodes' = $ServerNodes
    }
    return $F5Status
}
