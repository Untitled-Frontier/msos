// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// Renderer + SVG.sol + Utils.sol from hot-chain-svg.
// Modified to fit the project.
// https://github.com/w1nt3r-eth/hot-chain-svg

/*
Partly inspired by Zond's Flowers by onchainCo: https://opensea.io/collection/flowersonchain
*/
import './svg.sol';
import './utils.sol';

contract TestDescriptorChange {

    function render(uint256 _tokenId, bool deluxe) internal pure returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(_tokenId));

        // different petal counts: 8, 12, 20, 24, 36
        uint petalCount = utils.getPetalCount(hash); 
        uint rotation = 360/petalCount;

        string memory animation = "";

        if(deluxe == true) {
            animation = '<style>#entire {transform-origin: 150px 150px;animation: rotate 80s linear infinite; }@keyframes rotate {from {transform: rotate(0deg);}to {transform: rotate(360deg);}</style>';
        }

        return string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" style="background:#fff" xmlns:xlink="http://www.w3.org/1999/xlink">',
                animation,
                filtersPathsAndMasks(hash),
                '<g id="entire">',
                reusables(hash, petalCount, rotation),
                '<use xlink:href="#flower" clip-path="url(#halfClip)" transform="rotate(0, 150, 150)"/>',
                '<use xlink:href="#flower" clip-path="url(#halfClip)" transform="rotate(180, 150, 150)"/>',
                '</g>',
                '</svg>'
            );
    }

    function filtersPathsAndMasks(bytes memory hash) internal pure returns (string memory) {
        string memory patstrMaximal = outerPetalPattern(hash, true);
        string memory patstrMinimal = outerPetalPattern(hash, false);
        uint height = utils.getHeight(hash); //  180 - 52
        string memory adjustment = utils.uint2str(150+height);

        // 8, 12, 20, 24, 36
        return string.concat('<filter id="blur">',
            patstrMaximal,
            '<feGaussianBlur stdDeviation="1"/>',
            '</filter>',
            '<filter id="sharp">',
            patstrMinimal,
            '</filter>',
            '<clipPath id="blurClip">',
            '<rect x="150" y="150" width="300" height="300"/>',
            '</clipPath>',
            '<clipPath id="patternClip">',
            '<path d="M 150 150 L ',adjustment,' 150 Q ',adjustment,' ',adjustment,' 150 ',adjustment,' Z"/>'
            '</clipPath>',
            '<clipPath id="halfClip">',
            '<rect transform="rotate(1, 150, 150)" width="260" height="610" x="-110" y="-110"/>',
            '</clipPath>'
        );
    }

    function outerPetalPattern(bytes memory hash, bool maximalist) internal pure returns (string memory) {
        // latter 0.0 isn't strictly necessary, but keeping it in for vestigial reasons
        string memory oppBF = generateBaseFrequency(hash, ['0.0', '0.00', '0.00'], ['0.0', '0.0', '0.0']);
        string memory oppSeed = utils.uint2str(utils.getSeed(hash)); // 0 - 16581375

        return string.concat(
                svg.el('feTurbulence', string.concat(svg.prop('baseFrequency', oppBF),svg.prop('seed', oppSeed), svg.prop('result', 'turb'))),
                svg.el('feColorMatrix',string.concat(svg.prop('in', 'turb'), svg.prop('values', generateColorMatrix(hash, maximalist)), svg.prop('out', 'turb2')))
        );
    }

    /* 
    Generates the base frequency parameter for the perlin noise.
    */
    function generateBaseFrequency(bytes memory hash, string[3] memory decimalStrings, string[3] memory decimalStrings2) public pure returns (string memory) {
        string memory strNr = utils.uint2str(utils.getBaseFrequencyOne(hash)); // 1 - 997 (ish)
        uint256 dec = utils.getDecimalsOne(hash); // 0 - 2

        string memory strNr2 = utils.uint2str(utils.getBaseFrequencyTwo(hash)); // 1 - 997 (ish)
        uint256 dec2 = utils.getDecimalsTwo(hash); // 0 - 2

        string memory bf = string.concat(decimalStrings[dec], strNr,' ',decimalStrings2[dec2], strNr2);
        return bf;
    }

    /*
    An algorithm to generate the modification of the perlin noise to stronger colours
    */
    function generateColorMatrix(bytes memory hash, bool maximalist) public pure returns (string memory) {
        string memory strMatrix;

        for(uint i = 0; i<20; i+=1) {
            // re-uses entropy
            // note: using i+1 does create *some* default tendency, but shouldn't be significant.
            uint matrixOffset = utils.getMatrixOffset(hash, i); // 0 - 64
            uint negOrPos = utils.getNegOrPos(hash, i+1); // 0 - 255

            if(i == 18) { // Alpha modified by itself. Adds more of everything or less of everything.
                // note: code borrowed from room of infinite paintings
                // in general: higher -> brighter colours. lower -> darker colours
                // string memory modStr = string.concat("-", utils.uint2str(1), ' ');
                // string memory modStr = string.concat("-", utils.uint2str(1), ' ');
                strMatrix = string.concat(strMatrix, '0 '); 
            } else if(i == 19) { 
                // final channel is the shift of the alpha channel
                // making it mildly brighter ensure *some* color
                strMatrix = string.concat(strMatrix, '1 ');
            } else if(i==4 || i == 9 || i== 14) { 
                // shifts for RGB
                if(maximalist == true) {
                    // shifting makes the entire channel linearly stronger or weaker AFTER it's been modified from its underlying components.
                    // eg modify randomly and THEN add more (or less) of the channel to the pixel in general.
                    // if the shift is zero, it keeps each channel equal essentially. ensures more varied colours.
                    // thus, for background blur, it's better and more maximalist.
                    strMatrix = string.concat(strMatrix, '0 '); // no shifts
                } else {
                    // adding a mild shift causes the entire pixel to add more of that channel
                    // this comes at the expense of the other channels
                    // thus, adding shifts to each channel essentially takes away variedness, making it white.
                    // making it more minimal and sharp. 
                    // too strong a shift makes it too white and thus you can't see the blur.
                    strMatrix = string.concat(strMatrix, '1 '); // shifts 
                }
            } else if(negOrPos < 128) { 
                // random chance of adding or taking away colour (or alpha) from rgba
                strMatrix = string.concat(strMatrix, utils.uint2str(matrixOffset), ' ');
            } else {
                strMatrix = string.concat(strMatrix, '-', utils.uint2str(matrixOffset), ' ');
            }
        }
        return strMatrix;
    }

    function reusables(bytes memory hash, uint petalCount, uint rotation) internal pure returns (string memory) {
        string memory height = utils.uint2str(utils.getHeight(hash));
        uint midPointReduction = utils.getMidPointReduction(hash);
        uint endPointReduction = midPointReduction*2; // 0 - 36-ish

        string memory petals = generatePetals(hash, petalCount, rotation);

        string memory rs = string.concat('<defs>',
        '<rect id="tap" x="150" y="150" width="',height,'" height="',height,'" filter="url(#sharp)"/>',
        '<rect id="blurtap" x="150" y="150" width="500" height="500" filter="url(#blur)"/>',
        '<path id="ptl" d="M 150 150 Q ',utils.uint2str(150-midPointReduction),' ',utils.uint2str(150-endPointReduction),' 150 ',utils.uint2str(150-endPointReduction),' ',utils.uint2str(150+midPointReduction),' ',utils.uint2str(150-endPointReduction),' 150 150 Z" stroke="black"/>',
        '<g id="flower">', petals, '</g></defs>'
        );

        return rs;
    }

    function generatePetals(bytes memory hash, uint petalCount, uint rotation) internal pure returns (string memory) {
        string memory petals = "";
        string memory backPetals = "";
        string memory frontPetals = "";
        for(uint i = 0; i<petalCount; i+=1) {
            if(i < (petalCount/4*3)+2) { // 3/4 of the wheel.
                backPetals = string.concat(backPetals, backPetal(rotation*(i+1)));
                frontPetals = string.concat(frontPetals, frontPetal(hash, rotation*(i+1)+90));
            }
        }

        // add final two front petals
        // note: since it's cut off at half-way point, this is simpler than using clips or masks to ensure that petals are behind each other
        frontPetals = string.concat(frontPetals, frontPetal(hash, rotation*(petalCount+1)+90), frontPetal(hash, rotation*(petalCount+2)+90));

        petals = string.concat(backPetals, frontPetals);
        return petals;
    }

    function backPetal(uint rotation) internal pure returns (string memory) {
        return string.concat(
            '<use xlink:href="#blurtap" transform="rotate(',utils.uint2str(rotation+1),', 150, 150)" clip-path="url(#blurClip)"/>',
            '<use xlink:href="#tap" transform="rotate(',utils.uint2str(rotation+1),', 150, 150)" clip-path="url(#patternClip)"/>'
            );
    }

    function frontPetal(bytes memory hash, uint rotation) internal pure returns (string memory) {
        uint256 c = utils.getFrontPetalColour(hash);
        
        return string.concat(
            '<use xlink:href="#ptl" transform="rotate(',utils.uint2str(rotation+1),', 150, 150)" fill="hsl(',utils.uint2str(c),',100%,50%)" stroke="black"/>'
        );
    }

    function generateName(uint nr) public pure returns (string memory) {
        return string(abi.encodePacked('Daisychain #', utils.substring(utils.uint2str(nr),0,8)));
    }

    function generateDescription() public pure returns (string memory) {
        string memory description = "Testing Change of Descriptor";
        return description;
    }
    
    function generateTraits(uint256 tokenId, bool deluxe) public pure returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));

        string memory animatedTrait;
        
        if(deluxe == true) {
            animatedTrait = createTrait("Animated", "True");
        } else {
            animatedTrait = createTrait("Animated", "False");
        }

        uint256 petalCount = utils.getPetalCount(hash);

        string memory petalCountTrait = createTrait("Petal Count", utils.uint2str(petalCount));

        return string(abi.encodePacked(
            '"attributes": [',
            animatedTrait,
            ",",
            petalCountTrait,
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

    function generateImage(uint256 tokenId, bool deluxe) public view returns (string memory) {
        return render(tokenId, deluxe);
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