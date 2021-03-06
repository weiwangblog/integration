*** Settings ***
Documentation     Test suite for Connection Manager
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.txt

*** Variables ***
${OVSDB_PORT}     6644
${BRIDGE}         br01
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${MININET}:${OVSDB_PORT}
${FILE}           ${CURDIR}/../../../variables/ovsdb

*** Test Cases ***
Connect to OVSDB Node
    [Documentation]    Initiate the connection to OVSDB node from controller
    [Tags]    Southbound
    ${sample}    OperatingSystem.Get File    ${FILE}/connect.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${MININET}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Create a Bridge
    [Documentation]    This will create bridge on the specified OVSDB node.
    [Tags]    Southbound
    ${sample}    OperatingSystem.Get File    ${FILE}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6630    tcp:${CONTROLLER}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${MININET}
    ${sample3}    Replace String    ${sample2}    br01    ${BRIDGE}
    ${body}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Config Topology with Bridge
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Get    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ${BRIDGE}

Get Operational Topology with Bridge
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify the bridge is added to the data store
    [Tags]    Southbound
    @{list}    Create List    ${BRIDGE}
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Create Port and attach to a Bridge
    [Documentation]    This request will creates port/interface and attach it to the specific bridge
    [Tags]    Southbound
    ${body}    OperatingSystem.Get File    ${FILE}/create_port.json
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vxlanport/
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vxlanport/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Operational Topology with Port
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    [Tags]    Southbound
    @{list}    Create List    ${BRIDGE}    vxlanport
    Wait Until Keyword Succeeds    6s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Delete the Port
    [Documentation]    This request will delete the port node from the bridge node and data store.
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Delete    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vxlanport/
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of Port
    [Documentation]    This request will fetch the operational topology after the Port is deleted
    [Tags]    Southbound
    @{list}    Create List    vxlanport
    Wait Until Keyword Succeeds    6s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Delete the Bridge
    [Documentation]    This request will delete the bridge node from the config data store.
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Delete    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of Bridge
    [Documentation]    This request will fetch the operational topology after the Bridge is deleted
    [Tags]    Southbound
    @{list}    Create List    ${BRIDGE}    vxlanport
    Wait Until Keyword Succeeds    6s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Delete the OVSDB Node
    [Documentation]    This request will delete the OVSDB node
    [Tags]    Southbound
    ${resp}    RequestsLibrary.Delete    session    ${SOUTHBOUND_CONFIG_API}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Get Operational Topology after Deletion of OVSDB Node
    [Documentation]    This request will fetch the operational topology after the OVSDB node is deleted
    [Tags]    Southbound
    @{list}    Create List    ovsdb://${MININET}:${OVSDB_PORT}    ${BRIDGE}    vxlanport
    Wait Until Keyword Succeeds    6s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}
