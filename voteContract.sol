pragma solidity ^0.5.0;

contract Vote {

	struct Proposal {
		string name;   // 메뉴 이름
		uint voteCount; // 투표 받은 수
		string imageUrl; // 메뉴 이미지 url
		address proposer; // 메뉴 제안자

	}
    
	struct Voter {
		bool voted;  // 투표 진행 여부 (true,false)
		uint vote;   // Menu 리스트 요소의 index (0,1,2 ...)
		uint weight; // 투표 권한

	}
	
	address public deployer; // 컨트랙트 배포자
	
	mapping(address => Voter) public voters; // 투표자 매핑

	address[] public voterList; // 투표자 리스트
	
	Proposal[] public proposals; // 메뉴 리스트

	Proposal[] public winnerProposals; // 투표로 채택된 메뉴 리스트

	constructor() public {
		deployer = msg.sender;
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

	// 투표자 리스트 추가 함수
	function addVoters(address[] memory addressList) public {
			require(
					msg.sender == deployer,
					"Only deployer can give right to vote."
			);
			require(
					voterList.length == 0,
					"Already added Voters."
			);

			/** 🔥 수정 필요
				addressList를 입력값으로 받는 것이 아니라 NFT 홀더 리스트를 가져오는 함수를 호출한 후 아래 로직을 실행하는게 좋을 것 같다.
			*/
			
			for (uint i = 0; i < addressList.length; i++) {
					voterList.push(addressList[i]);
			}
	}
    
	// 투표 권한 부여 함수
	function giveRightToVote(address voter) private {
			require(
					msg.sender == deployer,
					"Only deployer can give right to vote."
			);
			require(
					!voters[voter].voted,
					"The voter already voted."
			);
			require(voters[voter].weight == 0);
			voters[voter].weight = 1;
	}

	// 투표자 리스트 모두에게 권한 부여
    function giveVotersRightToVote() public {
        for (uint i = 0; i < voterList.length; i++) {
            giveRightToVote(voterList[i]);
        }
    }


	// 투표 함수
	function vote(uint proposal) public {
		Voter storage sender = voters[msg.sender];

		/** 🔥 pseudocode 추가
		 	[require] msg.sender == 뱃지밀 일반 NFT 소유자, "투표 권한이 없습니다."
		*/
		require(sender.weight != 0, "Has no right to vote");
		require(!sender.voted, "Already voted.");

		sender.voted = true;
		sender.vote = proposal;

		proposals[proposal].voteCount += sender.weight;
	}

	// 가장 많은 득표수를 얻은 메뉴 index 출력하는 함수
	function winningProposal() public view returns (uint winningProposal_) {
			uint winningVoteCount = 0;
			for (uint p = 0; p < proposals.length; p++) {
					if (proposals[p].voteCount > winningVoteCount) {
							winningVoteCount = proposals[p].voteCount;
							winningProposal_ = p;
					}
			}
	}

	// 가장 많은 득표수를 얻은 메뉴 이름을 리턴하는 함수
	function winnerName() public view returns (string memory winnerName_) {
			winnerName_ = proposals[winningProposal()].name;
	}

	/** 🔥 pseudocode 추가
		function 투표 마감
		1. 투표 시간이 마감되면 가장 많은 득표수를 얻은 메뉴 Proposal을 winnerProposals 에 push 한다.
		2. Proposals를 초기화한다.
	*/
}