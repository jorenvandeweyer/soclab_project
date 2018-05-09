let last_empty = 0;
let address = 0;
let move = 0;
let clear = 0;
let clear_empty_spaces = 1;
let insert_value_in_array = 1;
let passed = 0;

let switch_value;

let array = [1, 0, 0, 2, 5, 0, 0, 7, 0];

let insert_value = 3;

while (true) {
    if (clear_empty_spaces) {
        if (clear) {
            clear = 0;
            array[address] = 0;
        } else if (array[address] !== 0 && move) {
            array[last_empty] = array[address];
            clear = 1;
            last_empty = last_empty + 1;
        } else if (array[address] === 0 && !move) {
            last_empty = address;
            move = 1;
            address = address + 1;
        } else {
            address = address + 1;
            passed = 1;
        }
        if (address === array.length) address = 0;
        if (address === 0 && passed) {
            passed = 0;
            clear_empty_spaces = 0;
        }
    } else if (insert_value_in_array){
        if (insert_value < array[address] || array[address] === 0) {
            switch_value = array[address] + 0;
            array[address] = insert_value;
            insert_value = switch_value + 0;
            address = address + 1;
            passed = 1;
        } else {
            passed = 1;
            address = address + 1;
        }

        if (address === array.length) address = 0;
        if (address === 0 && passed) {
            insert_value_in_array = 0;
            passed = 0;
        }

    } else {
        break;
    }
    console.log(array);

}
