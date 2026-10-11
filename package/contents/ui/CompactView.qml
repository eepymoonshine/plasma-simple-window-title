/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: compact

    readonly property string fontFamily: Plasmoid.configuration.panelFontFamily || Kirigami.Theme.defaultFont.family
    readonly property real fontSize: Plasmoid.configuration.panelFontSize > 0
        ? Plasmoid.configuration.panelFontSize : Kirigami.Theme.defaultFont.pointSize
    readonly property int fontWeight: Plasmoid.configuration.panelFontWeight || Font.Bold
    readonly property bool fontItalic: Plasmoid.configuration.panelFontItalic === true
    readonly property int iconSize: Plasmoid.configuration.iconSize > 0 ? Plasmoid.configuration.iconSize : Kirigami.Units.iconSizes.smallMedium
    readonly property int maxWidth: Plasmoid.configuration.maxWidth || 0   // 0 = no limit

    // No room for text on vertical panels
    readonly property bool showText: !root.isVertical && root.text !== ""
    // Always shown without text, so the widget doesn't vanish
    readonly property bool showIcon: Plasmoid.configuration.showIcon !== false || !showText

    Layout.minimumWidth: row.implicitWidth + Kirigami.Units.largeSpacing * 2
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth: Layout.minimumWidth
    Layout.minimumHeight: root.isVertical ? row.implicitHeight + Kirigami.Units.largeSpacing * 2 : Kirigami.Units.iconSizes.medium
    Layout.preferredHeight: root.isVertical ? Layout.minimumHeight : -1

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton) {
                if (root.activeTask && Plasmoid.configuration.middleClickClose !== false) root.close(root.activeTask)
            } else if (Plasmoid.configuration.doubleClickMaximize !== false) {
                // Wait to see if it's a double-click, so that doesn't also open the popup
                clickTimer.restart()
            } else {
                root.expanded = !root.expanded
            }
        }
        onDoubleClicked: function(mouse) {
            if (mouse.button !== Qt.LeftButton || Plasmoid.configuration.doubleClickMaximize === false) return
            clickTimer.stop()
            if (root.activeTask) root.toggleMaximized(root.activeTask)
        }

        // Scroll to switch windows. Touchpads send many small steps, so take one per pause
        property bool wheelBlocked: false
        onWheel: function(wheel) {
            if (Plasmoid.configuration.scrollSwitch === false || wheelBlocked) return
            var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : -wheel.angleDelta.x
            if (Math.abs(delta) < 10) return
            wheelBlocked = true
            wheelTimer.restart()
            root.cycle(delta < 0 ? 1 : -1)
        }
        Timer { id: wheelTimer; interval: 200; onTriggered: mouseArea.wheelBlocked = false }
    }

    Timer {
        id: clickTimer
        interval: Qt.styleHints.mouseDoubleClickInterval
        onTriggered: root.expanded = !root.expanded
    }

    GridLayout {
        id: row
        anchors.centerIn: parent
        flow: root.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: root.isVertical ? 1 : -1
        rows: root.isVertical ? -1 : 1
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: 0

        Kirigami.Icon {
            visible: compact.showIcon
            source: root.icon
            Layout.preferredWidth: compact.iconSize
            Layout.preferredHeight: compact.iconSize
            Layout.alignment: Qt.AlignCenter
        }

        PanelLabel {
            panel: compact
            visible: compact.showText
            Layout.alignment: Qt.AlignCenter
            Layout.maximumWidth: compact.maxWidth > 0 ? compact.maxWidth : Number.POSITIVE_INFINITY
            text: root.text
            elide: Text.ElideRight
            textFormat: Text.PlainText
            font.pointSize: compact.fontSize
            font.family: compact.fontFamily
            font.weight: compact.fontWeight
            font.italic: compact.fontItalic
        }
    }
}
