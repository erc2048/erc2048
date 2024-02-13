# ERC2048

Inspired by [ERC404](https://github.com/Pandora-Labs-Org/erc404), ERC2048 is an experimental, mixed ERC20 / ERC721 implementation with native liquidity and fractionalization.

In ERC404, there is a 1:1 mapping between fungible tokens (FT) and non-fungible tokens (NFT). This caused two challenging issues when using the ERC404 protocol:

1. When transferring a large amount of FTs, the times of minting and burning NFTs equal to the token amount, it'll cost too much Gas. In the initial version of ERC404 code, it try to use whitelist to make it possible to transfer large amount, but it proved ineffective and caused a bug.
2. With the 1:1 mapping between NFTs and FTs, different rarities of NFTs lose their value. Even if a green Pandora box has a lower rarity compared to a red Pandora box, they are both equal to 1 Pandora.

Inspired by the [2048 game](https://en.wikipedia.org/wiki/2048_(video_game)), in the ERC2048 protocol, we introduce the concept of "Level" for NFTs. Similar to the game, when you collect two NFTs of the same Level, they automatically upgrade to a higher Level NFT! Let's provide some examples:

1. Alice purchases a Level(0) NFT, which also means she receives 1 FT.
2. Alice buys 1 FT, which also means she acquires a Level(0) NFT. Since she already owns a Level(0) NFT, these two Level(0) NFTs will merge into a Level(1) NFT.
3. When Bob purchases the Level(1) NFT from Alice, it is equivalent to buying 2 FT.

We can observe that in the ERC2048 protocol, the number of FTs is equal to 2 raised to the power of the Level (1 Level(n) NFT = 2^n FT). Therefore, when transferring n FTs, the number of NFTs to be handled is Floor(Log2(n)). This enables the possibility of handling large token transfers.

This standard is entirely experimental and unaudited, while testing has been conducted in an effort to ensure execution is as accurate as possible. The nature of overlapping standards, however, does imply that integrating protocols will not fully understand their mixed function.

## ERC721 Notes

In ERC2048, the implementation of `transferFrom` is burned and minted to finish transfer. That's means when you transfer a Level(0) NFT, you will burn this NFT, meanwhile it will mint a Level(0) NFT for the receiver. So we didn't implementation `safeTransferFrom` method.

## Licensing

This software is released under the MIT License.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
