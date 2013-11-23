part of switchy_html;

/*!
 * Copyright (C) 2012-2013, The SwitchyOmega Authors. Please see the AUTHORS file
 * for details.
 *
 * This file is part of SwitchyOmega.
 *
 * SwitchyOmega is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SwitchyOmega is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SwitchyOmega.  If not, see <http://www.gnu.org/licenses/>.
 */

final String autoBindToDataListAttrName = "data-list";
final String valueLaterDataListAttrName = "data-later-value";
final String copiedOptionClassName = "data-list-item";

void copyFromDataList(Element target, DataListElement datalist) {
  target.nodes.retainWhere((node) => node is Element &&
      !node.classes.contains(copiedOptionClassName));

  target.nodes.addAll(
      datalist.querySelectorAll('option').map((o) {
        var copied = o.clone(true);
        (copied as Element).classes.add(copiedOptionClassName);
        return copied;
      }));

  var value = target.attributes[valueLaterDataListAttrName];
  if (value != null) {
    // Let's just assume target has a value setter.
    (target as dynamic).value = value;
  }
}

MutationObserver bindToDataList(Element target, [DataListElement datalist]) {
  if (datalist == null) {
    var datalist_id = target.attributes[autoBindToDataListAttrName];
    datalist = target.ownerDocument.querySelector('#$datalist_id');
    if (datalist == null) return null;
  }

  copyFromDataList(target, datalist);

  // When the datalist changes, update the target Element.
  MutationObserver ob = new MutationObserver(
      (List<MutationRecord> mutations, MutationObserver _) {
        copyFromDataList(target, datalist);
      });
  ob.observe(datalist,
      childList: true,
      attributes: true,
      subtree: true,
      characterData: true);

  return ob;
}

MutationObserver autoBindToDataList(Element root) {
  root.querySelectorAll('[$autoBindToDataListAttrName]').forEach(
      (target) {
        bindToDataList(target);
      });

  MutationObserver ob = new MutationObserver(
      (List<MutationRecord> mutations, MutationObserver _) {
        mutations.forEach((MutationRecord record) {
          switch (record.type) {
            case 'attributes':
              bindToDataList(record.target as Element);
              break;
            case 'childList':
              record.addedNodes.forEach((el) {
                if (el is Element) {
                  el.querySelectorAll('[$autoBindToDataListAttrName]').forEach(
                      (target) {
                        bindToDataList(target);
                      });
                }
              });
              break;
          }
        });
      });
  ob.observe(root,
      childList: true,
      attributes: true,
      subtree: true,
      attributeFilter: [autoBindToDataListAttrName]);

  return ob;
}
