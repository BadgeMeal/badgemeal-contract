# BadgeMeal Smart Contract

## BadgemealNFT (임시 NFT 컨트랙트)

1. 필요한 구조체 및 변수 선언
```sol
struct Proposal {
  string name;   // 메뉴 이름
  string imageUrl; // 메뉴 이미지 url
  address proposer; // 메뉴 제안자
  address voteContract; // 투표 컨트랙트 address
}

address public owner; // 컨트랙트 소유자

mapping(address => bool) public nftHolders; // NFT 홀더 매핑 (홀더인지 확인용 boolean 값만 매핑)

Proposal[] public winnerProposals; // 투표로 채택된 메뉴 리스트
```

2. Owner 체크 함수 변경자
```sol
modifier onlyOwner() {
    require(
        msg.sender == owner,
        "msg sender is not a owner."
    );
    _;
}
```

3. NFT 홀더 체크 함수 (Public)
```sol
function isHolder(address _address) public view returns(bool) {
    return nftHolders[_address];
}
```

4. NFT 홀더 추가 함수
```sol
function addNFTHolder(address _address) private {
    require(
        !nftHolders[_address],
        "already added NFT Holder address."
    );

    nftHolders[_address] = true;
}
```

5. NFT 홀더 리스트 추가 함수 (Public)
```sol
function addNFTHolders(address[] memory _addresses) public onlyOwner {
    for (uint i = 0; i < _addresses.length; i++) {
        addNFTHolder(_addresses[i]);
    }
}
```

6. 투표에서 채택된 메뉴 추가 함수 (Public)
- params: 메뉴이름, 이미지url, 메뉴 제안자, 투표 컨트랙트 주소
- desc: 투표마다 컨트랙트가 따로 배포되어 주소가 params로 저장되면 히스토리 기능 및 투표결과에 투명성 부여 가능
```sol
function addWinnerProposal(string memory _name, string memory _imageUrl, address _proposer, address _voteContract) public onlyOwner {
    winnerProposals.push(Proposal({
    name: _name,
    imageUrl: _imageUrl,
    proposer: _proposer,
    voteContract: _voteContract
    }));
}
```


## Vote 컨트랙트

#### 요약 설명
- deployer -> owner 용어 변경
- require문에 컨트랙트 소유권자, 투표자 검증이 반복되어 함수변경자로 적용 (onlyOwner, onlyVoter)
- startTime, endTime 적용
  - 현재 시간이 start, end time 사이에 있을 때만 vote 함수 실행 가능 => voteOpen(함수변경자)
  - 그 외 함수는 투표 시작시간 전에 배포해놓고 투표자를 세팅할 수도 있으므로 시간 검증 제외
- 임시 BadgemealNFT 컨트랙트를 통해 voters 매핑에 추가 전 NFT 홀더인지 검증
- Vote Contract를 한번 배포해서 계속 쓰는 것이 아니라 투표 때마다 새로운 Vote Contract를 배포해서 사용 (투표 히스토리 관리, 투명성)
- 투표 종료 시간 체크는 백엔드에서 스케쥴러로 체크. 백엔드에서 winnerProposal 확인 후 DB에 저장하고  BadgemealNFT 컨트랙트에 addWinnerProposals 함수로 투표에서 채택된 메뉴를 추가
- 이미지 URL은 기본 메뉴 이미지를 베이스 이미지에 글자만 다르게 넣는 걸로 결정되었다고 기억해서 넣음.

1. 필요한 구조체 및 변수 선언
```sol
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
```

2. 생성자
- require: 시작시간이 종료시간보다 이전이어야 함.
- params: 투표 시작시간, 투표 종료시간 (unix time)
```sol
constructor(uint _startTime, uint _endTime) public {
    require(
        _startTime < _endTime,
        "start time needs to be lower than end time"
    );
    owner = msg.sender;
    startTime = _startTime;
    endTime = _endTime;
}
```

3. 공통 require문 -> 함수 변경자로 변경
- Owner 체크 함수 변경자
```sol
modifier onlyOwner() {
    require(
        msg.sender == owner,
        "msg sender is not a owner."
    );
    _;
}
```
- 투표자 체크 함수 변경자
  - desc: voters 구조체에서 exist값으로 투표자인지 아닌지를 체크 (솔리디티는 voters[_address]이 할당되지 않은 null일 경우 초기값으로(exist는 false) 뱉는 듯함.)
```sol
modifier onlyVoter() {
    require(
        isVoter(msg.sender),
        "msg sender is not a registered voter."
    );
    _;
}

function isVoter(address _address) public view returns(bool) {
    return voters[_address].exist;
}
```
- 투표 기간 유효 체크 함수 변경자
```sol
modifier voteOpen() {
    require(
        now >= startTime && now < endTime,
        "voting currently not open"
    );
    _;
}
```

4. 메뉴 추가 함수 (Public)
- require : 마스터 NFT 소유자
- params: 메뉴이름, 이미지url (베이스 이미지에 글자만 다르게 넣는 걸로 결정되었다고 기억해서 넣음)
```sol
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
```

5. 투표자 추가
5-1. 투표자 단일 추가 함수
- require : NFT 소유자, 투표자 매핑에 아직 등록되지 않은 주소
- params: 투표자 주소, 뱃지밀 NFT 컨트랙트 주소
- desc: 투표자로 추가하려한 대상 address를 error message에 출력함으로써 어떤 address가 문제인지 메시지를 통해 확인 가능
```sol
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
```
5-2. 투표자 리스트 추가 함수 (Public)
- require : Owner
- params: 투표자 주소 리스트, 뱃지밀 NFT 컨트랙트 주소
```sol
function addVoters(address[] memory _addresses, address nftAddress) public onlyOwner {
    for (uint i = 0; i < _addresses.length; i++) {
        addVoter(_addresses[i], nftAddress);
    }
}
```

6. 투표 함수
- require : 투표자 매핑에 등록된 자(onlyVoter), 투표 가능 기간(voteOpen), 아직 투표하지 않은 투표권자
- params: 메뉴 후보 리스트 내 인덱스
- ‼️보완해야할 사항 : params로 온 메뉴 인덱스가 메뉴 후보 리스트보다 크거나 작은 값으로 오면 무효표로 처리할지, 에러로 처리하고 다시 투표하게 할지를 결정해야 함.
```sol
function vote(uint proposal) public onlyVoter voteOpen {
    require(!voters[msg.sender].voted, "Already voted.");

    voters[msg.sender].voted = true;
    voters[msg.sender].vote = proposal;
    proposals[proposal].voteCount++;
}
```

7. 가장 많은 득표수 얻은 메뉴의 index 출력 함수
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

8. 가장 많은 득표수를 얻은 메뉴의 이름을 리턴하는 함수
```sol
function winnerName() public view returns (string memory winnerName_) {
    winnerName_ = proposals[winningProposal()].name;
}
```

9. util 함수
```sol
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
```