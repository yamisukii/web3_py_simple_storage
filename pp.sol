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
        require(numParkplaetze > 0, "Anzahl der Parkplätze muss größer sein");

        for (uint256 i = 0; i < numParkplaetze; i++) {
            addParkplatz(i, ParkgebuehrProMinute);
        }
    }

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

    function parkplatzBelegen(uint256 parkplatzId) public {
        require(
            !parkplaetze[parkplatzId].istBelegt,
            "Parkplatz ist bereits belegt"
        );
        Parkplatz storage parkplatz = parkplaetze[parkplatzId];
        parkplatz.istBelegt = true;
        parkplatz.belegungsStartzeit = block.timestamp;
        parkplatz.fahrzeugBesitzer = msg.sender;
        emit ParkplatzBelegt(
            parkplatzId,
            msg.sender,
            parkplatz.belegungsStartzeit
        );
    }

    function getCurrentGebuehren(
        uint256 parkplatzId
    ) public view returns (uint256) {
        Parkplatz storage parkplatz = parkplaetze[parkplatzId];
        require(parkplatz.istBelegt, "Parkplatz ist nicht belegt");

        uint256 parkdauer = block.timestamp - parkplatz.belegungsStartzeit;
        uint256 gebuehrenProMinute = parkplatz.ParkgebuehrProMinute;

        if (parkdauer >= 15 seconds) {
            uint256 zusatzgebuehren = (parkdauer / 15 seconds) *
                gebuehrenProMinute;
            return parkplatz.Parkgebuehren + zusatzgebuehren;
        }

        return parkplatz.Parkgebuehren;
    }

    function parkplatzFreigeben(uint256 parkplatzId) public payable {
        Parkplatz storage parkplatz = parkplaetze[parkplatzId];
        require(parkplatz.istBelegt, "Parkplatz ist nicht belegt");
        require(
            msg.sender == parkplatz.fahrzeugBesitzer,
            "Nur der Fahrzeugbesitzer kann den Parkplatz freigeben"
        );

        uint256 parkdauer = block.timestamp - parkplatz.belegungsStartzeit;
        uint256 parkgebuehrProMinute = parkplatz.ParkgebuehrProMinute;
        uint256 parkgebuehrInWei = parkdauer * parkgebuehrProMinute;

        if (parkdauer >= 15 minutes) {
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

        address payable parkplatzbetreiber = payable(
            parkplatz.fahrzeugBesitzer
        );
        require(
            address(this).balance >= parkgebuehrInWei,
            "Unzureichendes Guthaben des Parkplatzbetreibers"
        );
        parkplatzbetreiber.transfer(parkgebuehrInWei);
    }

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
        Parkplatz storage parkplatz = parkplaetze[parkplatzId];
        return (
            parkplatz.istBelegt,
            parkplatz.belegungsStartzeit,
            parkplatz.fahrzeugBesitzer,
            parkplatz.ParkgebuehrProMinute
        );
    }
}
