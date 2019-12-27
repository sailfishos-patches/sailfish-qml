import QtQuick 2.1
import com.jolla.settings.system 1.0
import com.jolla.apkd 1.0

Item {
    height: textItem.height

    AboutText {
        id: textItem

        //: For about device page
        //% "Android is a trademark of Google Inc. The Android robot is reproduced or modified from work created "
        //% "and shared by Google and used according to terms described in the Creative Commons 3.0 Attribution License."
        text: qsTrId("apkd_settings-la-android_trademark_info")
    }
}
