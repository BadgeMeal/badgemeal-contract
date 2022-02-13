# BadgeMeal Smart Contract


## KIP17NFTContract

 

### 기존 KIP17Token.sol 파일에 추가 및 변경

1. KIP17Burnable contract 권한 수정
-	기존 소유자가 지울수 있는 권한에서 발행자만 지울 수 있게 변경    
```Solidity
function burn(uint256 tokenId)  public onlyMinter{

//solhint-disable-next-line max-line-length

// require(

// _isApprovedOrOwner(msg.sender, tokenId),

// "KIP17Burnable: caller is not owner nor approved"

// );

	_burn(tokenId);

}
```  

2. 함수 추가
#### mintNft : NFT 발행

 ```Solidity
function mintNft(

address to,

uint256 tokenId,

string  memory nftMetadata

)  public  returns  (bool)  {

	_mint(to, tokenId);

	_setTokenURI(tokenId, nftMetadata);

	return  true;

}
```  

***
 #### mintWithKlay : NFT 발행(수수료0.5Klay)
```Solidity
function mintNft(

address to,

uint256 tokenId,

string  memory nftMetadata

)  public  returns  (bool)  {

	_mint(to, tokenId);

	_setTokenURI(tokenId, nftMetadata);

	return  true;

}
```  
	
***
#### mintMasterBadge : 마스터 뱃지 발행
```Solidity
function mintMasterBadge(

address to,

uint256 tokenId,

string memory nftMetaData,

address NFT

) public returns (bool){

	uint256 userBalance;

	userBalance = balanceOf(to);

	//require(userBalance == 20, "You must have 20NFTs")

	_removeOwnToken(userBalance, to, NFT);

	//_burn(tokenId);

	mintNft(to,tokenId, nftMetaData);

	return true;

}
// 소유한 전체 NFT 삭제

function _removeOwnToken(uint256 balance, address to,address NFT) private{

	//유저가 가지고 있는 토큰id 리트스 확인
	for (uint256 i = 0; i < balance; i++) {

		uint256 id = KIP17Enumerable(NFT).tokenOfOwnerByIndex(to,i);

		userid.push(id);

	}
	//유저가 가지고 있는 기존 NFT 삭제
	for (uint256 i = 0; i < balance; i++) {

		_burn(userid[i]);

	}

}
```  
***
- 마스터 뱃지 발행 시 일반 nft와 마스터 nft 구분 필요