# BadgeMeal Smart Contract

## voteContract
### 주요 변경 사항
- 제안한 메뉴 리스트를 조회하는 funciton, propsedMenuList 추가
- voteContract에 투표 결과를 저장하는 electedProposal 변수를 추가하고 투표 결과를 선언하는 announceResult modifier를 추가. 결과를 조회하는 function을 실행 할때마다 announceResult를 호출하도록 선언.
- 투표 결과를 선언하는 announceResult modifier에서 모든 투표수가 '0'일때 선착순으로 등록한 메뉴가 등록되도록 선언.
- 기존에 선언되어 있던 voterList는 불필요 하다고 판단, 구현하지 않음 (=>용도를 잘 모르겠습니다..)
***

### 기존 voteContract.sol 추가 및 수정

1. badgeMeal 마스터 NFT에 필요한 기능들 선언
  - NFT를 소유하고 있는 유저인지 확인하는 function
   ```Solidity
function isHolder(address _address) public view returns(bool) {
		return nftHolders[_address];
	}
   ```
2.  vote contract에 필요한 modifier
  - contract 소유자인지 확인하는 modifier
   ```Solidity
modifier checkOwner() {
		require(
			msg.sender == owner,
			"msg sender is not a owner."
		);
		_;
	}
   ```    
  - 투표가능 여부 (투표 가능한 사람 + 가능한 기간) 확인하는 modifier
    ```Solidity
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
    ```
  -  이미 투표한 사람인지 확인하는 modifier
    ```Solidity
	modifier alreadyVoted() {
		require(
			votes[msg.sender].vote >= 0,
			"msg sender already voted"
		);
		_;
	}
    ```    
 -  투표 종료시, 결과를 contract에 저장하는 modifier
    ```Solidity
	modifier announceResult() {
		require(
			now > endTime,
			"The vote is not ended."
		);
		if(electedProposal.voteCount >= 0){
			uint voteCount = 0;
			uint electedIndex = 0; // 투표가 모두 0이면 제일 먼저 등록한 메뉴로 선정 (선착순)
			for (uint i = 0; i < proposals.length; i++) {
				if (proposals[i].voteCount > voteCount) {
					voteCount = proposals[i].voteCount;
					electedIndex = i;
				}
			}
			electedProposal = proposals[electedIndex];
			BadgemealNFT(badgeNFTAddress).addElectedProposal(electedProposal.menu, electedProposal.proposer, electedProposal.voteCount, address(this));
		}
		_;
	}
    ```    

3.  vote contract에 필요한 function
 -  메뉴를 제안하는 function
    ```Solidity
	function proposeMenu(string memory _menu) checkVoteAvailable public{
		proposals.push(Proposal({
		menu: _menu,
		voteCount: 0,
		proposer: msg.sender
		}));
	}
    ```    
 -  제안된 메뉴 목록을 조회하는 function
    ```Solidity
	function proposedMenuList() public view returns(string) {
		string memory result = proposals[0].menu;
		for(uint i = 1; i < proposals.length; i++){
			string memory temp = string(abi.encodePacked(", ", proposals[i].menu));
			result = string(abi.encodePacked(result, temp));
		}
		return result;
	}
    ```    
 -  메뉴를 투표하는 function
    ```Solidity
	function vote(uint proposalIndex) checkVoteAvailable alreadyVoted public{
		votes[msg.sender] = Vote({
		vote: proposalIndex
		});

		votes[msg.sender].vote = proposalIndex;
		proposals[proposalIndex].voteCount++;
	}
    ```    
 -  채택된 메뉴의 정보를 조회하는 function
    ```Solidity
	// 가장 많은 득표수를 얻은 메뉴 이름을 리턴
	function getElectedMenuName() announceResult public returns (string memory electedMenuName_) {
		electedMenuName_ = electedProposal.menu;
	}
	// 가장 많은 득표수를 얻은 메뉴의 득표수를 리턴
	function getElectedMenuVoteCount() announceResult public returns (uint  electedMenuVoteCount_) {
		electedMenuVoteCount_ = electedProposal.voteCount;
	}
	// 가장 많은 득표수를 얻은 메뉴의 제안자 address를 리턴
	function getElectedMenuVoterAddress() announceResult public returns (address  electedMenuVoterAddress_) {
		electedMenuVoterAddress_ = electedProposal.proposer;
	}
    ``` 
