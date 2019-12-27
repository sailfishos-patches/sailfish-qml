// Copyright (C) 2015 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import com.jolla.keyboard 1.0
import Sailfish.Silica 1.0

// supports diacritic prefix on the key, only last character will be sent
CharacterKey {
    text: keyText.charAt(keyText.length-1)
    pixelSize: geometry.isLargeScreen ? Theme.fontSizeLarge
                                      : Theme.fontSizeLargeBase
}
