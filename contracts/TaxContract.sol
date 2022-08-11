// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TaxContract is Ownable {
    using SafeMath for uint256;
    struct Tax {
        uint256 from;
        uint256 to;
        uint256 percent; //2 decimal
        bool valid;
    }

    Tax[] public taxs;

    mapping(address => bool) exclusedTax;

    address constant privateSaleAddress =
        0xC0ec934a21D27143B2e4BC26a7e2eCec3Eae6cB8;
    address playToEarnAddress = 0xa113933D3310b92bfC47310c92691A632F5BC4e7;
    address marketingAddress = 0x343D14587dF910f682AE77c3e809DCda8a52AB7D;
    address ecosystemAddress = 0x88dfD1B40c6cF9701DFCc1EBD12BBFb0AA52982E;
    address publicSaleAddress = 0xA596C18957CC8b933a9d75a326e47Dd3ddB9129E;
    address teamAdvisorAddress = 0x43cbB65cc934360c6ECA0Fa19a100380A6d221B2;

    constructor() {
        exclusedTax[privateSaleAddress] = true;
        exclusedTax[playToEarnAddress] = true;
        exclusedTax[marketingAddress] = true;
        exclusedTax[ecosystemAddress] = true;
        exclusedTax[publicSaleAddress] = true;
        exclusedTax[teamAdvisorAddress] = true;
        exclusedTax[_msgSender()] = true;
    }

    function setExclusedTaxs(
        address[] memory _accounts,
        bool[] memory _isExcluseds
    ) external onlyOwner {
        require(
            _accounts.length == _isExcluseds.length,
            "Error: input invalid"
        );
        for (uint8 i = 0; i < _accounts.length; i++)
            exclusedTax[_accounts[i]] = _isExcluseds[i];
    }

    function setTaxs(
        uint256[] calldata _froms,
        uint256[] calldata _tos,
        uint256[] calldata _percents,
        bool[] calldata _valids
    ) external onlyOwner {
        require(_froms.length == _tos.length, "Error: invalid input");
        require(_froms.length == _percents.length, "Error: invalid input");
        require(_froms.length == _valids.length, "Error: invalid input");

        if (_froms.length > 0) {
            delete taxs;

            for (uint256 i = 0; i < _froms.length; i++) {
                Tax storage tax = taxs.push();
                tax.from = _froms[i];
                tax.to = _tos[i];
                tax.percent = _percents[i];
                tax.valid = _valids[i];
            }
        }
    }

    function modifyTax(
        uint256 _index,
        uint256 _from,
        uint256 _to,
        uint256 _percent
    ) external onlyOwner {
        require(_index < taxs.length, "Invalid _index");
        require(_from > 0, "Invalid from");
        require(_to > _from, "Invalid from to");

        if (_from != taxs[_index].from) taxs[_index].from = _from;

        if (_to != taxs[_index].to) taxs[_index].to = _to;

        if (_percent != taxs[_index].percent) taxs[_index].percent = _percent;
    }

    function getTax()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        for (uint256 i = 0; i < taxs.length; i++) {
            Tax memory tax = taxs[i];

            if (tax.from == 0 && tax.to == 0 && tax.valid)
                return (0, 0, 0, tax.percent);

            if (
                block.timestamp >= tax.from &&
                block.timestamp <= tax.to &&
                tax.valid
            ) return (i + 1, tax.from, tax.to, tax.percent);
        }

        return (0, 0, 0, 0);
    }

    function applyTax(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external view returns (uint256) {
        if (taxs.length == 0) return 0;

        if (exclusedTax[_sender] || exclusedTax[_recipient]) return 0;

        (, , , uint256 percent) = getTax();

        if (percent > 0) {
            uint256 taxAmount = uint256(_amount * percent) / uint256(10000); //2 decimals
            return taxAmount;
        }
        return 0;
    }

    function withdrawToken(address _tokenContract, uint256 _amount)
        external
        onlyOwner
    {
        IERC20(_tokenContract).transfer(_msgSender(), _amount);
    }
}
