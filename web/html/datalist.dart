part of switchy_html;

/*!
 * Copyright (C) 2012, The SwitchyOmega Authors. Please see the AUTHORS file
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

void bindToDataList(Element target, [DataListElement datalist]) {
  if (datalist == null) {
    var datalist_id = target.attributes[autoBindToDataListAttrName];
    datalist = target.document.query('#$datalist_id');
    if (datalist == null) return;
  }

  target.nodes.clear();
  target.nodes.addAll(
      datalist.queryAll('option').mappedBy((o) => o.clone(true)));

  // When the datalist changes, update the target Element.
  MutationObserver ob = new MutationObserver(
      (List<MutationRecord> mutations, MutationObserver _) {
        mutations.forEach((MutationRecord record) {
          // Perhaps this can be done in a more efficient way.
          target.nodes.clear();
          target.nodes.addAll(
              datalist.queryAll('option').mappedBy((o) => o.clone(true)));
        });
      });
  ob.observe(datalist,
      childList: true,
      attributes: true,
      subtree: true,
      characterData: true);
}

void autoBindToDataList(Element root) {
  root.queryAll('[$autoBindToDataListAttrName]').forEach(
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
                  el.queryAll('[$autoBindToDataListAttrName]').forEach(
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
}
