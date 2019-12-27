import QtQuick 2.0
import Sailfish.Silica 1.0

// These will be compiled but not instantiated.
// If instantiation won't result in further caching then place those
// components here.
Item {
    Component {
        // All components required by browser are only compiled so that memory footprint
        // of the browser booster is as minimal of possible.
        ApplicationWindow {
            cover: null  // don't create a cover - the switcher will try to show it
            BackgroundItem { }
            Label { }
            PageHeader { }
            Switch { }
            SearchField { }

            ContextMenu { }
            Dialog {
                DialogHeader { }
            }
            DockedPanel { }
            IconButton { }
            SilicaFlickable {
                PullDownMenu { } // creates HighlightFeedback.qml and initializes sampleCache
            }
            SilicaListView {
                ScrollDecorator { }
                PushUpMenu { }
                ListItem { }
            }
            SilicaGridView {}
            MenuItem { }
            Page { }
            RemorseItem { }
            RemorsePopup { }
            SearchField { }
            SectionHeader { }
            TextSwitch { }
            ViewPlaceholder { }
            InteractionHintLabel {}
            TouchInteractionHint {}
            FirstTimeUseCounter {}
        }
    }
}
