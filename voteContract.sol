pragma solidity ^0.5.6;

contract BadgemealNFT {

	struct Proposal {
		string menu;   // 메뉴 이름
		address proposer; // 메뉴 제안자
		uint voteCount; // 투표 받은 수
		address voteContract; // 투표 컨트랙트 address
	}

	address public owner; // 컨트랙트 소유자

	mapping(address => bool) public nftHolders; // NFT 홀더 매핑

	Proposal[] public electedProposals; // 투표로 채택된 메뉴 리스트

	constructor() public {
		owner = msg.sender;
	}

	// modifier
	// owner 인지 확인
	modifier checkOwner() {
		require(
			msg.sender == owner,
			"msg sender is not a owner."
		);
		_;
	}

	// function
	// NFT 홀더 체크 함수
	function isHolder(address _address) public view returns(bool) {
		return nftHolders[_address];
	}

	// 채택된 메뉴 추가 함수
	function addElectedProposal(Proposal _electedProposal, address _voteContract) public{
		winnerProposals.push(Proposal({
		menu: _electedProposal.menu,
		proposer: _electedProposal.proposer,
		voteContract: _voteContract
		}));
	}

	// NFT 홀더 추가 함수
	function addNFTHolder(address _address) private {
		require(
			!nftHolders[_address],
			"already added NFT Holder address."
		);

		nftHolders[_address] = true;
	}
}

contract Vote {
	struct Proposal {
		string menu;   // 메뉴 이름
		uint voteCount; // 투표 받은 수
		address proposer; // 메뉴 제안자
	}

	struct Vote {
		uint vote;   // Menu 리스트 요소의 index (0,1,2 ...)
	}

	string badgeNFTAddress = "0x0000000000000000000000";

	Proposal electedProposal; // 선출된 투표결과 저장

	address public owner; // 컨트랙트 소유자

	mapping(address => Vote) public votes; // 투표한 건수들 모음

	Proposal[] public proposals; // 투표할 메뉴 리스트

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

	// modifier
	// owner 인지 확인
	modifier checkOwner() {
		require(
			msg.sender == owner,
			"msg sender is not a owner."
		);
		_;
	}
	// 투표가능 여부 (투표 가능한 사람 + 가능한 기간)
	modifier checkVoteAvailable() {
		require(
			BadgemealNFT(badgeNFTAddress).isHolder(msg.sender),
			"msg sender don't have vote authority."
		);
		require(
			now >= startTime && now < endTime,
			"this vote is not available"
		);
		_;
	}
	// 이미 투표 했는지 확인
	modifier alreadyVoted() {
		require(
			votes[msg.sender] != null,
			"msg sender already voted"
		);
		_;
	}
	// 투표 결과 선언
	modifier announceResult() {
		require(
			now > endTime,
			"The vote is not ended."
		);
		if(electedProposal == null){
			uint voteCount = 0;
			uint electedIndex = 0; // 투표가 모두 0이면 제일 먼저 등록한 메뉴로 선정 (선착순)
			for (uint i = 0; i < proposals.length; i++) {
				if (proposals[i].voteCount > voteCount) {
					voteCount = proposals[i].voteCount;
					winningProposal_ = i;
				}
			}
			electedProposal = proposals[electedIndex];
			BadgemealNFT(badgeNFTAddress).addElectedProposal(electedProposal, address(this));
		}
		_;
	}

	// function
	// 메뉴 제안
	function proposeMenu(string memory _menu) checkVoteAvailable public{
		proposals.push(Proposal({
		menu: _menu,
		voteCount: 0,
		proposer: msg.sender
		}));
	}
	// 투표
	function vote(uint proposalIndex) checkVoteAvailable alreadyVoted public{
		votes[msg.sender] = Vote({
		vote: proposalIndex
		});

		votes[msg.sender].vote = proposalIndex;
		proposals[proposalIndex].voteCount++;
	}

	// 투표 결과 - electedProposal 변수에 값이 있으면 반환, 없으면 저장하고 반환
	function electedProposal() announceResult public view returns (Proposal memory electedProposal_) {
		electedProposal_ = electedProposal;
	}
	// 가장 많은 득표수를 얻은 메뉴 이름을 리턴
	function electedMenuName() public view announceResult returns (string memory electedMenuName_) {
		electedMenuName_ = electedProposal.menu;
	}
	// 가장 많은 득표수를 얻은 메뉴의 득표수를 리턴
	function electedMenuVoteCount() public view announceResult returns (uint memory electedMenuVoteCount_) {
		electedMenuVoteCount_ = electedProposal.voteCount;
	}
	// 가장 많은 득표수를 얻은 메뉴의 제안자 address를 리턴
	function electedMenuVoterAddress() public view announceResult returns (address memory electedMenuVoterAddress_) {
		electedMenuVoterAddress_ = electedProposal.proposer;
	}
}
