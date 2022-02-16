# BadgeMeal Smart Contract


## KIP17NFTContract

 

### 기존 KIP17Token.sol 파일에 추가 및 변경

1. KIP17Burnable contract 권한 수정
-	~~기존 소유자가 지울수 있는 권한에서 발행자만 지울 수 있게 변경~~
- 기존 KIP17Token으로 수정    

2. 함수 추가
#### Ownable, TokenLevel 추가
- [수빈님 코드 참조](https://github.com/BadgeMeal/badgemeal-contract/tree/subin#:~:text=KIP17Metadata%20%EC%BB%A8%ED%8A%B8%EB%9E%99%ED%8A%B8%20%EC%88%98%EC%A0%95%20%EC%82%AC%ED%95%AD, "링크")
#### mintWithTokenURI : NFT 발행
- [mint함수명 원복](https://github.com/BadgeMeal/badgemeal-contract/pull/3#discussion_r806472363, "review01")
- level 추가(마스터, 구체적인 메뉴 구분을 위한 레벨)
```sol
  function mintWithTokenURI(
        address to,
        uint256 tokenId,
        string memory tokenURI,
        uint level
    ) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _setTokenLevel(tokenId, level);
        return true;
    }
```  

***
 #### mintWithKlay : NFT 발행(수수료0.5Klay)
- level 추가(마스터, 구체적인 메뉴 구분을 위한 레벨)
- owner address를 불러와 시도를 해볼려고 했지만 payable가 제대로 안되어서 우선은 기존처럼 해놓았습니다.
```sol  
//mint 유료, 0.5 klay 
function mintWithKlay(
        address to,
        uint256 tokenId,
        string memory tokenURI,
        uint level,
        address payable reciver
    ) public payable returns (bool) {
        // reciver = Ownable(NFT).owner();
        reciver.transfer(10**17*5);
        mintWithTokenURI(to,tokenId, tokenURI,level);
        return true;
    }
``` 
	
***
#### mintMasterBadge : 마스터 뱃지 발행
- [특정메뉴 20개 이상 소유 확인](https://github.com/BadgeMeal/badgemeal-contract/pull/3#discussion_r805961010, "review2")
- [userList 초기화](https://github.com/BadgeMeal/badgemeal-contract/pull/3#discussion_r806795345, "review3")
- level기준으로 메뉴 갯수 확인 및 삭제 기능 보완
```sol
//마스터 뱃지 mint (수정사항 : 마스터 뱃지레벨, 일반 뱃지(메뉴별 레벨)로 구분)
    function mintMasterBadge(
        address to,
        uint256 tokenId,
        string memory tokenURI,
        uint setLevel,
        uint delLevel,
        address NFT
    ) public returns (bool){
        uint256 userBalance;
        userBalance = balanceOf(to);
        
        _listOfUserToeknId(userBalance, to, NFT);

        //특정 NFT(국밥 마스터 뱃지 인지)가 20개 이상 소유한지 판별
        require(_checkMenu(delLevel, userBalance) >= 20, "You must have menu20NFTs");
        _removeOwnToken(to, delLevel);
        mintWithTokenURI(to,tokenId, tokenURI,setLevel);
        return true;
    }

    //소유한 특정메뉴 갯수 확인
    function _checkMenu(uint level, uint256 balance) private returns(uint256){
        uint256 result = 0;
        for (uint256 i =0 ; i< balance; i++){
            if(_ownTokenLevel(_userid[i], level)){
                result++;
            }
        }
        return result;
    }
    // 유저가 현재 소유한 전체 tokenId 리스트 생성
    function _listOfUserToeknId(uint256 balance, address to, address NFT) private
    {
        _useridInit();
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = KIP17Enumerable(NFT).tokenOfOwnerByIndex(to,i);
            _userid.push(id);
        }
    }
    // 소유한 20개의 메뉴 NFT 삭제
    function _removeOwnToken(address to, uint level) private{

        //유저가 가지고 있는 기존 NFT 삭제(20개 이상을 소유할 수도 있으니 20개만 삭제)
        for (uint256 i = 0; i < 20; i++) {
            _burnForMasterNFT(to, _userid[i],level);
        }
      
        _useridInit();
    }
    //_userid 초기화
    function _useridInit() private{
        for (uint256 i=0; i< _userid.length;i++){
            _userid.pop;
        }
        
    }

```  
***
- 현재 마스터 NFT와 일반 NFT는 level로 구분이 되는데 일반 NFT에서 메뉴끼리는 구별이 안되어 있습니다. 구별을 데이터에서 가져올지 안가져올지 확실하지 않아서 우선은 컨트랙트자체에서 해결할 수 있게 level에서 구분할수 있게 짜 놓았습니다.