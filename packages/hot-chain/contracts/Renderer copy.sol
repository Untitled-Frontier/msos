// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// Renderer + SVG.sol + Utils.sol from hot-chain-svg.
// Modified to fit the project.
// https://github.com/w1nt3r-eth/hot-chain-svg

import "./Words.sol";
import "./Definitions.sol";

contract Renderer {

    Words public words;
    Definitions public defs;

    constructor() {
        words = new Words();
        defs = new Definitions();
    }

    function render(uint256 _tokenId, bool randomMint) internal view returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(_tokenId));

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" style="background:#fff" xmlns:xlink="http://www.w3.org/1999/xlink">',
                //defs.defs(hash),
                //craftSand(hash),
                //cutOut(hash, randomMint),
                //capsuleOutline(),
                //defos(),
                flowers(hash),
                '</svg>'
            );
    }

    function defos(bytes memory hash, uint rotation) internal pure returns (string memory) {
        string memory patstr = pattern(hash);
        return string.concat('<filter id="blur">',
            patstr,
            '<feGaussianBlur stdDeviation="1"/>',
        '</filter>',
        '<filter id="room2">',
            patstr,
        '</filter>',
        '<filter id="satt">',
            patstr,
            '<feColorMatrix type="matrix" ',
            'values="0.2126 0.7152 0.0722 0 0 ',
              '0.2126 0.7152 0.0722 0 0 ',
              '0.2126 0.7152 0.0722 0 0 ',
              '0 0 0 1 0"/>',
        '<feComponentTransfer>',
          '<feFuncR type="discrete" tableValues="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1"/>',
          '<feFuncG type="discrete" tableValues="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1"/>',
          '<feFuncB type="discrete" tableValues="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1"/>',
        '</feComponentTransfer>',
        '</filter>',
        '<mask id="blurmask">',
            '<rect id="rr" x="150" y="150" width="500" height="500"/>',
            '<rect x="150" y="150" width="500" height="500" filter="url(#satt)" fill="white"/>',
            '<rect width="150" height="300" fill="black"/>',
            '<use transform="rotate(',utils.uint2str(rotation),', 150, 150)" xlink:href="#rr" fill="black"/>',
        '</mask>',
        '<mask id="m">',
            '<rect transform="rotate(',utils.uint2str(rotation),', 150, 150)" x="150" y="150" width="500" height="500" filter="url(#satt)"/>'

            //'<use transform="rotate(',utils.uint2str(rotation),', 150, 150)" xlink:href="#tap"/>',
            '<rect width="150" height="500" fill="black"/>',
            //'<rect transform="rotate(',utils.uint2str(rotation),' 150, 150)" width="500" height="150" fill="white"/>',
            '<rect width="500" height="150" fill="black"/>'
        '</mask>',
        '<defs>',
        '<rect id="tap" x="150" y="150" width="500" height="500" filter="url(#room2)"/>',
        '</defs>');
    }

    function pattern(bytes memory hash) internal pure returns (string memory) {
        string memory roomBF = generateBaseFrequency(hash, 3, 4, ['0.0', '0.00', '0.000']);
        string memory roomSeed = utils.uint2str(uint256(utils.toUint8(hash,8))*uint256(utils.toUint8(hash,9))*uint256(utils.toUint8(hash,10))); // 0 - 16581375

        return string.concat(
                svg.el('feTurbulence', string.concat(svg.prop('baseFrequency', roomBF),svg.prop('seed', roomSeed), svg.prop('result', 'turb'))),
                svg.el('feColorMatrix',string.concat(svg.prop('in', 'turb'), svg.prop('values', generateColorMatrix(hash)), svg.prop('out', 'turb2')))
        );
    }

    function generateColorMatrix(bytes memory hash) public pure returns (string memory) {
        string memory strMatrix;
        uint _tokenId = 0;

        for(uint i = 0; i<20; i+=1) {
            // re-uses entropy
            uint matrixOffset = uint256(utils.toUint8(hash, i))/4; // 0 - 64
            uint negOrPos = utils.toUint8(hash, i); // 0 - 255

            if(i == 18) {
                // the minimalism factor is defined by the alpha/alpha offset in the color matrix.
                // positive == changing to more colour
                // negative == taking colour away
                // the range is +64 -> -64 (128 digits)
                // max minimalism arrives at 1m mints.
                uint256 diff = generateMinimalismFactor(hash, i, _tokenId);

                // signed ints would've been better, but using unsigned<->string utils, so just manually adding pos/neg signs.
                string memory modStr;
                if (diff > 64) {
                   modStr = string.concat("-", utils.uint2str(diff-64), ' ');
                } else {
                   modStr = string.concat(utils.uint2str(64-diff), ' ');
                }

                strMatrix = string.concat(strMatrix, modStr); 

            } else if(i==4 || i == 9 || i== 14 || i == 19) {
                strMatrix = string.concat(strMatrix, '1 '); // end multiplier of channels (should be linear change, not multiplied)
            } else if(negOrPos < 128) { // random chance of adding or taking away colour (or alpha) from rgba
                strMatrix = string.concat(strMatrix, utils.uint2str(matrixOffset), ' ');
            } else {
                strMatrix = string.concat(strMatrix, '-', utils.uint2str(matrixOffset), ' ');
            }
        }
        return strMatrix;
    }

    /*
    A number in between 0 - 128, where 0 is most maximal. No attempt at minimalism.
    128 is the most minimal (given the constraints of the artist).

    It becomes more likely to produce a more minimal painting as it approaches 1 million.
    eg, at mint 1 -> minimalism factor is 0.
    at mint 1,000,000 -> minimalism factor could be between 0 - 128.
    */
    function generateMinimalismFactor(bytes memory hash, uint256 index, uint256 _tokenId) public pure returns (uint256) {
        uint256 rnr = uint256(utils.toUint8(hash, index))/2 + 1; // 1 - 128

        uint256 diff;
        if(_tokenId > 1000000) { 
            diff = rnr; 
        } else {
            diff = _tokenId*rnr/1000000;
        }

        return diff;
    }


    function generateBaseFrequency(bytes memory hash, uint256 index1, uint index2, string[3] memory decimalStrings) public pure returns (string memory) {
        string memory strNr = utils.uint2str(1 + uint256(utils.toUint8(hash,index1))*1000/256); // 1 - 997 (ish)
        uint256 dec = uint256(utils.toUint8(hash, index2))*3/256; // 0 - 2
        string memory bf = string.concat(decimalStrings[dec], strNr);
        return bf;
    }

    function tile(uint rotation, string memory opacity) internal pure returns (string memory) {
        return string.concat(

            //'<rect x="150" y="150" width="500" height="500" filter="url(#blur)" transform="rotate(',utils.uint2str(rotation+1),', 150, 150)" mask="url(#blurmask)"/>',
            '',
            '<use xlink:href="#tap" transform="rotate(',utils.uint2str(rotation+1),', 150, 150)" mask="url(#m)"/>'
            );
    }

    function flowers(bytes memory hash) internal pure returns (string memory) {
        uint petalCount = 36; // 360 + 2
        uint rotation = 360/petalCount;
        string memory defins = "";
        string memory petals = "";
        string memory tiledBack = "";

        defins = defos(hash, rotation);

        //for(uint i = 0; i<petalCount*2; i+=1) {
        for(uint i = 0; i<petalCount; i+=1) {
            //if(i%2 == 0) {
                //uint opacityNr = 99-100/petalCount*i;
                //string memory opacity = string.concat('0.', utils.uint2str(opacityNr));
                string memory opacity = "";

                tiledBack = string.concat(tiledBack, tile(rotation*(i+1), opacity));
                petals = string.concat(petals, petal(rotation*(i+1)));
            //}
        }

        return string.concat(defins, tiledBack, petals);
    }

    function petal(uint rotation) internal pure returns (string memory) {
        return string.concat(
            '<polygon points="130,150 150,130 170,150" fill="black" stroke="black" transform="rotate(',
            utils.uint2str(rotation),
            ', 150, 150)"/>'
        );
    }

    /* RE-USABLE SHAPES */
    function sandRect(string memory y, string memory h, string memory fill, string memory opacity) internal pure returns (string memory) {
        return svg.rect(
            string.concat(
                svg.prop('width', '300'),
                svg.prop('y',y),
                svg.prop('height',h),
                svg.prop('fill',fill),
                svg.prop('stroke','black'),
                svg.prop('filter','url(#sandFilter)'),
                svg.prop('opacity', opacity)
            )
        );        
    }

    /* CONSTRUCTIONS */
    function craftSand(bytes memory hash) internal pure returns (string memory) {
        string memory sandRects = '<rect width="100%" height="100%" filter="url(#fineSandFilter)"/> '; // background/fine sand

        uint amount = utils.getAmount(hash); // 2 - 18
        uint range = utils.getRange(hash);
        uint height; // = 0
        uint y; // = 0
        uint shift = 3;
        uint colour =  utils.getColour(hash);// 0 - 360
        uint cShift = utils.getColourShift(hash); // 0 - 255
        string memory opacity = "1";
        for (uint i = 1; i <= amount; i+=1) {
            y+=height;
            if(i % 2 == 0) {
                height = range*shift/2 >> shift;
                shift += 1;
            }
            opacity = "1";
            if ((y+colour) % 5 == 0) { opacity = "0"; }
            sandRects = string.concat(
                sandRects,
                sandRect(utils.uint2str(y), utils.uint2str(height), string.concat('hsl(',utils.uint2str(colour),',70%,50%)'), opacity)
            );
            colour+=cShift;
        }

        return sandRects;
    }

    function capsuleOutline() internal pure returns (string memory) {
        return string.concat(
            // top half of capsule
            svg.rect(string.concat(svg.prop('x', '111'), svg.prop('y', '50'), svg.prop('width', '78'), svg.prop('height', '150'), svg.prop('ry', '40'), svg.prop('rx', '40'), svg.prop('mask', 'url(#cutoutMask)'), svg.prop('clip-path', 'url(#clipBottom)'))),
            // bottom half of capsule
            svg.rect(string.concat(svg.prop('x', '113'), svg.prop('y', '50'), svg.prop('width', '74'), svg.prop('height', '205'), svg.prop('ry', '35'), svg.prop('rx', '50'), svg.prop('mask', 'url(#cutoutMask)'))),
            // crossbar of capsule 
            svg.rect(string.concat(svg.prop('x', '111'), svg.prop('y', '150'), svg.prop('width', '78'), svg.prop('height', '4'))),
            // top reflection
            svg.rect(string.concat(svg.prop('x', '115'), svg.prop('y', '45'), svg.prop('width', '70'), svg.prop('height', '40'), svg.prop('ry', '100'), svg.prop('rx', '10'), svg.prop('fill', 'white'), svg.prop('opacity', '0.4'), svg.prop('mask', 'url(#topReflectionMask)'))),
            // long reflection
            svg.rect(string.concat(svg.prop('x', '122'), svg.prop('y', '55'), svg.prop('width', '56'), svg.prop('height', '184'), svg.prop('ry', '30'), svg.prop('rx', '30'), svg.prop('fill', 'white'), svg.prop('opacity', '0.4'))),
            // drop shadow
            svg.rect(string.concat(svg.prop('x', '115'), svg.prop('y', '180'), svg.prop('width', '70'), svg.prop('height', '70'), svg.prop('ry', '30'), svg.prop('rx', '30'), svg.prop('filter', 'url(#dropShadowFilter)'), svg.prop('clip-path', 'url(#clipShadow)')))
        );
    }

    function cutOut(bytes memory hash, bool randomMint) internal view returns (string memory) {
        return svg.el('g', svg.prop('mask', 'url(#cutoutMask)'),
            string.concat(
                svg.whiteRect(),
                words.whatIveDone(hash, randomMint)
            )
        );
    }

    function generateName(uint nr) public pure returns (string memory) {
        return string(abi.encodePacked('Capsule #', utils.substring(utils.uint2str(nr),0,8)));
    }
    
    function generateTraits(uint256 tokenId, bool randomMint) public view returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        (uint256 rareCount, uint256 allCount, uint256[3][10] memory indices) = utils.getIndices(hash, randomMint);

        string memory nrOfWordsTrait = createTrait("Total Experiences", utils.uint2str(allCount));
        string memory nrOfRareWordsTrait = createTrait("Rare Experiences", utils.uint2str(rareCount));
        string memory slots;
        string memory typeOfMint;
        
        if(randomMint) {
            typeOfMint = createTrait("Type of Mint", "Random");
        } else {
            typeOfMint = createTrait("Type of Mint", "Chosen Seed");
        }

        for(uint i; i < 10; i+=1) {
            if(indices[i][0] == 1) { // slot is assigned or not
                string memory slotPosition = string.concat("Slot ", utils.uint2str(i));
                string memory action;
                if(indices[i][1] == 1) { // there's a rare word there or not
                    action = words.rareActions(indices[i][2]);
                } else {
                    action = words.actions(indices[i][2]);
                }

                slots = string.concat(slots, ",", createTrait(slotPosition, action));
            }
        }

        return string(abi.encodePacked(
            '"attributes": [',
            nrOfWordsTrait,
            ",",
            nrOfRareWordsTrait,
            ",",
            typeOfMint,
            slots,
            ']'
        ));
    }

    function createTrait(string memory traitType, string memory traitValue) internal pure returns (string memory) {
        return string.concat(
            '{"trait_type": "',
            traitType,
            '", "value": "',
            traitValue,
            '"}'
        );
    }

    function generateImage(uint256 tokenId, bool randomMint) public view returns (string memory) {
        return render(tokenId, randomMint);
    } 

    /* HELPERS */

    // hot-chain-svg calls this to render an example image
    // gasleft() is a hack to get a random nr. The call varies the gas being sent.
    function example() external view returns (string memory) {
        uint256 rnr = uint(keccak256(abi.encodePacked(uint256(gasleft()))));
        //uint256 timestamp = uint(keccak256(abi.encodePacked(uint256(1000011113511))));
        return render(rnr, true);
    }
}