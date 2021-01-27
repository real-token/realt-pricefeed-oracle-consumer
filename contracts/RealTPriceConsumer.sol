pragma solidity 0.4.24;

import "@chainlink/contracts/contracts/v0.4/ChainlinkClient.sol";
import "@chainlink/contracts/contracts/v0.4/vendor/Ownable.sol";

/**
 * RealTPriceConsumer contract provides the Ethereum price for a given RealT property token,
 * by calling an external API via Chainlink oracle.
 */
contract RealTPriceConsumer is ChainlinkClient, Ownable {
  
  uint256 constant private ORACLE_PAYMENT = 1 * LINK;

  uint256 public currentPrice;

  event RequestEthereumPriceFulfilled(
    bytes32 indexed requestId,
    uint256 indexed price
  );

  constructor(address _linkToken) public Ownable() {
      if(_linkToken != 0x0) {
          setChainlinkToken(_linkToken);
      } else {
        setPublicChainlinkToken();
      }
  }

  function requestEthereumPrice(address _oracle, string _jobId)
    public
    onlyOwner
  {
    Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), this, this.fulfillEthereumPrice.selector);
    req.add("get", "https://pricefeed.realt.cc/price/feed/token/REALTOKEN-9943-MARLOWE-ST-DETROIT-MI");
    req.add("path", "Prices.ETH");
    sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
  }

  function fulfillEthereumPrice(bytes32 _requestId, uint256 _price)
    public
    recordChainlinkFulfillment(_requestId)
  {
    emit RequestEthereumPriceFulfilled(_requestId, _price);
    currentPrice = _price;
  }


  function getChainlinkToken() public view returns (address) {
    return chainlinkTokenAddress();
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }

  function cancelRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  )
    public
    onlyOwner
  {
    cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
  }

  function stringToBytes32(string memory source) private pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly { // solhint-disable-line no-inline-assembly
      result := mload(add(source, 32))
    }
  }

}