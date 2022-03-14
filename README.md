# BadgeMeal Smart Contract

## KIP17 컨트랙트 수정 사항

### KIP17Metadata Contract

- nftType, menuType mapping 추가
```sol
//mapping for nftType (1: general NFT, 2: master NFT)
mapping(uint256 => uint) private _nftType;

//mapping for menuType
mapping(uint256 => string) private _menuType;
```

- nftType, menuType getter 함수 추가

```sol
function nftType(uint256 tokenId) external view returns (uint) {
    require(_exists(tokenId), "KIP17Metadata: NFT type query for nonexistent token");
    return _nftType[tokenId];
}

function menuType(uint256 tokenId) external view returns (string memory) {
    require(
        _exists(tokenId),
        "KIP17Metadata: Menu Type query for nonexistent token"
    );
    return _menuType[tokenId];
}
```

- nftType, menuType setter 함수 추가

```sol
function _setNftType(uint256 tokenId, uint nftType) internal {
    require(_exists(tokenId), "KIP17Metadata: NFT type set of nonexistent token");
    _nftType[tokenId] = nftType;
}

function _setMenuType(uint256 tokenId, string memory menuType) internal {
    require(_exists(tokenId), "KIP17Metadata: Menu Type set of nonexistent token");
    _menuType[tokenId] = menuType;
}
```

- _burn 함수에 nftType, menuType delete 코드 추가

```sol
function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

    // Clear metadata (if any)
    if (bytes(_tokenURIs[tokenId]).length != 0) {
        delete _tokenURIs[tokenId];
    }
    // Clear nftType (if any)
    if (_nftType[tokenId] > 0) {
        delete _nftType[tokenId];
    }
    // Clear _menuType (if any)
    if (bytes(_menuType[tokenId]).length != 0){
        delete _menuType[tokenId];
    }
}
```

- 마스터 NFT mint할 때 기존 일반 NFT 19개 burn 

```sol
  function _burnForMasterNFT(address owner, uint256 tokenId, string memory menuType) internal returns (bool){
      if(keccak256(abi.encodePacked(_menuType[tokenId])) == keccak256(abi.encodePacked(menuType))) {
          _burn(owner, tokenId);
          return true;
      } else {
          return false;
      }
  }
```

### KIP17MetadataMintable Contract

- badgemealMinter mapping, onlyBadgemealMinter modifier, minting 권한 부여 함수 추가

```sol
mapping (address => bool) badgemealMinter; 

event MintMasterNFT(string typeString);
event MintGeneralNFT(string typeString);

//badgemealMinter 인지 체크하는 modifier
modifier onlyBadgemealMinter(address acconut) {
    require(badgemealMinter[acconut] == true, "MinterRole: caller does not have the Minter role");
    _;
}

//유저에게 badgemealMinter 권한 부여
function addBadgemealMinter(address acconut) public onlyMinter {
    badgemealMinter[acconut] = true;
}

//유저의 badgemealMinter 권한 삭제
function removeBadgemealMinter(address acconut) public onlyMinter {
    badgemealMinter[acconut] = false;
}
```

- mintWithTokenURI 함수 수정 및 필요한 utils 함수 추가
  - `_checkMenu` 함수를 실행해서 true 이면 특정 NFT(ex: 국밥 NFT)를 19개 이상 소유했는지 판별해서, `_removeOwnToken` 함수로 19개를 삭제한 후 마스터 NFT 발행
  - 위 함수 결과 값이 false 이면 일반 NFT 발행

```sol
function mintWithTokenURI(
    address to,
    uint256 tokenId,
    string memory genralTokenURI,
    string memory masterTokenURI,
    string memory menuType
) public onlyBadgemealMinter(to) {
    require(bytes(masterTokenURI).length != 0, "No More Master NFT.");
    uint256 userBalance = balanceOf(to);

    //특정 NFT(ex: 국밥 NFT)를 19개 이상 소유했는지 판별해서 19개를 삭제한 후 마스터 NFT 발행
    if(_checkMenu(to, menuType, userBalance) >= 19) {
        _removeOwnToken(to, menuType);
        _mint(to, tokenId);
        _setTokenURI(tokenId, masterTokenURI);
        _setNftType(tokenId, 2);
        _setMenuType(tokenId, menuType);

        emit MintMasterNFT('MintMasterNFT');
    } else {
        _mint(to, tokenId);
        _setTokenURI(tokenId, genralTokenURI);
        _setNftType(tokenId, 1);
        _setMenuType(tokenId, menuType);

        emit MintGeneralNFT('MintGeneralNFT');
    }
}

//소유한 특정 메뉴 NFT 갯수 확인
function _checkMenu(address owner, string memory menuType, uint256 balance) private returns(uint256){
    uint256 result = 0;
    uint256[] memory owendAllTokenList = getOwnedTokens(owner);
    for (uint256 i = 0; i< balance; i++){
        if(_ownNftType(owendAllTokenList[i], menuType)){
            result++;
        }
    }
    return result;
}

//소유한 19개 메뉴 NFT burn
function _removeOwnToken(address to, string memory menuType) private{
    uint256 count = 0;
    uint256[] memory owendAllTokenList = getOwnedTokens(to);
    //유저가 가지고 있는 기존 NFT 19개 삭제
    for (uint256 i = 0; i < owendAllTokenList.length; i++) {
        bool isSucess = _burnForMasterNFT(to, owendAllTokenList[i], menuType);
        if(isSucess) {
            count ++;
        }
        if(count == 19) {
            break;
        }
    }
}
```

- mintWithKlay 함수 추가

```sol
function mintWithKlay(
    address to,
    uint256 tokenId,
    string memory genralTokenURI,
    string memory masterTokenURI,
    string memory menuType
) public payable {
    address payable receiver = address(uint160(owner()));
    receiver.transfer(10**17*5);

    mintWithTokenURI(to, tokenId, genralTokenURI, masterTokenURI, menuType);
}
```

#### 추후 보완 사항

- KIP 17 관련 표준 컨트랙트들을 수정한 것을 Klaytn17MintBadgemeal 컨트랙트 내부에서 다시 구현해놓으면 좋을 것 같다.

<br />

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