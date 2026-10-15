/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

PlasmaExtras.Representation {
    id: full

    readonly property Item task: root.lastTask   // the window the actions apply to

    Layout.minimumWidth: Kirigami.Units.gridUnit * 19
    Layout.preferredWidth: Kirigami.Units.gridUnit * 19
    // Fit the content exactly, or Plasma's saved popup size can leave a gap at the bottom
    Layout.minimumHeight: implicitHeight
    Layout.preferredHeight: implicitHeight
    Layout.maximumHeight: implicitHeight
    spacing: Kirigami.Units.smallSpacing

    // Building blocks

    component SectionTitle: PlasmaComponents.Label {
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.2
        font.bold: true
        opacity: 0.55
    }

    component Card: KSvg.FrameSvgItem {
        default property alias content: inner.data
        Layout.fillWidth: true
        imagePath: "widgets/frame"
        prefix: "plain"
        implicitHeight: inner.implicitHeight + Kirigami.Units.mediumSpacing * 2

        ColumnLayout {
            id: inner
            anchors.fill: parent
            anchors.margins: Kirigami.Units.mediumSpacing
            spacing: Kirigami.Units.smallSpacing
        }
    }

    component Chip: KSvg.FrameSvgItem {
        property alias text: chipLabel.text
        Layout.preferredWidth: chipLabel.implicitWidth + Kirigami.Units.largeSpacing
        Layout.preferredHeight: chipLabel.implicitHeight + Kirigami.Units.smallSpacing
        imagePath: "widgets/viewitem"
        prefix: "selected"

        PlasmaComponents.Label {
            id: chipLabel
            anchors.centerIn: parent
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.bold: true
        }
    }

    component ActionButton: PlasmaComponents.ToolButton {
        property string tip
        display: QQC2.AbstractButton.IconOnly
        QQC2.ToolTip.text: tip
        QQC2.ToolTip.visible: hovered
    }

    readonly property real rowHeight: Kirigami.Units.gridUnit * 2.2
    readonly property int maxRows: 8

    // Layout

    header: PlasmaExtras.PlasmoidHeading {
        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "preferences-system-windows"
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }
            Kirigami.Heading {
                level: 1
                text: i18n("Windows")
            }
            Item { Layout.fillWidth: true }
            Chip { text: i18np("%1 open", "%1 open", windowList.count) }
        }
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        // The current window
        Card {
            visible: full.task !== null

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    source: full.task ? full.task.icon : ""
                    Layout.preferredWidth: Kirigami.Units.iconSizes.large
                    Layout.preferredHeight: Kirigami.Units.iconSizes.large
                    Layout.alignment: Qt.AlignTop
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: full.task ? full.task.appName : ""
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        font.bold: true
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.15
                    }
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: full.task && full.task.title !== full.task.appName ? full.task.title : ""
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        opacity: 0.75
                    }
                    // Window state
                    RowLayout {
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        visible: full.task && (full.task.isMaximized || full.task.isMinimized || full.task.isKeepAbove || full.task.isOnAllDesktops)
                        spacing: Kirigami.Units.smallSpacing
                        Chip { visible: full.task && full.task.isMaximized; text: i18n("Maximized") }
                        Chip { visible: full.task && full.task.isMinimized; text: i18n("Minimized"); opacity: 0.6 }
                        Chip { visible: full.task && full.task.isKeepAbove; text: i18n("On top") }
                        Chip { visible: full.task && full.task.isOnAllDesktops; text: i18n("All desktops") }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                ActionButton {
                    icon.name: "window-minimize"
                    tip: full.task && full.task.isMinimized ? i18n("Restore") : i18n("Minimize")
                    onClicked: root.toggleMinimized(full.task)
                }
                ActionButton {
                    icon.name: full.task && full.task.isMaximized ? "window-restore" : "window-maximize"
                    tip: full.task && full.task.isMaximized ? i18n("Restore") : i18n("Maximize")
                    onClicked: root.toggleMaximized(full.task)
                }
                ActionButton {
                    icon.name: "window-keep-above"
                    checkable: true
                    checked: full.task !== null && full.task.isKeepAbove
                    tip: i18n("Keep above other windows")
                    onClicked: root.toggleKeepAbove(full.task)
                }
                ActionButton {
                    icon.name: "window-pin"
                    checkable: true
                    checked: full.task !== null && full.task.isOnAllDesktops
                    tip: i18n("Show on all desktops")
                    onClicked: root.toggleAllDesktops(full.task)
                }
                Item { Layout.fillWidth: true }
                PlasmaComponents.ToolButton {
                    icon.name: "window-close"
                    text: i18n("Close")
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    onClicked: {
                        root.close(full.task)
                        root.expanded = false
                    }
                }
            }
        }

        Card {
            visible: full.task === null
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: i18n("No window is active.")
                opacity: 0.75
            }
        }

        // Every window on this desktop
        Card {
            visible: windowList.count > 0
            SectionTitle { text: root.desktopName !== "" ? root.desktopName : i18n("On this desktop") }

            ListView {
                id: windowList
                Layout.fillWidth: true
                // Scrolls past a few rows instead of growing off screen
                Layout.preferredHeight: Math.min(count, full.maxRows) * full.rowHeight
                interactive: count > full.maxRows
                clip: true
                model: root.tasksModel
                boundsBehavior: Flickable.StopAtBounds
                QQC2.ScrollBar.vertical: QQC2.ScrollBar { visible: windowList.interactive }

                delegate: Item {
                    id: entry
                    required property int index
                    required property var model

                    readonly property bool isActive: model.IsActive === true || (root.expanded && root.lastTask && root.lastTask.row === index)
                    readonly property string appName: model.AppName || ""
                    readonly property string title: root.cleanTitle(model.display || "", appName)

                    width: windowList.width
                    height: full.rowHeight

                    PlasmaExtras.Highlight {
                        anchors.fill: parent
                        hovered: true
                        visible: opacity > 0
                        opacity: entry.isActive ? 1 : entryMouse.containsMouse ? 0.5 : 0
                    }

                    MouseArea {
                        id: entryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: function(mouse) {
                            var idx = root.tasksModel.makeModelIndex(entry.index)
                            if (mouse.button === Qt.MiddleButton) {
                                root.tasksModel.requestClose(idx)
                            } else {
                                root.tasksModel.requestActivate(idx)
                                root.expanded = false
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.mediumSpacing
                        opacity: entry.model.IsMinimized === true ? 0.55 : 1

                        Kirigami.Icon {
                            source: entry.model.decoration
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: entry.title
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                font.bold: entry.isActive
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                visible: entry.appName !== "" && entry.appName !== entry.title
                                text: entry.appName
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                opacity: 0.6
                            }
                        }
                        PlasmaComponents.ToolButton {
                            visible: entryMouse.containsMouse || hovered
                            icon.name: "window-close"
                            display: QQC2.AbstractButton.IconOnly
                            onClicked: root.tasksModel.requestClose(root.tasksModel.makeModelIndex(entry.index))
                            QQC2.ToolTip.text: i18n("Close")
                            QQC2.ToolTip.visible: hovered
                        }
                    }
                }
            }
        }
    }

    footer: PlasmaExtras.PlasmoidHeading {
        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: i18n("Middle-click a window to close it")
                elide: Text.ElideRight
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                opacity: 0.65
            }
            PlasmaComponents.ToolButton {
                text: i18n("Overview")
                icon.name: "view-grid"
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                onClicked: {
                    root.expanded = false
                    root.showOverview()
                }
            }
        }
    }
}
