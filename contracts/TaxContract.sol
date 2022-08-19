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

    mapping(address => bool) excludedTax;

    address constant privateSaleAddress =
        0xC0ec934a21D27143B2e4BC26a7e2eCec3Eae6cB8;
    address constant playToEarnAddress =
        0xa113933D3310b92bfC47310c92691A632F5BC4e7;
    address constant marketingAddress =
        0x343D14587dF910f682AE77c3e809DCda8a52AB7D;
    address constant ecosystemAddress =
        0x88dfD1B40c6cF9701DFCc1EBD12BBFb0AA52982E;
    address constant publicSaleAddress =
        0xA596C18957CC8b933a9d75a326e47Dd3ddB9129E;
    address constant teamAdvisorAddress =
        0x43cbB65cc934360c6ECA0Fa19a100380A6d221B2;

    event ExcludedTax(address user, bool isExcluded, uint256 time);

    constructor() {
        excludedTax[privateSaleAddress] = true;
        emit ExcludedTax(privateSaleAddress, true, block.timestamp);
        excludedTax[playToEarnAddress] = true;
        emit ExcludedTax(playToEarnAddress, true, block.timestamp);
        excludedTax[marketingAddress] = true;
        emit ExcludedTax(marketingAddress, true, block.timestamp);
        excludedTax[ecosystemAddress] = true;
        emit ExcludedTax(ecosystemAddress, true, block.timestamp);
        excludedTax[publicSaleAddress] = true;
        emit ExcludedTax(publicSaleAddress, true, block.timestamp);
        excludedTax[teamAdvisorAddress] = true;
        emit ExcludedTax(teamAdvisorAddress, true, block.timestamp);
        excludedTax[_msgSender()] = true;
        emit ExcludedTax(_msgSender(), true, block.timestamp);
    }

    function setExclusedTaxs(
        address[] memory _accounts,
        bool[] memory _isExcludeds
    ) external onlyOwner {
        require(
            _accounts.length == _isExcludeds.length,
            "Error: input invalid"
        );
        for (uint8 i = 0; i < _accounts.length; i++) {
            require(_accounts[i] != address(0), "Error: address(0");
            excludedTax[_accounts[i]] = _isExcludeds[i];
            emit ExcludedTax(_accounts[i], _isExcludeds[i], block.timestamp);
        }
    }

    event SetTax(
        uint256 from,
        uint256 to,
        uint256 percent,
        bool valid,
        uint256 time
    );

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
                require(_percents[i] < 10000, "Error: percent > 100");
                Tax storage tax = taxs.push();
                tax.from = _froms[i];
                tax.to = _tos[i];
                tax.percent = _percents[i];
                tax.valid = _valids[i];
                emit SetTax(
                    _froms[i],
                    _tos[i],
                    _percents[i],
                    _valids[i],
                    block.timestamp
                );
            }
        }
    }

    event UpdateTax(
        uint256 index,
        uint256 from,
        uint256 to,
        uint256 percent,
        uint256 time
    );

    function modifyTax(
        uint256 _index,
        uint256 _from,
        uint256 _to,
        uint256 _percent
    ) external onlyOwner {
        require(_index < taxs.length, "Invalid _index");
        require(_from > 0, "Invalid from");
        require(_to > _from, "Invalid from to");
        require(_percents[i] < 10000, "Error: percent > 100");

        if (_from != taxs[_index].from) taxs[_index].from = _from;

        if (_to != taxs[_index].to) taxs[_index].to = _to;

        if (_percent != taxs[_index].percent) taxs[_index].percent = _percent;
        emit UpdateTax(_index, _from, _to, _percent, block.timestamp);
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

        if (excludedTax[_sender] || excludedTax[_recipient]) return 0;

        (, , , uint256 percent) = getTax();

        if (percent > 0) {
            uint256 taxAmount = uint256(_amount * percent) / uint256(10000); //2 decimals
            return taxAmount;
        }
        return 0;
    }

    event Withdraw(address tokenContract, uint256 amount, uint256 time);

    function withdrawToken(address _tokenContract, uint256 _amount)
        external
        onlyOwner
    {
        IERC20(_tokenContract).transfer(_msgSender(), _amount);
        emit Withdraw(_tokenContract, _amount, block.timestamp);
    }
}
