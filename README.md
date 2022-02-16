# BadgeMeal Smart Contract

## KIP17Metadata 컨트랙트 수정 사항

1. _tokenLevel 매핑 추가
일반 NFT와 마스터 NFT를 구분하기 위해 `_tokenLevel` 매핑을 추가해서 활용했다.

2. _setTokenLevel 함수 추가
`_setTokenLevel` 함수를 **KIP17MetadataMintable** 컨트랙트 내에서 사용한다.

3. _burn 함수에 _tokenLevel도 초기화 하는 매소드 추가
토큰을 삭제할 때 _tokenURIs와 함께 _tokenLevel도 삭제한다.
```sol
mapping(uint256 => uint) private _tokenLevel;

/**
  * @dev 🔥 Returns an level for a given token ID.
  * Throws if the token ID does not exist. May return an empty string.
  * @param tokenId uint256 ID of the token to query
  */
function tokenLevel(uint256 tokenId) public view returns (uint) {
    require(_exists(tokenId), "KIP17Metadata: URI query for nonexistent token");
    return _tokenLevel[tokenId];
}

/**
  * @dev 🔥 Internal function to set the token level for a given token.
  * Reverts if the token ID does not exist.
  * @param tokenId uint256 ID of the token to set its URI
  * @param level uint to assign
  */
function _setTokenLevel(uint256 tokenId, uint level) internal {
    require(_exists(tokenId), "KIP17Metadata: URI set of nonexistent token");
    _tokenLevel[tokenId] = level;
}

function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

    // Clear metadata (if any)
    if (bytes(_tokenURIs[tokenId]).length != 0) {
        delete _tokenURIs[tokenId];
    }
    
    // 🔥 Clear level 
    if (_tokenLevel[tokenId] > 0) {
        delete _tokenLevel[tokenId];
    }
}
```

## KIP17MetadataMintable 컨트랙트 수정 사항

1. mintWithTokenURI 파라미터에 `uint level`값을 추가했다.
2. mintWithTokenURI 함수 내에서 `_setTokenLevel(tokenId, level)` 함수를 호출하여 tokenId와 level을 매핑한다.

```sol
function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI, uint level) public onlyMinter returns (bool) {
    _mint(to, tokenId);
    _setTokenURI(tokenId, tokenURI);
    _setTokenLevel(tokenId, level);
}

```

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
  uint voteCount; // 투표 받은 수
  string imageUrl; // 메뉴 이미지 url
  address proposer; // 메뉴 제안자

}
struct Voter {
  bool voted;  // 투표 진행 여부 (true,false)
  uint vote;   // Menu 리스트 요소의 index (0,1,2 ...)
}
  
mapping(address => Voter) public voters; // 투표자 매핑

address[] internal votersAddressList; // 

Proposal[] public proposals; // 메뉴 리스트

Proposal[] public winnerProposals; // 투표로 채택된 메뉴 리스트
```

2. 공통으로 사용할 util 함수 선언
- isNFTholder : NFT 소유자인지 판단하는 함수
- isMasterNFTholder : 마스터 NFT 소유자인지 판단하는 함수
- params: 뱃지밀 NFT 컨트랙트 주소

```sol
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
function proposeMenu(string memory _name, address _nftAddress) public {
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
function vote(uint _proposal, address _nftAddress) public {
    require(isNFTholder(_nftAddress), "You have no right to vote");
    require(!voters[msg.sender].voted, "Already voted.");
          require(_proposal < proposals.length, "Wrong index.");

    voters[msg.sender].voted = true;
    voters[msg.sender].vote = _proposal;
          
          votersAddressList.push(msg.sender);
    proposals[_proposal].voteCount++;
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
event AddWinner(string indexed name, uint indexed voteCount, address proposer);
```
- ‼️보완해야할 사항 
  - 메뉴 제안자 베네핏 제공: NFT 메타데이터에 제안자의 주소 추가
  - 투표자에게 베네핏 제공: 메뉴 NFT 1개 랜덤 발행

```sol
function addWinnerProposal(address _nftAddress) public onlyOwner {
    Proposal storage winner = proposals[winningProposal()];
          require(winner.voteCount > (Klaytn17MintBadgemeal(_nftAddress).getOwnedTokens(msg.sender).length / 2), "The proposal did not win majority of the votes.");

    winnerProposals.push(winner);

    // event 발생
    emit AddWinner(winner.name, winner.voteCount, winner.proposer)

    // proposals 초기화
    delete proposals;
    // voters 초기화;
          for (uint256 i = 0; i < votersAddressList.length; i++) {
            voters[votersAddressList[i]].voted = false;
            voters[votersAddressList[i]].vote = 0;
    }
          delete votersAddressList;

}
```