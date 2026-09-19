pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.modules.nexus

Item {
    id: root

    required property NexusState nState
    required property string searchQuery
    readonly property int topMargin: Tokens.padding.large
    readonly property int bottomMargin: Tokens.padding.large
    readonly property bool searching: searchQuery.trim().length > 0

    Loader {
        anchors.fill: parent
        sourceComponent: root.searching ? searchView : normalView
    }

    Component {
        id: normalView

        NavNormalView {
            nState: root.nState
        }
    }

    Component {
        id: searchView

        NavSearchView {
            nState: root.nState
            query: root.searchQuery
        }
    }
}
