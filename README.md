# ERC2048
Inspired by [ERC404](https://github.com/Pandora-Labs-Org/erc404), ERC2048 is an experimental, mixed ERC20 / ERC721 implementation with native liquidity and fractionalization.

![](./assets/protocol.jpg)
## Compared to ERC404
In ERC404, there is a 1:1 mapping between FT and NFT. This caused two challenging issues:

1. When transferring a large amount of FTs, the number of minting and burning is equal to the token amount, that costs too much gas. In the initial version of ERC404 protocol, it trys to use whitelist to make it possible for transferring large amount, but it proved ineffective.
2. With the 1:1 mapping between FTs and NFTs, different rarities of NFTs lose their value. Even if a red Pandora NFT has a higher rarity compared to a green one, they are both worth 1 Pandora.

Inspired by the [2048 game](https://en.wikipedia.org/wiki/2048_(video_game)), in the ERC2048 protocol, we introduce the concept of "level" for NFTs. Similar to the game, when you collect two NFTs with the same level, they automatically merge into a higher level NFT! Let's provide some examples:

1. Alice purchases a level(0) NFT, which also means she receives 1 FT.
2. Alice buys 1 FT, which also means she receives a level(0) NFT. Since she already owns a level(0) NFT, these two level(0) NFTs will merge into a level(1) NFT.

We can observe that in ERC2048 protocol, a level n NFT represents 2 to the power of n FT. (1 level(n) NFT = 2^n FT). Therefore, when transferring n FTs, the max number of NFTs to be handled is `Math.floor(Math.log2(n))`, this enables the possibility of handling large token transfers.

ERC2048 is entirely experimental and unaudited, while testing has been conducted in an effort to ensure execution is as accurate as possible.

## ERC721 Notes
In ERC2048, the implementation of ERC721 `transferFrom` uses BURN and MINT to finish transfer. That means when you transfer a Level(0) NFT, you will burn this NFT, meanwhile it will mint a Level(0) NFT for the receiver. So we didn't implement `safeTransferFrom` method.

## Licensing
This software is released under the MIT License.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
