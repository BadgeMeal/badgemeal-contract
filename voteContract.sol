pragma solidity ^0.5.6;

contract BadgemealNFT {

	struct Proposal {
		string name;   // 메뉴 이름
		string imageUrl; // 메뉴 이미지 url
		address proposer; // 메뉴 제안자
		address voteContract; // 투표 컨트랙트 address
	}

	address public owner; // 컨트랙트 소유자

	mapping(address => bool) public nftHolders; // NFT 홀더 매핑

	Proposal[] public winnerProposals; // 투표로 채택된 메뉴 리스트

	constructor() public {
		owner = msg.sender;
	}

	// 소유자 체크 함수 변경자
	modifier onlyOwner() {
		require(
			msg.sender == owner,
			"msg sender is not a owner."
		);
		_;
	}

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
	function addWinnerProposal(string memory _name, string memory _imageUrl, address _proposer, address _voteContract) public onlyOwner {
		winnerProposals.push(Proposal({
		name: _name,
		imageUrl: _imageUrl,
		proposer: _proposer,
		voteContract: _voteContract
		}));
	}

	// 채택된 메뉴 리스트 확인 함수
	// function getWinnerProposals() public view returns(Proposal[] memory _winnerProposals) {
	// 	_winnerProposals = winnerProposals;
	// }

}

contract Vote {

	struct Proposal {
		string name;   // 메뉴 이름
		uint voteCount; // 투표 받은 수
		string imageUrl; // 메뉴 이미지 url
		address proposer; // 메뉴 제안자
	}

	struct Voter {
		bool exist;  // 투표자 존재 여부 (true,false)
		bool voted;  // 투표 진행 여부 (true,false)
		uint vote;   // Menu 리스트 요소의 index (0,1,2 ...)
	}

	address public owner; // 컨트랙트 소유자

	mapping(address => Voter) public voters; // 투표자 매핑

	Proposal[] public proposals; // 메뉴 리스트

	uint startTime; // 투표 시작 시간

	uint endTime; // 투표 마감 시간

	constructor(uint _startTime, uint _endTime) public {
		require(
			_startTime < _endTime,
			"start time needs to be lower than end time"
		);
		owner = msg.sender;
		startTime = _startTime;
		endTime = _endTime;
	}

	// 소유자 체크 함수 변경자
	modifier onlyOwner() {
		require(
			msg.sender == owner,
			"msg sender is not a owner."
		);
		_;
	}

	// 투표자 체크 함수 변경자
	modifier onlyVoter() {
		require(
			isVoter(msg.sender),
			"msg sender is not a registered voter."
		);
		_;
	}

	// 투표 기간 유효성 체크 함수
	modifier voteOpen() {
		require(
			now >= startTime && now < endTime,
			"voting currently not open"
		);
		_;
	}

	// 투표자 체크 함수
	function isVoter(address _address) public view returns(bool) {
		return voters[_address].exist;
	}

	// 메뉴 추가 함수
	function proposeMenu(string memory name, string memory imageUrl) public {
		/** 🔥 pseudocode 추가
		 	[require] msg.sender == 뱃지밀 마스터 NFT 소유자, "메뉴 추가 제안 권한이 없습니다."
		*/

		proposals.push(Proposal({
		name: name,
		voteCount: 0,
		imageUrl: imageUrl,
		proposer: msg.sender
		}));
	}

	// 투표자 추가 함수
	function addVoter(address _address, address nftAddress) private {
		require(
			BadgemealNFT(nftAddress).isHolder(_address),
			concat(toString(_address), " is not NFT Holder.")
		);
		require(
			!voters[_address].exist,
			concat(toString(_address), " is already added voter address.")
		);

		voters[_address] = Voter({
		exist: true,
		voted: false,
		vote: 0
		});
	}

	// 투표자 리스트 추가 함수
	function addVoters(address[] memory _addresses, address nftAddress) public onlyOwner {
		for (uint i = 0; i < _addresses.length; i++) {
			addVoter(_addresses[i], nftAddress);
		}
	}

	// 투표 함수
	function vote(uint proposal) public onlyVoter voteOpen {
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