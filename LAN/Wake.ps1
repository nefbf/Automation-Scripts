#######################################################
##
## Wake.ps1, v1.0, 2013
##
## Forked from by Ammaar Limbada (see: https://gist.github.com/alimbada/4949168)
## Original Author: Matthijs ten Seldam, Microsoft (see: https://learn.microsoft.com/en-us/archive/blogs/matthts/wakeup-machines-a-powershell-script-for-wake-on-lan)
##
#######################################################
 
<#
.SYNOPSIS
Starts a list of physical machines by using Wake On LAN.
 
.DESCRIPTION
Wake sends a Wake On LAN magic packet to a given machine's MAC address.
 
.PARAMETER MacAddress
MacAddress of target machine to wake.
 
.EXAMPLE
Wake A0DEF169BE02
 
.INPUTS
None
 
.OUTPUTS
None
 
.NOTES
Make sure the MAC addresses supplied don't contain "-" or ".".
#>
 
 
param( [Parameter(Mandatory=$true, HelpMessage="MAC address of target machine to wake up")]
       [string] $MacAddress )
 
 
Set-StrictMode -Version Latest
 
function Send-Packet([string]$MacAddress)
{
    <#
    .SYNOPSIS
    Sends a number of magic packets using UDP broadcast.
 
    .DESCRIPTION
    Send-Packet sends a specified number of magic packets to a MAC address in order to wake up the machine.  
 
    .PARAMETER MacAddress
    The MAC address of the machine to wake up.
    #>
 
    try
    {
        # The following could potentially return an array - do your own error checking if needed.
        $IPAddress = Get-NetIPAddress -AddressFamily IPv4 -PrefixLength 24
        # Calculate directed broadcast address for subnet
        $Broadcast = [Net.IPAddress]::new(
            ((
                    [Net.IPAddress]::Parse( $IPAddress.IPAddress).Address `
                    -band [uint]::MaxValue `
                    -shr (32 - $IPAddress.PrefixLength)) `
                    -bor ([uint]::MaxValue `
                    -shl $IPAddress.PrefixLength)
            )).IPAddressToString

        $BroadcastAddress = [Net.IPAddress]::Parse($Broadcast)
 
        ## Create UDP client instance
        $UdpClient = New-Object Net.Sockets.UdpClient
 
        ## Create IP endpoints for each port
        $IPEndPoint = New-Object Net.IPEndPoint $BroadcastAddress, 9
 
        ## Construct physical address instance for the MAC address of the machine (string to byte array)
        $MAC = [Net.NetworkInformation.PhysicalAddress]::Parse($MacAddress.ToUpper())
 
        ## Construct the Magic Packet frame
        $Packet =  [Byte[]](,0xFF*6)+($MAC.GetAddressBytes()*16)
 
        ## Broadcast UDP packets to the IP endpoint of the machine
        $UdpClient.Send($Packet, $Packet.Length, $IPEndPoint) | Out-Null
        $UdpClient.Close()
    }
    catch
    {
        $UdpClient.Dispose()
        $Error | Write-Error;
    }
}
 
## Send magic packet to wake machine
Write-Output "Sending magic packet to $MacAddress"
Send-Packet $MacAddress
