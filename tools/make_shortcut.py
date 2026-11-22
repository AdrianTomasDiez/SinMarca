"""Genera Saver.shortcut (sin firmar) para la app Atajos. Uso:
    SERVER_URL=https://… API_KEY=… python3 tools/make_shortcut.py Saver.shortcut
Luego en macOS: shortcuts sign --mode anyone --input Saver.shortcut --output Saver-firmado.shortcut
Equivale a los pasos de ATAJO.md.
"""
import os
import plistlib
import sys
import uuid

OBJ = "￼"  # marcador de variable dentro de un texto


def new_id():
    return str(uuid.uuid4()).upper()


def output(uid, name):
    return {"Type": "ActionOutput", "OutputUUID": uid, "OutputName": name}


def attach(ref):
    return {"Value": ref, "WFSerializationType": "WFTextTokenAttachment"}


def text(s, ref=None):
    """Texto fijo, o una variable sola si se pasa ref."""
    if ref is None:
        return {"Value": {"string": s, "attachmentsByRange": {}}, "WFSerializationType": "WFTextTokenString"}
    return {"Value": {"string": OBJ, "attachmentsByRange": {"{0, 1}": ref}}, "WFSerializationType": "WFTextTokenString"}


def dictionary(items):
    return {"Value": {"WFDictionaryFieldValueItems": items}, "WFSerializationType": "WFDictionaryFieldValue"}


def text_item(key, value):
    return {"WFItemType": 0, "WFKey": text(key), "WFValue": value}


def bool_item(key, value):
    return {"WFItemType": 4, "WFKey": text(key),
            "WFValue": {"Value": value, "WFSerializationType": "WFNumberSubstitutableState"}}


def action(ident, **params):
    return {"WFWorkflowActionIdentifier": f"is.workflow.actions.{ident}", "WFWorkflowActionParameters": params}


def build(server, api_key):
    urls, first, resp, status = new_id(), new_id(), new_id(), new_id()
    picker, item_url, item_file = new_id(), new_id(), new_id()
    one_url, one_file = new_id(), new_id()
    if_group, repeat_group = new_id(), new_id()
    repeat_item = {"Type": "Variable", "VariableName": "Repeat Item"}

    actions = [
        action("detect.link", UUID=urls, WFInput=attach({"Type": "ExtensionInput"})),
        action("getitemfromlist", UUID=first, WFItemSpecifier="First Item", WFInput=attach(output(urls, "URLs"))),
        action(
            "downloadurl", UUID=resp, WFURL=server, WFHTTPMethod="POST", ShowHeaders=True,
            WFHTTPHeaders=dictionary([
                text_item("Accept", text("application/json")),
                text_item("Content-Type", text("application/json")),
                text_item("Authorization", text(f"Api-Key {api_key}")),
            ]),
            WFHTTPBodyType="JSON",
            WFJSONValues=dictionary([
                text_item("url", text("", output(first, "Item from List"))),
                text_item("videoQuality", text("max")),
                bool_item("allowH265", True),
            ]),
        ),
        action("getvalueforkey", UUID=status, WFGetDictionaryValueType="Value", WFDictionaryKey="status",
               WFInput=attach(output(resp, "Contents of URL"))),
        # Si status es "picker" (carrusel): guardar cada elemento
        action("conditional", GroupingIdentifier=if_group, WFControlFlowMode=0, WFCondition=4,
               WFConditionalActionString="picker",
               WFInput={"Type": "Variable", "Variable": attach(output(status, "Dictionary Value"))}),
        action("getvalueforkey", UUID=picker, WFGetDictionaryValueType="Value", WFDictionaryKey="picker",
               WFInput=attach(output(resp, "Contents of URL"))),
        action("repeat.each", GroupingIdentifier=repeat_group, WFControlFlowMode=0,
               WFInput=attach(output(picker, "Dictionary Value"))),
        action("getvalueforkey", UUID=item_url, WFGetDictionaryValueType="Value", WFDictionaryKey="url",
               WFInput=attach(repeat_item)),
        action("downloadurl", UUID=item_file, WFURL=text("", output(item_url, "Dictionary Value"))),
        action("savetocameraroll", WFInput=attach(output(item_file, "Contents of URL"))),
        action("repeat.each", GroupingIdentifier=repeat_group, WFControlFlowMode=2),
        # De lo contrario: un solo archivo
        action("conditional", GroupingIdentifier=if_group, WFControlFlowMode=1),
        action("getvalueforkey", UUID=one_url, WFGetDictionaryValueType="Value", WFDictionaryKey="url",
               WFInput=attach(output(resp, "Contents of URL"))),
        action("downloadurl", UUID=one_file, WFURL=text("", output(one_url, "Dictionary Value"))),
        action("savetocameraroll", WFInput=attach(output(one_file, "Contents of URL"))),
        action("conditional", GroupingIdentifier=if_group, WFControlFlowMode=2),
        action("notification", WFNotificationActionBody="Guardado en Fotos ✅", WFNotificationActionSound=True),
    ]
    return {
        "WFWorkflowClientVersion": "2607.0.2",
        "WFWorkflowMinimumClientVersion": 900,
        "WFWorkflowMinimumClientVersionString": "900",
        "WFWorkflowIcon": {"WFWorkflowIconStartColor": 463140863, "WFWorkflowIconGlyphNumber": 61440},
        "WFWorkflowTypes": ["ActionExtension"],  # aparece en el menú Compartir
        "WFWorkflowInputContentItemClasses": ["WFURLContentItem", "WFStringContentItem"],
        "WFWorkflowHasShortcutInputVariables": True,
        "WFWorkflowNoInputBehavior": {"Name": "WFWorkflowNoInputBehaviorGetClipboard", "Parameters": {}},
        "WFWorkflowImportQuestions": [],
        "WFQuickActionSurfaces": [],
        "WFWorkflowOutputContentItemClasses": [],
        "WFWorkflowActions": actions,
    }


if __name__ == "__main__":
    server, api_key = os.environ["SERVER_URL"], os.environ["API_KEY"]
    assert server.startswith("https://") and api_key, "faltan SERVER_URL o API_KEY"
    data = build(server, api_key)
    # Comprobación: cada bloque Si/Repetir abre y cierra con el mismo identificador.
    modes = {}
    for a in data["WFWorkflowActions"]:
        p = a["WFWorkflowActionParameters"]
        if "GroupingIdentifier" in p:
            modes.setdefault(p["GroupingIdentifier"], []).append(p["WFControlFlowMode"])
    assert sorted(modes.values()) == [[0, 1, 2], [0, 2]], modes
    with open(sys.argv[1], "wb") as f:
        plistlib.dump(data, f, fmt=plistlib.FMT_BINARY)
    print("ok", sys.argv[1], len(data["WFWorkflowActions"]), "acciones")
