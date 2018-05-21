const gp = require("get-pixels")
const Colors = {
    "000000": {
        address: 0
    },
    "FFFFFF": {
        address: 1
    },
    "FF0000": {
        address: 2
    },
    "00FF00": {
        address: 3
    },
    "0000FF": {
        address: 4
    },
    "FFFF00": {
        address: 5
    },
    "00FFFF": {
        address: 6
    },
    "FF00FF": {
        address: 7
    },
    "C0C0C0": {
        address: 8
    },
    "808080": {
        address: 9
    },
    "800000": {
        address: 10
    },
    "808000": {
        address: 11
    },
    "008000": {
        address: 12
    },
    "800080": {
        address: 13
    },
    "008080": {
        address: 14
    },
    "000080": {
        address: 15
    },
};

async function getPixels(path) {
    return new Promise((resolve, reject) => {
        gp(path, (err, pixels) => {
            if (err) {
                console.log("bad image path");
                return reject("bad image path");
            }
            resolve(pixels);
        });
    });
}

async function main() {
    const pixels = await getPixels("enemy.png");
    // console.log(pixels);
    const depth = pixels.shape[2];
    const data = pixels.data;
    for(let i = 0; i < data.length; i+=4) {
        let address;
        if (data[i+3] > 0) {
            address = lookUpColorAddress(data[i], data[i+1], data[i+2]);
        } else {
            address = "808000";
        }
        console.log(`${i/4}\t:\t${address};`);
    }
}

function lookUpColorAddress(red, green, blue) {
    const hex_color = hexCheck(red.toString(16)) + hexCheck(green.toString(16)) + hexCheck(blue.toString(16));
    return hex_color.toUpperCase();
    // return Colors[hex_color.toUpperCase()].address;
}

function hexCheck(hex) {
    if (hex.length === 1) hex = "0" + hex;
    return hex;
}

if (require.main === module) {
    main();
}
