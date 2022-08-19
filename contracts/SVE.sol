// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./TaxContract.sol";

contract SVE is Ownable, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    TaxContract taxContract;

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

    constructor() {
        _name = "Space marvel token";
        _symbol = "SVE";
        _decimals = 18;
        _totalSupply = 10**9 * 10**18;
        _mint(privateSaleAddress, 100 * 10**6 * 10**18);
        _mint(playToEarnAddress, 290 * 10**6 * 10**18);
        _mint(marketingAddress, 200 * 10**6 * 10**18);
        _mint(ecosystemAddress, 150 * 10**6 * 10**18);
        _mint(publicSaleAddress, 30 * 10**6 * 10**18);
        _mint(teamAdvisorAddress, 230 * 10**6 * 10**18);
    }

    event UpdateTaxContract(
        address oldContract,
        address newContract,
        uint256 time
    );

    function updateTaxContract(TaxContract _taxContract) external onlyOwner {
        require(address(_taxContract) != address(0), "Error: address(0)");
        emit UpdateTaxContract(
            address(taxContract),
            address(_taxContract),
            block.timestamp
        );
        taxContract = _taxContract;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address from, uint256 value) internal {
        _balances[from] = _balances[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        uint256 taxAmount = 0;
        if (address(taxContract) != address(0))
            taxAmount = taxContract.applyTax(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        if (taxAmount > 0) {
            _balances[recipient] = _balances[recipient].add(amount - taxAmount);
            _balances[address(taxContract)] = _balances[address(taxContract)]
                .add(taxAmount);
            emit Transfer(sender, recipient, amount - taxAmount);
            emit Transfer(sender, address(taxContract), taxAmount);
        } else {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    event Withdraw(address tokenContract, uint256 amount, uint256 time);

    function withdrawToken(address _tokenContract, uint256 _amount)
        external
        onlyOwner
    {
        IERC20 token = IERC20(_tokenContract);

        token.transfer(msg.sender, _amount);
        emit Withdraw(_tokenContract, _amount, block.timestamp);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
