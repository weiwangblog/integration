*** Settings ***
Documentation     Test Suite for vpn instance
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           ../../libraries/RequestsLibrary.py
Variables         ../../variables/Variables.py
Variables         ../../variables/vpnservice/Variables.py
Library           Collections

*** Variables ***
${REST_CON}       /restconf/config/
@{vpn_inst_values}    testVpn1    1000:1    1000:1,2000:1    3000:1,4000:1
@{vm_int_values}    s1-eth1    l2vlan    openflow:1:1
@{vm_vpnint_values}    s1-eth1    testVpn1    10.0.0.1    12:f8:57:a8:b9:a1

*** Test Cases ***
Create VPN Instance
    [Documentation]    Creates VPN Instance through restconf
    [Tags]    Post
    ${resp}    Post Json    session    ${REST_CON}l3vpn:vpn-instances/    data=${vpn_instance}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Verify VPN instance
    [Documentation]    Verifies the vpn instance is created
    [Tags]    Get
    ${resp}    RequestsLibrary.get    session    ${REST_CON}l3vpn:vpn-instances/vpn-instance/${vpn_inst_values[0]}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    : FOR    ${value}    IN    @{vpn_inst_values}
    \    Should Contain    ${resp.content}    ${value}

Create ietf vm interface
    [Documentation]    Creates ietf interface through the restconf
    [Tags]    Post
    ${resp}    Post Json    session    ${REST_CON}ietf-interfaces:interfaces/    data=${vm_interface}
    Should Be Equal As Strings    ${resp.status_code}    204

Verify ietf vm interface
    [Documentation]    Verifies ietf interface created
    [Tags]    Get
    ${resp}    RequestsLibrary.get    session    ${REST_CON}ietf-interfaces:interfaces/interface/${vm_int_values[0]}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    : FOR    ${value}    IN    @{vm_int_values}
    \    Should Contain    ${resp.content}    ${value}

Create VPN interface
    [Documentation]    Creates vpn interface for the corresponding ietf interface
    [Tags]    Post
    ${resp}    Post Json    session    ${REST_CON}l3vpn:vpn-interfaces/    data=${vm_vpninterface}
    Should Be Equal As Strings    ${resp.status_code}    204

Verify VPN interface
    [Documentation]    Verifies the vpn interface created
    [Tags]    Get
    ${resp}    RequestsLibrary.get    session    ${REST_CON}l3vpn:vpn-interfaces/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    : FOR    ${value}    IN    @{vm_vpnint_values}
    \    Should Contain    ${resp.content}    ${value}

Verify FIB entry after create
    [Documentation]    Verifies the fib entry for the corresponding vpn interface
    [Tags]    Get
    Wait Until Keyword Succeeds    10s    2s    Ensure The Fib Entry Is Present    vrfTables/${vpn_inst_values[1]}/vrfEntry/${vm_vpnint_values[2]}/    ${vm_vpnint_values[2]}

Delete vm vpn interface
    [Documentation]    Deletes the vpn interface
    [Tags]    Delete
    ${resp}    RequestsLibrary.Delete    session    ${REST_CON}l3vpn:vpn-interfaces/
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleteing vm vpn interface
    [Documentation]    Verifies vpn interface after delete
    [Tags]    Verify after delete
    ${resp}    RequestsLibrary.get    session    ${REST_CON}l3vpn:vpn-interfaces/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete VPN Instance
    [Documentation]    Deletes the VPN Instance
    [Tags]    Delete
    ${resp}    RequestsLibrary.Delete    session    ${REST_CON}l3vpn:vpn-instances/vpn-instance/${vpn_inst_values[0]}/
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleting the vpn instance
    [Documentation]    Verifies after deleting the vpn instance
    [Tags]    Verfiy after delete
    ${resp}    RequestsLibrary.get    session    ${REST_CON}l3vpn:vpn-instances/vpn-instance/${vpn_inst_values[0]}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete vm ietf interface
    [Documentation]    Deletes the ietf interface
    [Tags]    Delete
    ${resp}    RequestsLibrary.Delete    session    ${REST_CON}ietf-interfaces:interfaces/interface/${vm_int_values[0]}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleting vm ietf interface
    [Documentation]    Verifies ietf interface after delete
    [Tags]    Verify after delete
    ${resp}    RequestsLibrary.get    session    ${REST_CON}ietf-interfaces:interfaces/interface/${vm_int_values[0]}    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    404

Verify FIB entry after delete
    [Documentation]    Verifies the fib entry is deleted for the corresponding vpn interface
    [Tags]    Get
    Wait Until Keyword Succeeds    10s    2s    Ensure The Fib Entry Is Removed    vrfTables/${vpn_inst_values[1]}/vrfEntry/${vm_vpnint_values[2]}/

*** Keywords ***
Ensure The Fib Entry Is Present
    [Arguments]    ${uri_part}    ${prefix}
    [Documentation]    Will succeed if the fib entry is present for the vpn
    ${resp}    RequestsLibrary.get    session    ${REST_CON}odl-fib:fibEntries/${uri_part}    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${prefix}
    Should Contain    ${resp.content}    label

Ensure the Fib Entry Is Removed
    [Arguments]    ${uri_part}
    [Documentation]    Will succeed if the fib entry is removed for the vpn
    ${resp}    RequestsLibrary.get    session    ${REST_CON}odl-fib:fibEntries/${uri_part}    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    404
