# BadgeMeal Smart Contract

## KIP17 표준 컨트랙트 수정 사항

1. Ownable 컨트랙트를 가져온다. 
@openzeppelin/contracts/ownership/Ownable.sol

2. 뱃지밀 컨트랙트에 Ownable 컨트랙트를 상속 받는다.
```sol
contract Klaytn17MintBadgemeal is KIP17Full, KIP17Mintable, KIP17MetadataMintable, KIP17Burnable, KIP17Pausable, Ownable {
  //... 생략
}
```

## Vote 컨트랙트

1. 필요한 구조체 및 변수 선언
```sol
	struct Proposal {
		string name;   // 메뉴 이름
		uint256 voteCount; // 투표 받은 수
		address proposer; // 메뉴 제안자
	}
	struct Voter {
		bool voted;  // 투표 진행 여부 (true,false)
		uint vote;   // Menu 리스트 요소의 index (0,1,2 ...)
	}
  struct VoteHistory {
    mapping(address => Voter) voters; 
  }

  uint public proposeStartTime; // 메뉴 추가 시작 시간
  uint public voteStartTime; // 투표 시작 시간

	mapping(uint => VoteHistory) VoteHistoryMap; // voteStartTime과 투표자 매핑
	Proposal[] public proposals; // 메뉴 리스트
	Proposal[] public winnerProposals; // 투표로 채택된 메뉴 리스트

  event AddWinner(string indexed name, uint indexed voteCount, address proposer); // 채택된 메뉴 추가할 때 쓰는 이벤트

```

2. 공통으로 사용할 util 함수 선언
- proposeAvailable : 메뉴 추가 가능한 시간인지 검증하는 함수변경자
- voteAvailable : 투표 가능한 시간인지 검증하는 함수변경자
- isNFTholder : NFT 소유자인지 판단하는 함수
  - params: 뱃지밀 NFT 컨트랙트 주소
- isMasterNFTholder : 마스터 NFT 소유자인지 판단하는 함수
  - params: 뱃지밀 NFT 컨트랙트 주소

```sol
modifier proposeAvailable() {
    require(now >= proposeStartTime && now < proposeStartTime + 1 days, "Cannot propose now.");
    _;
}
modifier voteAvailable() {
    require(now >= voteStartTime && now < voteStartTime + 1 days, "Cannot vote now.");
    _;
}

function isNFTholder(address _nftAddress) public view returns(bool) {
    return Klaytn17MintBadgemeal(_nftAddress).getOwnedTokens(msg.sender).length != 0;
}

function isMasterNFTholder(address _nftAddress) public view returns(bool) {
    uint256[] memory ownedTokenLIst = Klaytn17MintBadgemeal(_nftAddress).getOwnedTokens(msg.sender);
    bool result = false;
    for (uint256 i = 0; i < ownedTokenLIst.length; i++) {
        if (Klaytn17MintBadgemeal(_nftAddress).tokenLevel(ownedTokenLIst[i]) == 2) {
          result = true;
          break;
        } 
    }
    return result;
}
```

3. 메뉴 제안 함수
- require : 마스터 NFT 소유자
- params: 메뉴이름, 뱃지밀 NFT 컨트랙트 주소

```sol
function proposeMenu(string memory _name, address _nftAddress) public proposeAvailable{
    require(isMasterNFTholder(_nftAddress), "You have no right to propose.");

    proposals.push(Proposal({
      name: _name,
      voteCount: 0,
      proposer: msg.sender
    }));
}
```

4. 투표 함수
- require : NFT 소유자 && 아직 투표하지 않은 투표권자
- params: 메뉴이름, 뱃지밀 NFT 컨트랙트 주소

```sol
function vote(uint _proposal, address _nftAddress) public voteAvailable {
    require(isNFTholder(_nftAddress), "You have no right to vote");
          require(!VoteHistoryMap[voteStartTime].voters[msg.sender].voted, "Already voted.");
          require(_proposal < proposals.length && _proposal >= 0, "Wrong index.");

    VoteHistoryMap[voteStartTime].voters[msg.sender].voted = true;
    VoteHistoryMap[voteStartTime].voters[msg.sender].vote = _proposal;
          
    proposals[_proposal].voteCount = proposals[_proposal].voteCount.add(1);
}
```

5. 가장 많은 득표수 얻은 메뉴의 index 출력 함수
```sol
function winningProposal() public view returns (uint winningProposal_) {
    uint winningVoteCount = 0;
    for (uint p = 0; p < proposals.length; p++) {
        if (proposals[p].voteCount > winningVoteCount) {
            winningVoteCount = proposals[p].voteCount;
            winningProposal_ = p;
        }
    }
}
```

6. 가장 많은 득표수를 얻은 메뉴의 이름을 리턴하는 함수
```sol
function winnerName() public view returns (string memory winnerName_) {
    winnerName_ = proposals[winningProposal()].name;
}
```

7. 가장 많은 득표수를 얻은 메뉴를 향후 메뉴 리스트에 추가하는 함수
- 기존 메뉴 리스트는 DB에 있고, 투표로 추가된 메뉴 리스트는 vote 컨트랙트의 `winnerProposals`변수에 담긴다.
- 호츨 조건: 투표가 마감되는 시점에 백엔드에서 호출한다.
- require: voteCount가 메뉴 NFT 소유자의 과반수 이상
- addWinnerProposal 가 발생하면 event를 발생시켜, 백엔드에서 이를 인지 후 DB의 메뉴 리스트에 `winnerProposals`를 추가한다.

```sol
function addWinnerProposal(address _nftAddress) public onlyOwner addProposeAvailable {
    Proposal storage winner = proposals[winningProposal()];
          require(winner.voteCount > (Klaytn17MintBadgemeal(_nftAddress).totalSupply() / 2), "The proposal did not win majority of the votes.");

    winnerProposals.push(winner);

    // event 발생
    emit AddWinner(winner.name, winner.voteCount, winner.proposer);

    // proposals 초기화
    delete proposals;
}
```

8. 투표 시작 및 메뉴 추가 시작 시간 세팅하는 함수
- 백엔드 스케줄러를 통해 매달 말일 `setProposeStartTime` 실행
- 백엔드 스케줄러를 통해 매달 1일 `setVoteStartTime` 실행

```sol
function setVoteStartTime () public onlyOwner {
    voteStartTime = now;
}
// 메뉴 추가 시작 시간 세팅하는 함수
function setProposeStartTime () public onlyOwner {
    proposeStartTime = now;
}
```