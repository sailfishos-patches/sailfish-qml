import QtQuick 2.5
import Sailfish.Silica 1.0
import Sailfish.Gallery 1.0
import QtMultimedia 5.4
import QtDocGallery 5.0
import org.nemomobile.ngf 1.0
import org.nemomobile.dbus 2.0
import org.nemomobile.policy 1.0
import org.nemomobile.thumbnailer 1.0

ApplicationWindow {
    cover: null  // don't create a cover - the switcher will try to show it
    VideoOutput { }

    BackgroundItem { }
    Button { }
    SilicaFlickable {
        PullDownMenu { } // creates HighlightFeedback.qml and initializes sampleCache
    }
    Label { }
    PageHeader { }
    Slider { }
    Switch { }

    Component {
        // These will be compiled but not instantiated.
        // If instantiation won't result in further caching then place those
        // components here.
        Item {
            Camera {}
            ImageViewer {}
            Thumbnail {}
            DocumentGalleryModel {}

            AddAnimation { }
            BusyIndicator { }
            ColumnView { }
            ComboBox { }
            ContextMenu { }
            CoverBackground { }
            CoverPlaceholder { }
            DatePicker { }
            Dialog {
                DialogHeader { }
            }
            DockedPanel { }
            Drawer { }
            IconButton { }
            SilicaListView {
                ScrollDecorator { }
                PushUpMenu { }
                ListItem { }
            }
            SilicaGridView { }
            MenuItem { }
            Page { }
            RemorseItem { }
            RemorsePopup { }
            SearchField { }
            SectionHeader { }
            SilicaGridView { }
            OpacityRampEffect { }
            TextArea { }
            TextField { }
            TextSwitch { }
            ValueButton { }
            ViewPlaceholder { }
            InteractionHintLabel {}
            TouchInteractionHint {}
            FirstTimeUseCounter {}
        }
    }
}
