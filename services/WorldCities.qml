pragma Singleton

import Quickshell

Singleton {
    readonly property list<var> entries: [
        {
            zone: "local",
            name: qsTr("Local time")
        },
        {
            zone: "Asia/Shanghai",
            name: qsTr("Beijing")
        },
        {
            zone: "Asia/Hong_Kong",
            name: qsTr("Hong Kong")
        },
        {
            zone: "Asia/Taipei",
            name: qsTr("Taipei")
        },
        {
            zone: "Asia/Tokyo",
            name: qsTr("Tokyo")
        },
        {
            zone: "Asia/Seoul",
            name: qsTr("Seoul")
        },
        {
            zone: "Asia/Singapore",
            name: qsTr("Singapore")
        },
        {
            zone: "Asia/Bangkok",
            name: qsTr("Bangkok")
        },
        {
            zone: "Asia/Kolkata",
            name: qsTr("New Delhi")
        },
        {
            zone: "Asia/Kathmandu",
            name: qsTr("Kathmandu")
        },
        {
            zone: "Asia/Dubai",
            name: qsTr("Dubai")
        },
        {
            zone: "Europe/London",
            name: qsTr("London")
        },
        {
            zone: "Europe/Paris",
            name: qsTr("Paris")
        },
        {
            zone: "Europe/Berlin",
            name: qsTr("Berlin")
        },
        {
            zone: "Europe/Rome",
            name: qsTr("Rome")
        },
        {
            zone: "Europe/Moscow",
            name: qsTr("Moscow")
        },
        {
            zone: "Europe/Istanbul",
            name: qsTr("Istanbul")
        },
        {
            zone: "Africa/Cairo",
            name: qsTr("Cairo")
        },
        {
            zone: "Africa/Johannesburg",
            name: qsTr("Johannesburg")
        },
        {
            zone: "America/New_York",
            name: qsTr("New York")
        },
        {
            zone: "America/Chicago",
            name: qsTr("Chicago")
        },
        {
            zone: "America/Denver",
            name: qsTr("Denver")
        },
        {
            zone: "America/Los_Angeles",
            name: qsTr("Los Angeles")
        },
        {
            zone: "America/Vancouver",
            name: qsTr("Vancouver")
        },
        {
            zone: "America/Toronto",
            name: qsTr("Toronto")
        },
        {
            zone: "America/Mexico_City",
            name: qsTr("Mexico City")
        },
        {
            zone: "America/Sao_Paulo",
            name: qsTr("São Paulo")
        },
        {
            zone: "Pacific/Honolulu",
            name: qsTr("Honolulu")
        },
        {
            zone: "Australia/Perth",
            name: qsTr("Perth")
        },
        {
            zone: "Australia/Adelaide",
            name: qsTr("Adelaide")
        },
        {
            zone: "Australia/Sydney",
            name: qsTr("Sydney")
        },
        {
            zone: "Pacific/Auckland",
            name: qsTr("Auckland")
        }
    ]

    function nameFor(zone: string): string {
        return entries.find(city => city.zone === zone)?.name ?? zone.split("/").pop().replace(/_/g, " ");
    }
}
