# BadgeMeal Smart Contract


## KIP17NFTContract

 

### 기존 KIP17Token.sol 파일에 추가 및 변경

1. KIP17Burnable contract 권한 수정
-	~~기존 소유자가 지울수 있는 권한에서 발행자만 지울 수 있게 변경~~
- 기존 KIP17Token으로 수정    

2. 함수 추가
#### Ownable, TokenLevel 추가
- [수빈님 코드 참조](https://github.com/BadgeMeal/badgemeal-contract/tree/subin#:~:text=KIP17Metadata%20%EC%BB%A8%ED%8A%B8%EB%9E%99%ED%8A%B8%20%EC%88%98%EC%A0%95%20%EC%82%AC%ED%95%AD, "링크")
- level -> nftType 변경(1 : 일반 nft, 2 : 마스터 nft)
- menuType 추가 (string 형식) : menuType, _setMenuType 추가, 기존 _burn함수에 menuType삭제 추가
```sol
mapping(uint256 => string) private _menuType;

function menuType(uint256 tokenId) external view returns (string memory) {
    require(
        _exists(tokenId),
        "KIP17Metadata: URI query for nonexistent token"
    );
    return _menuType[tokenId];
}
function _setMenuType(uint256 tokenId, string memory menuType) internal{
    require(_exists(tokenId), "KIP17Metadata: URI set of nonexistent token");
    _menuType[tokenId] = menuType;
}

function _burn(address owner, uint256 tokenId) internal {
        
    super._burn(owner, tokenId);
    // Clear metadata (if any)
    if (bytes(_tokenURIs[tokenId]).length != 0) {
        delete _tokenURIs[tokenId];
    }
    if (_nftType[tokenId] > 0) {
        delete _nftType[tokenId];
    }
    if (bytes(_menuType[tokenId]).length != 0){
        delete _menuType[tokenId];
    }
        
}
```
#### mintWithTokenURI : NFT 발행
- [mint함수명 원복](https://github.com/BadgeMeal/badgemeal-contract/pull/3#discussion_r806472363, "review01")
- ~~level 추가(마스터, 구체적인 메뉴 구분을 위한 레벨)~~
- level -> nftType 변경, menuType 추가
```sol
  function mintWithTokenURI(
        address to,
        uint256 tokenId,
        string memory tokenURI,
        uint nftType,
        string memory menuType
    ) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _setNftType(tokenId, nftType);
        _setMenuType(tokenId, menuType);
        return true;
    }
```  

***
 #### mintWithKlay : NFT 발행(수수료0.5Klay)
- ~~level 추가(마스터, 구체적인 메뉴 구분을 위한 레벨)~~
- owner address를 불러와 시도를 해볼려고 했지만 payable가 제대로 안되어서 우선은 기존처럼 해놓았습니다.
- level -> nftType 변경, menuType 추가
```sol  
function mintWithKlay(
        address to,
        uint256 tokenId,
        string memory tokenURI,
        uint nftType,
        string memory menuType,
        address payable reciver
    ) public payable returns (bool) {
        // reciver = Ownable(NFT).owner();
        reciver.transfer(10**17*5);
        mintWithTokenURI(to,tokenId, tokenURI,nftType, menuType);
        return true;
    }
``` 
	
***
#### mintMasterBadge : 마스터 뱃지 발행
- [특정메뉴 20개 이상 소유 확인](https://github.com/BadgeMeal/badgemeal-contract/pull/3#discussion_r805961010, "review2")
- [userList 초기화](https://github.com/BadgeMeal/badgemeal-contract/pull/3#discussion_r806795345, "review3")
- ~~level기준으로 메뉴 갯수 확인 및 삭제 기능 보완~~
- menuType기준으로 마스터 NFT 메뉴명 등록 및 기존 일반NFT 삭제
- 메뉴 삭제시 중간에 다른 메뉴 타입이 있는경우 안지워지는 버그 수정
```sol
//마스터 뱃지 mint
    function mintMasterBadge(
        address to,
        uint256 tokenId,
        string memory tokenURI,
        uint nftType,
        string memory menuType,
        address NFT
    ) public returns (bool){
        uint256 userBalance;
        userBalance = balanceOf(to);
        
        _listOfUserToeknId(userBalance, to, NFT);

        //특정 NFT(국밥 마스터 뱃지 인지)가 20개 이상 소유한지 판별
        require(_checkMenu(menuType, userBalance) >= 20, "You must have menu20NFTs");
        _removeOwnToken(to, menuType);
        mintWithTokenURI(to,tokenId, tokenURI,nftType,menuType);
        return true;
    }

    //소유한 특정메뉴 갯수 확인
    function _checkMenu(string memory menuType, uint256 balance) private returns(uint256){
        uint256 result = 0;
        for (uint256 i =0 ; i< balance; i++){
            if(_ownNftType(_userid[i], menuType)){
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
    function _removeOwnToken(address to, string memory menuType) private{
        uint256 count =0;
        //유저가 가지고 있는 기존 NFT 삭제(20개 이상을 소유할 수도 있으니 20개만 삭제)
        for (uint256 i = 0; i < _userid.length; i++) {
            bool isSucess = _burnForMasterNFT(to, _userid[i],menuType);
            if(isSucess)
            {
                count ++;
            }
            if(count ==20)
            {
                break;
            }
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