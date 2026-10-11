/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_titleFormat: titleFormat.text
    property alias cfg_sameFormat: sameFormat.text
    property alias cfg_emptyFormat: emptyFormat.text
    property alias cfg_showIcon: showIcon.checked
    property int cfg_iconSize
    property int cfg_maxWidth
    property alias cfg_onlyMaximized: onlyMaximized.checked
    property alias cfg_filterByScreen: filterByScreen.checked
    property alias cfg_middleClickClose: middleClickClose.checked
    property alias cfg_doubleClickMaximize: doubleClickMaximize.checked
    property alias cfg_scrollSwitch: scrollSwitch.checked
    property string cfg_panelFontFamily
    property real cfg_panelFontSize
    property int cfg_panelFontWeight
    property alias cfg_panelFontItalic: fontItalic.checked

    // Spin box with a unit, e.g. value 85 with scale 10 shows "8,5 pt"
    component UnitSpinBox: QQC2.SpinBox {
        property string suffix
        property int scale: 1
        property int decimals: 0

        // Same width so they line up, and padded since the style hugs the left border
        Layout.preferredWidth: Kirigami.Units.gridUnit * 6
        leftPadding: Kirigami.Units.mediumSpacing
        // Allow typing the unit and either "." or ","
        validator: RegularExpressionValidator { regularExpression: /\d+([.,]\d+)?\s*\S*/ }
        textFromValue: function(value, locale) {
            return (value / scale).toLocaleString(locale, 'f', decimals) + suffix
        }
        valueFromText: function(text, locale) {
            return Math.round(parseFloat(text.replace(",", ".")) * scale)
        }
    }

    // Combo for a setting, selected after load so it doesn't stick on the first item
    component ValueComboBox: QQC2.ComboBox {
        property var current
        signal picked(var value)
        textRole: "text"
        valueRole: "value"
        Component.onCompleted: currentIndex = Math.max(0, indexOfValue(current))
        onActivated: picked(currentValue)
    }

    component FormatField: QQC2.TextField {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
        font.family: "monospace"
    }

    Kirigami.FormLayout {
        FormatField { id: titleFormat; Kirigami.FormData.label: i18n("Text:"); placeholderText: "%a" }
        FormatField { id: sameFormat; Kirigami.FormData.label: i18n("When app and title match:"); placeholderText: "%a" }
        FormatField { id: emptyFormat; Kirigami.FormData.label: i18n("When no window is active:"); placeholderText: i18n("(nothing)") }

        QQC2.Label {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            text: i18n("%a is the app name, %w the window title and %q the current activity. For example \"%a — %w\" shows \"Firefox — Example page\".")
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            wrapMode: Text.WordWrap
            opacity: 0.65
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox { id: showIcon; Kirigami.FormData.label: i18n("Icon:"); text: i18n("Show window icon") }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.FormData.label: i18n("Icon size:")
            enabled: showIcon.checked
            QQC2.CheckBox {
                id: customIconSize
                text: i18n("Custom")
                checked: cfg_iconSize > 0
                onToggled: cfg_iconSize = checked ? iconSizeSpin.value : 0
            }
            UnitSpinBox {
                id: iconSizeSpin
                enabled: customIconSize.checked
                suffix: " px"
                from: 8; to: 64; stepSize: 2
                value: cfg_iconSize > 0 ? cfg_iconSize : Kirigami.Units.iconSizes.smallMedium
                onValueModified: cfg_iconSize = value
            }
        }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.FormData.label: i18n("Maximum width:")
            QQC2.CheckBox {
                id: limitWidth
                text: i18n("Limit")
                checked: cfg_maxWidth > 0
                onToggled: cfg_maxWidth = checked ? widthSpin.value : 0
            }
            UnitSpinBox {
                id: widthSpin
                enabled: limitWidth.checked
                suffix: " px"
                from: 40; to: 2000; stepSize: 10
                value: cfg_maxWidth > 0 ? cfg_maxWidth : 300
                onValueModified: cfg_maxWidth = value
            }
        }

        Item { Kirigami.FormData.isSection: true }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.FormData.label: i18n("Font:")
            QQC2.CheckBox {
                id: customFont
                text: i18n("Custom")
                checked: cfg_panelFontFamily !== ""
                onToggled: cfg_panelFontFamily = checked ? (fontCombo.editText || Kirigami.Theme.defaultFont.family) : ""
            }
            QQC2.ComboBox {
                id: fontCombo
                enabled: customFont.checked
                editable: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                model: Qt.fontFamilies()
                // Ignore changes while loading, or the first font in the list wins
                property bool loaded: false
                Component.onCompleted: {
                    var fam = cfg_panelFontFamily || Kirigami.Theme.defaultFont.family
                    var i = find(fam)
                    if (i >= 0) currentIndex = i
                    else editText = fam
                    loaded = true
                }
                // Saves both picked and typed names, no Enter needed
                onEditTextChanged: if (loaded && customFont.checked && editText !== "") cfg_panelFontFamily = editText
            }
        }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.FormData.label: i18n("Size:")
            QQC2.CheckBox {
                id: customSize
                text: i18n("Custom")
                checked: cfg_panelFontSize > 0
                onToggled: cfg_panelFontSize = checked ? sizeSpin.value / 10 : 0
            }
            UnitSpinBox {
                id: sizeSpin
                enabled: customSize.checked
                // Stored in tenths of a point for half-point steps
                suffix: " pt"; scale: 10; decimals: 1
                from: 40; to: 300; stepSize: 5
                value: cfg_panelFontSize > 0 ? Math.round(cfg_panelFontSize * 10) : 90
                onValueModified: cfg_panelFontSize = value / 10
            }
        }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.FormData.label: i18n("Style:")
            // Fonts without the chosen weight fall back to the closest one they have
            ValueComboBox {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                model: [
                    { text: i18n("Thin"), value: Font.Thin },
                    { text: i18n("Extra Light"), value: Font.ExtraLight },
                    { text: i18n("Light"), value: Font.Light },
                    { text: i18n("Regular"), value: Font.Normal },
                    { text: i18n("Medium"), value: Font.Medium },
                    { text: i18n("Semi Bold"), value: Font.DemiBold },
                    { text: i18n("Bold"), value: Font.Bold },
                    { text: i18n("Extra Bold"), value: Font.ExtraBold },
                    { text: i18n("Black"), value: Font.Black }
                ]
                current: cfg_panelFontWeight
                onPicked: function(value) { cfg_panelFontWeight = value }
            }
            QQC2.CheckBox { id: fontItalic; text: i18n("Italic") }
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox { id: onlyMaximized; Kirigami.FormData.label: i18n("Windows:"); text: i18n("Only show maximized windows") }
        QQC2.CheckBox { id: filterByScreen; text: i18n("Only windows on this panel's screen") }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox { id: doubleClickMaximize; Kirigami.FormData.label: i18n("Mouse:"); text: i18n("Double-click to maximize or restore") }
        QQC2.CheckBox { id: middleClickClose; text: i18n("Middle-click to close") }
        QQC2.CheckBox { id: scrollSwitch; text: i18n("Scroll to switch windows") }
    }
}
