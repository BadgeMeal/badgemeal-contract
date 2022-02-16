// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
	// Empty internal constructor, to prevent people from mistakenly deploying
	// an instance of this contract, which should be used via inheritance.
	constructor () internal { }
	// solhint-disable-previous-line no-empty-blocks

	function _msgSender() internal view returns (address payable) {
		return msg.sender;
	}

	function _msgData() internal view returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
	constructor () internal {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	/**
     * @dev Returns the address of the current owner.
     */
	function owner() public view returns (address) {
		return _owner;
	}

	/**
     * @dev Throws if called by any account other than the owner.
     */
	modifier onlyOwner() {
		require(isOwner(), "Ownable: caller is not the owner");
		_;
	}

	/**
     * @dev Returns true if the caller is the current owner.
     */
	function isOwner() public view returns (bool) {
		return _msgSender() == _owner;
	}

	/**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
	function renounceOwnership() public onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	/**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
	function transferOwnership(address newOwner) public onlyOwner {
		_transferOwnership(newOwner);
	}

	/**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
	function _transferOwnership(address newOwner) internal {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

pragma solidity ^0.5.6;

contract BadgemealNFT is Ownable {

	struct Proposal {
		string name;   // 메뉴 이름
		address proposer; // 메뉴 제안자
		address voteContract; // 투표 컨트랙트 address
	}

	mapping(address => bool) public nftHolders; // NFT 홀더 매핑

	Proposal[] public winnerProposals; // 투표로 채택된 메뉴 리스트

	// NFT 홀더 체크 함수
	function isHolder(address _address) public view returns(bool) {
		return nftHolders[_address];
	}

    // NFT 홀더 추가 함수
	function addNFTHolder(address _address) private {
		require(
			!nftHolders[_address],
			"already added NFT Holder address."
		);

		nftHolders[_address] = true;
	}

	// NFT 홀더 리스트 추가 함수
	function addNFTHolders(address[] memory _addresses) public onlyOwner {
		for (uint i = 0; i < _addresses.length; i++) {
			addNFTHolder(_addresses[i]);
		}
	}

	// 채택된 메뉴 추가 함수
	function addWinnerProposal(string memory _name, address _proposer, address _voteContract) public onlyOwner {
		winnerProposals.push(Proposal({
		name: _name,
		proposer: _proposer,
		voteContract: _voteContract
		}));
	}

	// 채택된 메뉴 리스트 확인 함수
	// function getWinnerProposals() public view returns(Proposal[] memory _winnerProposals) {
	// 	_winnerProposals = winnerProposals;
	// }

}

pragma solidity ^0.5.6;

contract Vote is Ownable {

	struct Proposal {
		string name;   // 메뉴 이름
		uint voteCount; // 투표 받은 수
		address proposer; // 메뉴 제안자
	}

	struct Voter {
		bool voted;  // 투표 진행 여부 (true,false)
		uint vote;   // Menu 리스트 요소의 index (0,1,2 ...)
	}

	mapping(address => Voter) public voters; // 투표자 매핑

	Proposal[] public proposals; // 메뉴 리스트

	uint startTime; // 투표 시작 시간

	uint endTime; // 투표 마감 시간

	constructor(uint _startTime, uint _endTime) public {
		require(
			_startTime < _endTime,
			"start time needs to be lower than end time"
		);
		startTime = _startTime;
		endTime = _endTime;
	}

	// 투표 기간 유효성 체크 함수
	modifier voteOpen() {
		require(
			now >= startTime && now < endTime,
			"voting currently not open"
		);
		_;
	}

	// 메뉴 추가 함수
	function proposeMenu(string memory name) public {
		/** 🔥 pseudocode 추가
		 	[require] msg.sender == 뱃지밀 마스터 NFT 소유자, "메뉴 추가 제안 권한이 없습니다."
		*/

		proposals.push(Proposal({
		name: name,
		voteCount: 0,
		proposer: msg.sender
		}));
	}

	// 투표자 추가 함수
	//	function addVoter(address _address, address nftAddress) private {
	//		require(
	//			BadgemealNFT(nftAddress).isHolder(_address),
	//			concat(toString(_address), " is not NFT Holder.")
	//		);
	//		require(
	//			!voters[_address].exist,
	//			concat(toString(_address), " is already added voter address.")
	//		);
	//
	//		voters[_address] = Voter({
	//			exist: true,
	//			voted: false,
	//			vote: 0
	//		});
	//	}

	// 투표자 리스트 추가 함수
	//	function addVoters(address[] memory _addresses, address nftAddress) public onlyOwner {
	//		for (uint i = 0; i < _addresses.length; i++) {
	//			addVoter(_addresses[i], nftAddress);
	//		}
	//	}

	// 투표 함수
	function vote(uint proposal, address nftAddress) public voteOpen {
		require(
			BadgemealNFT(nftAddress).isHolder(msg.sender),
			concat(toString(msg.sender), " is not NFT Holder.")
		);
		require(!voters[msg.sender].voted, "Already voted.");

		voters[msg.sender].voted = true;
		voters[msg.sender].vote = proposal;
		proposals[proposal].voteCount++;
	}

	// 가장 많은 득표수를 얻은 메뉴 index 출력하는 함수
	function winningProposal() public view onlyOwner returns (uint winningProposal_) {
		uint winningVoteCount = 0;
		for (uint p = 0; p < proposals.length; p++) {
			if (proposals[p].voteCount > winningVoteCount) {
				winningVoteCount = proposals[p].voteCount;
				winningProposal_ = p;
			}
		}
	}

	// 가장 많은 득표수를 얻은 메뉴 이름을 리턴하는 함수
	function winnerName() public view onlyOwner returns (string memory winnerName_) {
		winnerName_ = proposals[winningProposal()].name;
	}

	// address -> string 변환 함수
	function toString(address account) internal pure returns(string memory) {
		return toString(abi.encodePacked(account));
	}

	// address -> string 변환 함수
	function toString(bytes memory data) internal pure returns(string memory) {
		bytes memory alphabet = "0123456789abcdef";

		bytes memory str = new bytes(2 + data.length * 2);
		str[0] = "0";
		str[1] = "x";
		for (uint i = 0; i < data.length; i++) {
			str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
			str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
		}

		return string(str);
	}

	// string concat 함수
	function concat(string memory a, string memory b) internal pure returns (string memory) {
		return string(abi.encodePacked(a, b));
	}
}