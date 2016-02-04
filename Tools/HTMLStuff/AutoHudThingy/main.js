window.onload = (function () {
    outputJSON = _outputJSON;
});

var _outputJSON = (function (inArea, outArea) {
    if (inArea.value == '') {
        outArea.value = 'Nothing in the input area.';
        return;
    }
    if (!validateJSON (inArea.value)) {
        outArea.value = 'Invalid JSON.';
        return;
    }

    data = JSON.parse (inArea.value);

    if (!data.hasOwnProperty ('weaponName')    ||
        !data.hasOwnProperty ('max')           ||
        !data.hasOwnProperty ('inventoryName') ||
        !data.hasOwnProperty ('graphicString') ||
        !data.hasOwnProperty ('initialX')      ||
        !data.hasOwnProperty ('xStep')         ||
        !data.hasOwnProperty ('y')) {
        outArea.value = 'Something\'s missing.';
        return;
    }
    weaponName = data.weaponName;
    max = data.max;
    inventoryName = data.inventoryName;
    graphicString = data.graphicString;
    initialX = data.initialX;
    xStep = data.xStep;
    y = data.y;

    str = 'isSelected ' + weaponName + ' {\n';

    yPos = 0;
    maxXPos = initialX + (xStep * max);
    for (i = 1; i <= max; i++) {
        xPos = initialX + ((i - 1) * xStep);

        iStr = '';
        xPosStr = '';
        for (j = 0; j < (max.toString ().length - i.toString ().length); j++) {
            iStr += ' ';
        }
        iStr += i;
        for (k = 0; k < (maxXPos.toString ().length - xPos.toString ().length); k++) {
            xPosStr += ' ';
        }
        xPosStr += xPos;
        
        str += '    inInventory ' + inventoryName + ', ' + iStr + ' { drawImage "' + graphicString + '", ' + xPosStr + ', ' + y [yPos] + '; }\n';
        if (y.length > 1) {
            yPos++;
            if (yPos >= y.length)
                yPos = 0;
        }
    }
    str += "}";

    outArea.value = str;
});

var outputJSON = (function () { });