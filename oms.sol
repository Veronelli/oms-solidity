// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


contract OmsCovid{
    // Direccion de OMS -> Owner / Dueño del contrato
    address public OMS;

    constructor()public{
        OMS = msg.sender;
    }

    // Mapping para relacionar los centros de salud (direccion/address) con la validez del sistema de gestion
    mapping(address=> bool) public aprobacionCentroSalud;

    // Relacionar direccion de centros de salud con un contrato
    mapping(address=>address) public direccionContrato;

    // Array Direcciones
    address[] public direccionesContratosSalud;

    // Eventos a emitir
    event nuevo_centro_validado(address);
    event nuevo_contrato(address, address);
    event solicitar_acceso(address);

    // Array de las direcciones que soliciten acceso
    address[] solicitudes;

    // Modificadores
    modifier isOMS(){
        require(msg.sender == OMS, "No eres la OMS");
        _;
    }

    // Validar nuevo centro de salud
    function centroSalud(address _direccion)public isOMS(){
        aprobacionCentroSalud[_direccion] = true;
        emit nuevo_centro_validado(_direccion);
    }

    function solicitarAcceso() public {
        solicitudes.push(msg.sender);
        emit solicitar_acceso(msg.sender);
    }

    function FactoryCentroSalud()public{
        // Filtrado de los centros de salud puedan generar un contrato
        require(aprobacionCentroSalud[msg.sender] == true ,"Esta direccion no esta abilitada para generar un nuevo contrato");
        address contratoCentroSalud = address(new CentroSalud(msg.sender));
        direccionesContratosSalud.push(contratoCentroSalud);

        direccionContrato[msg.sender] = contratoCentroSalud;
        emit nuevo_contrato(contratoCentroSalud, msg.sender);

    }

    function visualizarSolicitudes() public view isOMS() returns(address[] memory){
        return solicitudes;
    }

    // Ver contrato de una direccion
    function verContrato() public  view returns(address){
        return direccionContrato[msg.sender];
    }

}

contract CentroSalud{

    struct Resultado{
        bool resultadoCovid;
        string[] resultadosCOVID_IPFS;
    }

    address public centroSalud; 
    address public direccionContrato;

    // mapping (bytes32=>bool) resultadoCovid;
    // mapping (bytes32=>string) resultadoCOVID_IPFS;
    mapping (bytes32=>Resultado)resultadosCovid;

    // Eventos
    event nuevo_resultado(string,bool);

    constructor(address _direccion)public{
        centroSalud = _direccion;
        direccionContrato = address(this);
    }

    modifier isCentroSalud(){
        require(centroSalud == msg.sender,"No eres el centro de salud");
        _;
    }

    // CID Example QmQhSPRu4E9Jgj1JsVn22rcZKff5vUdXbwMRfqNvSfgDzv

    // Funcion para emitir un resultado de una prueba COVID
    function resultadoPruebaCovid(string memory _idPersona, bool _resultado, string memory _codigoIPFS) public isCentroSalud(){
        // Hash de la identificacion de la idPersona_boleto
        bytes32 hashPersona = keccak256(abi.encodePacked(_idPersona));
        resultadosCovid[hashPersona].resultadoCovid = _resultado;

        resultadosCovid[hashPersona].resultadosCOVID_IPFS.push(_codigoIPFS);
        emit nuevo_resultado(_codigoIPFS,_resultado);

    }

    function verResultado(string memory _idPersona) public view returns(bool) {
        bytes32 hashPersona = keccak256(abi.encodePacked(_idPersona));
        return resultadosCovid[hashPersona].resultadoCovid;
    }
    
    function verTodosIPFS(string memory _idPersona) public view returns(string[] memory) {
        bytes32 hashPersona = keccak256(abi.encodePacked(_idPersona));
        return resultadosCovid[hashPersona].resultadosCOVID_IPFS;
    }

    function verUltimoIPFS(string memory _idPersona) public view returns(string memory){
        bytes32 hashPersona = keccak256(abi.encodePacked(_idPersona));
        uint lengthResult = resultadosCovid[hashPersona].resultadosCOVID_IPFS.length;
        return resultadosCovid[hashPersona].resultadosCOVID_IPFS[length];
    }
}