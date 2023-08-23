// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract Parkplatzverwaltung {
    struct Parkplatz {
        bool istBelegt;
        uint256 belegungsStartzeit;
        address fahrzeugBesitzer;
        uint256 ParkgebuehrProMinute;
        uint256 Parkgebuehren;
    }

    mapping(uint256 => Parkplatz) public parkplaetze;

    uint256[] public parkplatzIds;

    event ParkplatzBelegt(
        uint256 parkplatzId,
        address fahrzeugBesitzer,
        uint256 belegungsStartzeit
    );
    event ParkplatzFreigegeben(
        uint256 parkplatzId,
        address fahrzeugBesitzer,
        uint256 parkdauer,
        uint256 parkgebuehr
    );

    constructor() {
        generateParkplaetze(20, 1);
    }

    function generateParkplaetze(
        uint256 numParkplaetze,
        uint256 ParkgebuehrProMinute
    ) private {
        require(
            numParkplaetze > 0,
            "Anzahl der parkplaetze muss groesser sein"
        );

        for (uint256 i = 0; i < numParkplaetze; i++) {
            addParkplatz(i + 100, ParkgebuehrProMinute);
        }
    }

    // Funktion zum Hinzufügen eines Parkplatzes
    function addParkplatz(
        uint256 parkplatzId,
        uint256 ParkgebuehrProMinute
    ) private {
        require(
            !parkplaetze[parkplatzId].istBelegt,
            "Parkplatz ist bereits belegt"
        );
        parkplaetze[parkplatzId] = Parkplatz(
            false,
            0,
            address(0),
            ParkgebuehrProMinute,
            0
        );
        parkplatzIds.push(parkplatzId);
    }

    function getParkplatzIds() public view returns (uint256[] memory) {
        return parkplatzIds;
    }

    // Funktion zum Belegen eines Parkplatzes
    function parkplatzBelegen(uint256 parkplatzId) public {
        require(
            !parkplaetze[parkplatzId].istBelegt,
            "Parkplatz ist bereits belegt"
        );
        parkplaetze[parkplatzId].istBelegt = true;
        parkplaetze[parkplatzId].belegungsStartzeit = block.timestamp;
        parkplaetze[parkplatzId].fahrzeugBesitzer = msg.sender;
        emit ParkplatzBelegt(
            parkplatzId,
            msg.sender,
            parkplaetze[parkplatzId].belegungsStartzeit
        );
    }

    function getCurrentGebuehren(
        uint256 parkplatzId
    ) public view returns (uint256) {
        require(
            parkplaetze[parkplatzId].istBelegt,
            "Parkplatz ist nicht belegt"
        );

        uint256 parkdauer = block.timestamp -
            parkplaetze[parkplatzId].belegungsStartzeit;
        uint256 gebuehrenProMinute = parkplaetze[parkplatzId]
            .ParkgebuehrProMinute;

        // Überprüfen, ob 15 Minuten überschritten wurden
        if (parkdauer >= 15 seconds) {
            // Berechnung der erhöhten Gebühren
            uint256 zusatzgebuehren = (parkdauer / 15 seconds) *
                gebuehrenProMinute;
            return parkplaetze[parkplatzId].Parkgebuehren + zusatzgebuehren;
        }

        return parkplaetze[parkplatzId].Parkgebuehren;
    }

    // Funktion zum Freigeben eines Parkplatzes
    function parkplatzFreigeben(uint256 parkplatzId) public payable {
        require(
            parkplaetze[parkplatzId].istBelegt,
            "Parkplatz ist nicht belegt"
        );
        require(
            msg.sender == parkplaetze[parkplatzId].fahrzeugBesitzer,
            "Nur der Fahrzeugbesitzer kann den Parkplatz freigeben"
        );

        uint256 parkdauer = block.timestamp -
            parkplaetze[parkplatzId].belegungsStartzeit;
        uint256 parkgebuehrProMinute = parkplaetze[parkplatzId]
            .ParkgebuehrProMinute;
        uint256 parkgebuehrInWei = parkdauer * parkgebuehrProMinute;

        // Überprüfen, ob 15 Minuten überschritten wurden
        if (parkdauer >= 15 minutes) {
            // Berechnung der erhöhten Gebühren
            uint256 zusatzgebuehren = (parkdauer / 15 minutes) *
                parkgebuehrProMinute;
            parkgebuehrInWei += zusatzgebuehren;
        }

        delete parkplaetze[parkplatzId];
        emit ParkplatzFreigegeben(
            parkplatzId,
            msg.sender,
            parkdauer,
            parkgebuehrInWei
        );

        // Weitere Logik zur Abbuchung der Parkgebühr an den Parkplatzbetreiber
        address payable parkplatzbetreiber = payable(
            parkplaetze[parkplatzId].fahrzeugBesitzer
        );
        require(
            address(this).balance >= parkgebuehrInWei,
            "Unzureichendes Guthaben des Parkplatzbetreibers"
        );
        parkplatzbetreiber.transfer(parkgebuehrInWei);
    }

    // Funktion zum Abrufen des Parkplatzstatus
    function getParkplatzStatus(
        uint256 parkplatzId
    )
        public
        view
        returns (
            bool istBelegt,
            uint256 belegungsStartzeit,
            address fahrzeugBesitzer,
            uint256 ParkgebuehrProMinute
        )
    {
        return (
            parkplaetze[parkplatzId].istBelegt,
            parkplaetze[parkplatzId].belegungsStartzeit,
            parkplaetze[parkplatzId].fahrzeugBesitzer,
            parkplaetze[parkplatzId].ParkgebuehrProMinute
        );
    }
}
