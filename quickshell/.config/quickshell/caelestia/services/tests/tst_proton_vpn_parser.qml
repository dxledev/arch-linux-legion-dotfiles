import QtQuick
import QtTest
import "../ProtonVpnParser.js" as Parser

TestCase {
    function test_account() {
        verify(Parser.signedIn("Account: 'example'"));
        verify(!Parser.signedIn("Account: 'None'"));
        verify(!Parser.signedIn(""));
    }
    function test_connectedDetails() {
        const status = Parser.status("Updating server list…\n\x1b[32mStatus: Connected\x1b[0m\nServer: NL#42 in Amsterdam, Netherlands\nLoad: 21%\nProtocol: wireguard");
        verify(status.valid);
        verify(status.connected);
        compare(status.server, "NL#42");
        compare(status.location, "Amsterdam, Netherlands");
        compare(status.details.length, 2);
    }
    function test_countryTable() {
        const countries = Parser.countries("Country         Code\n--------------  ----\nUnited States   US\nNetherlands     NL\nUnited States   US\nJunk");
        compare(countries.length, 2);
        compare(countries[0].name, "United States");
        compare(countries[1].code, "NL");
    }
    function test_disconnectedAndMalformed() {
        const status = Parser.status("Status: Disconnected");
        verify(status.valid);
        verify(!status.connected);
        verify(!Parser.status("Unexpected failure").valid);
    }
    function test_escapedConnectionName() {
        const link = Parser.link("ProtonVPN US\\:Test#12:wireguard:proton0:activated");
        compare(link.server, "US:Test#12");
        compare(link.device, "proton0");
    }
    function test_planRestrictedConfig() {
        const config = Parser.config("Setting       Value\n------------  -----------------\nkill-switch   off\nnetshield     Upgrade to enable");
        compare(config["kill-switch"], "off");
        compare(config.netshield, "Upgrade to enable");
    }
    function test_timeoutAndMissingCli() {
        verify(Parser.error(124, "").includes("respond in time"));
        verify(Parser.error(127, "").includes("proton-vpn-cli"));
        compare(Parser.error(1, "Noise\nError: Authentication required"), "Error: Authentication required");
    }
    function test_tunnel(data) {
        compare(Parser.link(data.output).connected, data.connected);
    }
    function test_tunnel_data() {
        return [
            {
                tag: "wireguard",
                output: "ProtonVPN US#12:wireguard:proton0:activated",
                connected: true
            },
            {
                tag: "openvpn",
                output: "ProtonVPN NL#4:vpn:proton0:activated",
                connected: true
            },
            {
                tag: "kill-switch",
                output: "pvpn-killswitch-ipv6:dummy:ipv6leakintrf0:activated",
                connected: false
            },
            {
                tag: "misleading-wifi-name",
                output: "ProtonVPN US#12:802-11-wireless:wlan0:activated",
                connected: false
            },
            {
                tag: "unrelated-wireguard",
                output: "Work:wireguard:wg0:activated",
                connected: false
            },
            {
                tag: "activating",
                output: "ProtonVPN US#12:wireguard:proton0:activating",
                connected: false
            },
            {
                tag: "empty",
                output: "",
                connected: false
            }
        ];
    }

    name: "ProtonVpnParser"
}
